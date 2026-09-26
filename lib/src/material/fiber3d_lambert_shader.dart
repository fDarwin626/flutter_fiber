import 'package:flutter_fiber/src/material/shader_chunk/fiber3d_lights_lambert_pars_fragment.dart';

import '../core/fiber3d_color_management.dart';
import '../renderer/fiber3d_tone_mapping.dart';
import 'fiber3d_pbr_shader.dart';
import 'fiber3d_program_functions.dart';
import 'fiber3d_shader_chunk.dart';
import 'fiber3d_shader_preprocess.dart';
import 'shader_chunk/fiber3d_colorspace_pars_fragment.dart';
import 'shader_chunk/fiber3d_tonemapping_pars_fragment.dart';


class Fiber3DLambertShader {
  static String vertex(String version) {
    const body = r'''
#define LAMBERT

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

    // vViewPosition is declared here, once, matching Fiber3DPbrShader's
    // pattern — so lights_lambert_pars_fragment's own `varying vec3
    // vViewPosition;` line must NOT also be included verbatim, or this
    // becomes a duplicate declaration and fails to compile. Handled by
    // stripping that one line out of the chunk's own text before
    // inclusion, rather than editing the ported chunk file itself (which
    // stays a faithful, unmodified copy of the real three.js source).
    final lambertParsWithoutDuplicateVarying = fiber3dLightsLambertParsFragment
        .replaceFirst('varying vec3 vViewPosition;\n\n', '');

    final body =
        '''
#define LAMBERT
#define OPAQUE

uniform vec3 diffuse;
uniform vec3 emissive;
uniform float emissiveIntensity;
uniform float opacity;
uniform bool isOrthographic;
uniform mat4 viewMatrix;

varying vec3 vViewPosition;
varying vec2 vUv;

$outputPrefix

#include <common>
#include <lights_pars_begin>
#include <normal_pars_fragment>
$lambertParsWithoutDuplicateVarying

void main() {

\tvec4 diffuseColor = vec4( diffuse, opacity );
\tReflectedLight reflectedLight = ReflectedLight( vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ) );
\tvec3 totalEmissiveRadiance = emissive * emissiveIntensity;

\t#include <normal_fragment_begin>

\t// accumulation
\t#include <lights_lambert_fragment>
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