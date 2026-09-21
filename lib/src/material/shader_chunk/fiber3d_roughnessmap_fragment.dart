/// Computes `roughnessFactor` from the `roughness` uniform, multiplied by the
/// roughness map's G channel when USE_ROUGHNESSMAP is defined.
///
/// Ported from three.js's `roughnessmap_fragment.glsl.js`
/// (src/renderers/shaders/ShaderChunk/), copied unchanged.
const String fiber3dRoughnessmapFragment = r'''
float roughnessFactor = roughness;

#ifdef USE_ROUGHNESSMAP

	vec4 texelRoughness = texture2D( roughnessMap, vRoughnessMapUv );

	// reads channel G, compatible with a combined OcclusionRoughnessMetallic (RGB) texture
	roughnessFactor *= texelRoughness.g;

#endif
''';