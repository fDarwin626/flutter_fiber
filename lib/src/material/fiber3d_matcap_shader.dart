import '../core/fiber3d_color_management.dart';
import '../renderer/fiber3d_tone_mapping.dart';
import 'fiber3d_program_functions.dart';
import 'fiber3d_shader_chunk.dart';
import 'shader_chunk/fiber3d_colorspace_pars_fragment.dart';
import 'shader_chunk/fiber3d_tonemapping_pars_fragment.dart';

/// The vertex/fragment pair for flutter_fiber's Matcap material color
/// sampled purely from view-space normal orientation, no lighting math
/// at all (no ambient, no point lights, no ReflectedLight accumulation).
///
/// Ported from three.js's `meshmatcap.glsl.js`
/// (src/renderers/shaders/ShaderLib/). The `USE_MATCAP` texture-sampled
/// branch is dormant (no texture pipeline yet); every material renders
/// through the `#else` fallback gradient.
///
/// Reuses the exact same vertex body as the other materials. No
/// `replaceLightNums`/`unrollLoops` preprocessing needed this shader
/// has no light-related tokens to substitute at all, unlike every other
/// material shader here.
class Fiber3DMatcapShader {
  static String vertex(String version) {
    const body = r'''
#define MATCAP

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

  static String fragment(
    String version, {
    Fiber3DToneMapping toneMapping = Fiber3DToneMapping.none,
    Fiber3DColorSpace outputColorSpace = Fiber3DColorSpace.srgb,
  }) {
    final outputPrefix = _outputPrefix(toneMapping, outputColorSpace);

    final body =
        '''
#define MATCAP
#define OPAQUE

uniform vec3 diffuse;
uniform float opacity;
uniform sampler2D matcap;

varying vec3 vViewPosition;
varying vec2 vUv;

$outputPrefix

#include <common>
#include <normal_pars_fragment>

void main() {

\tvec4 diffuseColor = vec4( diffuse, opacity );

\t#include <normal_fragment_begin>

\tvec3 viewDir = normalize( vViewPosition );
\tvec3 x = normalize( vec3( viewDir.z, 0.0, - viewDir.x ) );
\tvec3 y = cross( viewDir, x );
\tvec2 uv = vec2( dot( x, normal ), dot( y, normal ) ) * 0.495 + 0.5;

\t#ifdef USE_MATCAP

\t\tvec4 matcapColor = texture2D( matcap, uv );

\t#else

\t\tvec4 matcapColor = vec4( vec3( mix( 0.2, 0.8, uv.y ) ), 1.0 );

\t#endif

\tvec3 outgoingLight = diffuseColor.rgb * matcapColor.rgb;

\t#include <opaque_fragment>
\t#include <tonemapping_fragment>
\t#include <colorspace_fragment>

}
''';

    final resolved = Fiber3DShaderChunk.resolveIncludes(body);

    return """#version $version
precision highp float;
out highp vec4 pc_fragColor;
#define gl_FragColor pc_fragColor
#define varying in
#define texture2D texture

$resolved""";
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