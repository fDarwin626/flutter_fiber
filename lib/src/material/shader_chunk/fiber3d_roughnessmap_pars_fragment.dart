/// Declares the roughness-map texture uniform, guarded by
/// USE_ROUGHNESSMAP. flutter_fiber always defines USE_ROUGHNESSMAP for
/// the PBR shader and binds a white 1x1 fallback when a material has no
/// real roughnessMap set same one-program-per-material-type pattern
/// as `map`/USE_MAP.
///
/// Ported from three.js's `roughnessmap_pars_fragment.glsl.js`
/// (src/renderers/shaders/ShaderChunk/), copied unchanged.
const String fiber3dRoughnessmapParsFragment = r'''
#ifdef USE_ROUGHNESSMAP

	uniform sampler2D roughnessMap;

#endif
''';