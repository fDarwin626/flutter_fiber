/// Declares the interpolated view-space normal (and tangent frame) varyings
/// used by the fragment shader.
///
/// Ported from three.js's `normal_pars_fragment.glsl.js`
/// (src/renderers/shaders/ShaderChunk/), copied unchanged. Paired with
/// `normal_pars_vertex` / `normal_vertex`, which write these varyings.
const String fiber3dNormalParsFragment = r'''
#ifndef FLAT_SHADED

	varying vec3 vNormal;

	#ifdef USE_TANGENT

		varying vec3 vTangent;
		varying vec3 vBitangent;

	#endif

#endif
''';