import '../core/fiber3d_color_management.dart';
import '../renderer/fiber3d_tone_mapping.dart';
import 'fiber3d_program_functions.dart';
import 'fiber3d_shader_chunk.dart';
import 'fiber3d_shader_preprocess.dart';
import 'shader_chunk/fiber3d_colorspace_pars_fragment.dart';
import 'shader_chunk/fiber3d_tonemapping_pars_fragment.dart';

/// The vertex/fragment pair for flutter_fiber's physical (PBR) material.
///
/// Ported from three.js's `meshphysical.glsl.js`
/// (src/renderers/shaders/ShaderLib/), trimmed to the subset of chunks
/// flutter_fiber has ported so far: no UV/texture maps, no shadows, no
/// fog, no morph/skin/batching/instancing, no clearcoat/sheen/iridescence/
/// anisotropy/transmission (all still behind their #ifdef guards and
/// simply never triggered), and no environment maps (so indirect specular
/// is always zero black metals until Section 6).
///
/// Because flutter_fiber has no WebGLProgram-style automatic uniform/
/// attribute injection, `position`, `normal`, `modelViewMatrix`,
/// `projectionMatrix`, `normalMatrix` and `isOrthographic` are declared
/// explicitly here rather than assumed.
class Fiber3DPbrShader {
  /// GLSL loop bounds must be compile-time constants, so NUM_POINT_LIGHTS
  /// is fixed to this value rather than derived per-scene (see
  /// Fiber3DShaderPreprocess). Unused light slots are zeroed at upload
  /// time by the canvas.
  static const int maxPointLights = 4;

  static String vertex(String version) {
    const body = r'''
#define STANDARD

uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;
uniform mat3 normalMatrix;


attribute vec3 position;
attribute vec3 normal;
attribute vec2 uv;

varying vec3 vViewPosition;
varying vec2 vUv;

#include <common>
#include <normal_pars_vertex>

void main() {

	#include <beginnormal_vertex>
	#include <defaultnormal_vertex>
	#include <normal_vertex>

	#include <begin_vertex>
	#include <project_vertex>

	vViewPosition = - mvPosition.xyz;
	vUv = uv;

}
''';

    final resolved = Fiber3DShaderChunk.resolveIncludes(body);

    return """#version $version
#define attribute in
#define varying out

$resolved""";
  }

  /// Output settings are baked into the shader at compile time, like
  /// three.js's program parameters.
  static String fragment(
    String version, {
    Fiber3DToneMapping toneMapping = Fiber3DToneMapping.none,
    Fiber3DColorSpace outputColorSpace = Fiber3DColorSpace.srgb,
  }) {
    final outputPrefix = _outputPrefix(toneMapping, outputColorSpace);

    final body =
        '''
#define STANDARD
#define OPAQUE
#define USE_MAP
#define vMapUv vUv

uniform vec3 diffuse;
uniform vec3 emissive;
uniform float emissiveIntensity;
uniform float roughness;
uniform float metalness;
uniform float opacity;
uniform bool isOrthographic;
uniform mat4 viewMatrix;

varying vec3 vViewPosition;
varying vec2 vUv;

$outputPrefix

#include <common>
#include <map_pars_fragment>
#include <lights_pars_begin>
#include <normal_pars_fragment>
#include <lights_physical_pars_fragment>

void main() {

\tvec4 diffuseColor = vec4( diffuse, opacity );
\tReflectedLight reflectedLight = ReflectedLight( vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ) );
\tvec3 totalEmissiveRadiance = emissive * emissiveIntensity;

\t#include <map_fragment>
\t#include <roughnessmap_fragment>
\t#include <metalnessmap_fragment>
\t#include <normal_fragment_begin>
\t// accumulation
\t#include <lights_physical_fragment>
\t#include <lights_fragment_begin>
\t#include <lights_fragment_maps>
\t#include <lights_fragment_end>

\tvec3 totalDiffuse = reflectedLight.directDiffuse + reflectedLight.indirectDiffuse;
\tvec3 totalSpecular = reflectedLight.directSpecular + reflectedLight.indirectSpecular;

\tvec3 outgoingLight = totalDiffuse + totalSpecular + totalEmissiveRadiance;

\t#include <opaque_fragment>
\t#include <tonemapping_fragment>
\t#include <colorspace_fragment>

}
''';

    final resolved = Fiber3DShaderChunk.resolveIncludes(body);
    final withNums = Fiber3DShaderPreprocess.replaceLightNums(
      resolved,
      numPointLights: maxPointLights,
    );
    final unrolled = Fiber3DShaderPreprocess.unrollLoops(withNums);

    return """#version $version
precision highp float;
out highp vec4 pc_fragColor;
#define gl_FragColor pc_fragColor
#define varying in
#define texture2D texture

$unrolled""";
  }

  /// The prefix pieces three.js's WebGLProgram injects before the fragment
  /// body: tone-mapping (only when active) and output encoding.
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