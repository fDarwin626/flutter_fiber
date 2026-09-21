/// Applies tone mapping to the final fragment color when TONE_MAPPING is
/// defined.
///
/// Ported from three.js's `tonemapping_fragment.glsl.js`
/// (src/renderers/shaders/ShaderChunk/). `toneMapping()` is not defined
/// here; three.js generates it in WebGLProgram.js
/// (getToneMappingFunction), so it is ported from there.
const String fiber3dTonemappingFragment = r'''
#if defined( TONE_MAPPING )

	gl_FragColor.rgb = toneMapping( gl_FragColor.rgb );

#endif
''';