/// Declares the interpolated per-vertex color varying on the fragment
/// side, matching the vertex-side declaration.
///
/// Ported from three.js's `color_pars_fragment.glsl.js`
/// (src/renderers/shaders/ShaderChunk/), trimmed to USE_COLOR only.
const String fiber3dColorParsFragment = r'''
#ifdef USE_COLOR

	varying vec3 vColor;

#endif
''';