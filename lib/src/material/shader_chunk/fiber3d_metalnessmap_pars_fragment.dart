/// Declares the metalness-map texture uniform, guarded by
/// USE_METALNESSMAP. Same always-on + white-fallback pattern as `map`.
///
/// Ported from three.js's `metalnessmap_pars_fragment.glsl.js`
/// (src/renderers/shaders/ShaderChunk/), copied unchanged.
const String fiber3dMetalnessmapParsFragment = r'''
#ifdef USE_METALNESSMAP

	uniform sampler2D metalnessMap;

#endif
''';