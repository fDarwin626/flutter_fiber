/// Copies the `color` attribute into the interpolated varying.
///
/// Ported from three.js's `color_vertex.glsl.js`
/// (src/renderers/shaders/ShaderChunk/), trimmed to the USE_COLOR
/// (vec3) branch only — no alpha, no instancing/batching.
const String fiber3dColorVertex = r'''
#ifdef USE_COLOR

	vColor = vec3( 1.0 );
	vColor *= color;

#endif
''';