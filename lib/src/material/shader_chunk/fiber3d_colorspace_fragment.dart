/// Applies the output color-space encoding to the final fragment color.
///
/// Ported from three.js's `colorspace_fragment.glsl.js`
/// (src/renderers/shaders/ShaderChunk/). `linearToOutputTexel` is not
/// defined here; three.js generates it in WebGLProgram.js
/// (getTexelEncodingFunction), so it is ported from there.
const String fiber3dColorspaceFragment = r'''
gl_FragColor = linearToOutputTexel( gl_FragColor );
''';