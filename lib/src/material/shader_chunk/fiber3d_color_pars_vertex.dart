/// Declares the interpolated per-vertex color varying, when the
/// USE_COLOR feature is active. flutter_fiber only supports the plain
/// USE_COLOR (vec3) path no USE_COLOR_ALPHA, no instancing/batching
/// color, since flutter_fiber has neither instancing nor batching.
///
/// Ported from three.js's `color_pars_vertex.glsl.js`
/// (src/renderers/shaders/ShaderChunk/), trimmed to the USE_COLOR
/// branch only.
const String fiber3dColorParsVertex = r'''
#ifdef USE_COLOR

	varying vec3 vColor;

#endif
''';