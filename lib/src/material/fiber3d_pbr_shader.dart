import '../core/fiber3d_color_management.dart';
import '../renderer/fiber3d_tone_mapping.dart';
import 'fiber3d_program_functions.dart';
import 'fiber3d_shader_chunk.dart';
import 'shader_chunk/fiber3d_colorspace_pars_fragment.dart';
import 'shader_chunk/fiber3d_tonemapping_pars_fragment.dart';

class Fiber3DPbrShader {
  /// GLSL loop bounds must be compile-time constants this is a real
  /// language constraint, not a scope shortcut. three.js works around
  /// the same constraint by compiling a distinct shader per exact light
  /// count; we use one fixed ceiling instead.
  static const int maxPointLights = 4;

  static String vertex(String version) => """#version $version
#define attribute in
#define varying out

attribute vec3 a_Position;
attribute vec3 a_Normal;

uniform mat4 u_ModelMatrix;
uniform mat4 u_ViewMatrix;
uniform mat4 u_ProjectionMatrix;

varying vec3 v_WorldPosition;
varying vec3 v_WorldNormal;

void main() {
    vec4 worldPos = u_ModelMatrix * vec4(a_Position, 1.0);
    v_WorldPosition = worldPos.xyz;
    v_WorldNormal = mat3(transpose(inverse(u_ModelMatrix))) * a_Normal;
    gl_Position = u_ProjectionMatrix * u_ViewMatrix * worldPos;
}
""";

  /// Output settings are baked into the shader at compile time, like
  /// three.js's program parameters.
  static String fragment(
    String version, {
    Fiber3DToneMapping toneMapping = Fiber3DToneMapping.none,
    Fiber3DColorSpace outputColorSpace = Fiber3DColorSpace.srgb,
  }) => Fiber3DShaderChunk.resolveIncludes("""#version $version
precision highp float;
out highp vec4 pc_fragColor;
#define gl_FragColor pc_fragColor
#define varying in

varying vec3 v_WorldPosition;
varying vec3 v_WorldNormal;

uniform vec3 u_CameraPosition;

uniform vec3 u_BaseColor;
uniform float u_Roughness;
uniform float u_Metalness;
uniform vec3 u_Emissive;
uniform float u_EmissiveIntensity;

uniform vec3 u_AmbientLightColor;
uniform vec3 u_SkyColor;
uniform vec3 u_GroundColor;

uniform int u_PointLightCount;
uniform vec3 u_PointLightPosition[$maxPointLights];
uniform vec3 u_PointLightColor[$maxPointLights];
uniform float u_PointLightDistance[$maxPointLights];
uniform float u_PointLightDecay[$maxPointLights];

${_outputPrefix(toneMapping, outputColorSpace)}

const float PI = 3.14159265359;

float pow2(float x) { return x * x; }

// Trowbridge-Reitz/GGX normal distribution function.
// http://graphicrants.blogspot.com/2013/08/specular-brdf-reference.html
float D_GGX(float alpha, float dotNH) {
    float a2 = pow2(alpha);
    float denom = pow2(dotNH) * (a2 - 1.0) + 1.0;
    return a2 / (PI * pow2(denom));
}

// Smith-correlated visibility term (combines geometry term + BRDF
// normalization). Moving Frostbite to PBR 3.0, page 12.
float V_GGX_SmithCorrelated(float alpha, float dotNL, float dotNV) {
    float a2 = pow2(alpha);
    float gv = dotNL * sqrt(a2 + (1.0 - a2) * pow2(dotNV));
    float gl = dotNV * sqrt(a2 + (1.0 - a2) * pow2(dotNL));
    return 0.5 / max(gv + gl, 1e-6);
}

// Schlick's Fresnel approximation.
vec3 F_Schlick(vec3 f0, float dotVH) {
    float x = clamp(1.0 - dotVH, 0.0, 1.0);
    return f0 + (vec3(1.0) - f0) * (x * x * x * x * x);
}

// Ported from three.js's getDistanceAttenuation (Frostbite 3 PBR notes,
// page 32, equation 26).
float getDistanceAttenuation(float lightDistance, float cutoffDistance, float decayExponent) {
    float distanceFalloff = 1.0 / max(pow(lightDistance, decayExponent), 0.01);
    if (cutoffDistance > 0.0) {
        float factor = clamp(1.0 - pow(lightDistance / cutoffDistance, 4.0), 0.0, 1.0);
        distanceFalloff *= factor * factor;
    }
    return distanceFalloff;
}

void main() {
    vec3 N = normalize(v_WorldNormal);
    vec3 V = normalize(u_CameraPosition - v_WorldPosition);

    // Metallic-roughness workflow: metals have no diffuse term and tint
    // their specular reflectance by the base color; dielectrics use a
    // flat F0 of 0.04 (~4% reflectance), matching three.js's non-IOR
    // default path.
    vec3 diffuseColor = u_BaseColor * (1.0 - u_Metalness);
    vec3 F0 = mix(vec3(0.04), u_BaseColor, u_Metalness);
    float roughness = clamp(u_Roughness, 0.0525, 1.0);
    float alpha = pow2(roughness);

    vec3 directDiffuse = vec3(0.0);
    vec3 directSpecular = vec3(0.0);

    for (int i = 0; i < $maxPointLights; i++) {
        if (i >= u_PointLightCount) break;

        vec3 toLight = u_PointLightPosition[i] - v_WorldPosition;
        float lightDistance = length(toLight);
        vec3 L = normalize(toLight);
        vec3 H = normalize(L + V);

        float dotNL = clamp(dot(N, L), 0.0, 1.0);
        float dotNV = clamp(dot(N, V), 0.0, 1.0);
        float dotNH = clamp(dot(N, H), 0.0, 1.0);
        float dotVH = clamp(dot(V, H), 0.0, 1.0);

        float attenuation = getDistanceAttenuation(
            lightDistance, u_PointLightDistance[i], u_PointLightDecay[i]);
        vec3 lightColor = u_PointLightColor[i] * attenuation;
        vec3 irradiance = dotNL * lightColor;

        float D = D_GGX(alpha, dotNH);
        float Vis = V_GGX_SmithCorrelated(alpha, dotNL, dotNV);
        vec3 F = F_Schlick(F0, dotVH);

        vec3 specularBRDF = F * (D * Vis);
        vec3 diffuseBRDF = diffuseColor / PI;

        directSpecular += irradiance * specularBRDF;
        // Energy conservation: light reflected by the specular lobe
        // isn't available to the diffuse layer (glTF fresnel_mix).
        directDiffuse += irradiance * diffuseBRDF * (vec3(1.0) - F);
    }

    // Tier 1 environment lighting (HemisphereLight-style fake env):
    // approximates the surrounding environment as two flat colors
    // blended by the surface normal's vertical component, so every
    // surface gets some light based on which way it faces rather than
    // only faces pointed at a point light. Near-zero cost, no texture.
    vec3 envColor = mix(u_GroundColor, u_SkyColor, N.y * 0.5 + 0.5);
    vec3 envDiffuse = envColor * diffuseColor;

    vec3 ambientDiffuse = u_AmbientLightColor * diffuseColor;
    vec3 emissive = u_Emissive * u_EmissiveIntensity;

    vec3 outgoing = directDiffuse + directSpecular + ambientDiffuse + envDiffuse + emissive;
    gl_FragColor = vec4(outgoing, 1.0);

    #include <tonemapping_fragment>
    #include <colorspace_fragment>
}
""");

  static String _outputPrefix(
    Fiber3DToneMapping toneMapping,
    Fiber3DColorSpace outputColorSpace,
  ) {
    final toneMapped = toneMapping != Fiber3DToneMapping.none;
    return [
      if (toneMapped) '#define TONE_MAPPING',
      if (toneMapped) fiber3dTonemappingParsFragment,
      if (toneMapped)
        Fiber3DProgramFunctions.toneMappingFunction('toneMapping', toneMapping),
      fiber3dColorspaceParsFragment,
      Fiber3DProgramFunctions.texelEncodingFunction(
        'linearToOutputTexel',
        outputColorSpace,
      ),
      Fiber3DProgramFunctions.luminanceFunction(),
    ].join('\n');
  }
}