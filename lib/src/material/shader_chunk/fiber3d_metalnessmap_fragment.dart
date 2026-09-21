/// Computes `metalnessFactor` from the `metalness` uniform, multiplied by the
/// metalness map's B channel when USE_METALNESSMAP is defined.
///
/// Ported from three.js's `metalnessmap_fragment.glsl.js`
/// (src/renderers/shaders/ShaderChunk/), copied unchanged.
const String fiber3dMetalnessmapFragment = r'''
float metalnessFactor = metalness;

#ifdef USE_METALNESSMAP

	vec4 texelMetalness = texture2D( metalnessMap, vMetalnessMapUv );

	// reads channel B, compatible with a combined OcclusionRoughnessMetallic (RGB) texture
	metalnessFactor *= texelMetalness.b;

#endif
''';