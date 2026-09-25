import '../core/fiber3d_color_management.dart';
import '../renderer/fiber3d_tone_mapping.dart';
import 'fiber3d_pbr_shader.dart';
import 'fiber3d_program_functions.dart';
import 'fiber3d_shader_chunk.dart';
import 'fiber3d_shader_preprocess.dart';
import 'shader_chunk/fiber3d_colorspace_pars_fragment.dart';
import 'shader_chunk/fiber3d_lights_toon_pars_fragment.dart';
import 'shader_chunk/fiber3d_tonemapping_pars_fragment.dart';

/// The vertex/fragment pair for flutter_fiber's Toon (cel-shading)
/// material direct light is stepped into discrete bands via
/// `getGradientIrradiance` rather than shaded continuously.
///
/// Ported from three.js's `meshtoon.glsl.js`
/// (src/renderers/shaders/ShaderLib/), trimmed the same way
/// Fiber3DPbrShader/Fiber3DLambertShader/Fiber3DPhongShader are.
///
/// No `USE_GRADIENTMAP` support: flutter_fiber has no texture pipeline
/// yet (section 1, not started), so real three.js's texture-sampled
/// gradient map branch in `gradientmap_pars_fragment` is dormant,
/// unreachable code, same as every other `#ifdef`-guarded feature
/// flutter_fiber compiles but never triggers. Every Toon material
/// currently renders with the fixed two-band fallback step.
///
/// Reuses the exact same vertex body as the other three materials
/// every chunk Toon's real vertex shader needs was already ported for
/// Physical, and none of them branch on the material `#define` with
/// only the `#define` swapped for parity with three.js's own shader.
///
/// emissiveIntensity is the same deliberate, flagged deviation from
/// three.js already made for Lambert/Phong (real meshtoon.glsl.js has
/// no such uniform) added by hand for API consistency.
class Fiber3DToonShader {
  static String vertex(String version) {
    const body = r'''
#define TOON

uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;
uniform mat3 normalMatrix;

attribute vec3 position;
attribute vec3 normal;

varying vec3 vViewPosition;

#include <common>
#include <normal_pars_vertex>

void main() {

	#include <beginnormal_vertex>
	#include <defaultnormal_vertex>
	#include <normal_vertex>

	#include <begin_vertex>
	#include <project_vertex>

	vViewPosition = - mvPosition.xyz;

}
''';

    final resolved = Fiber3DShaderChunk.resolveIncludes(body);

    return """#version $version
#define attribute in
#define varying out

$resolved""";
  }

  static String fragment(
    String version, {
    Fiber3DToneMapping toneMapping = Fiber3DToneMapping.none,
    Fiber3DColorSpace outputColorSpace = Fiber3DColorSpace.srgb,
  }) {
    final outputPrefix = _outputPrefix(toneMapping, outputColorSpace);

    // Same duplicate-varying handling as Lambert/Phong.
    final toonParsWithoutDuplicateVarying = fiber3dLightsToonParsFragment
        .replaceFirst('varying vec3 vViewPosition;\n\n', '');

    final body =
        '''
#define TOON
#define OPAQUE

uniform vec3 diffuse;
uniform vec3 emissive;
uniform float emissiveIntensity;
uniform float opacity;
uniform bool isOrthographic;
uniform mat4 viewMatrix;

varying vec3 vViewPosition;

$outputPrefix

#include <common>
#include <lights_pars_begin>
#include <normal_pars_fragment>
#include <gradientmap_pars_fragment>
$toonParsWithoutDuplicateVarying

void main() {

\tvec4 diffuseColor = vec4( diffuse, opacity );
\tReflectedLight reflectedLight = ReflectedLight( vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ) );
\tvec3 totalEmissiveRadiance = emissive * emissiveIntensity;

\t#include <normal_fragment_begin>

\t// accumulation
\t#include <lights_toon_fragment>
\t#include <lights_fragment_begin>
\t#include <lights_fragment_maps>
\t#include <lights_fragment_end>

\tvec3 outgoingLight = reflectedLight.directDiffuse + reflectedLight.indirectDiffuse + totalEmissiveRadiance;

\t#include <opaque_fragment>
\t#include <tonemapping_fragment>
\t#include <colorspace_fragment>

}
''';

    final resolved = Fiber3DShaderChunk.resolveIncludes(body);
    final withNums = Fiber3DShaderPreprocess.replaceLightNums(
      resolved,
      numPointLights: Fiber3DPbrShader.maxPointLights,
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