///  `gl_FragColor` from `outgoingLight` and the material's
/// alpha, forcing alpha to 1.0 for opaque materials (unless transmission
/// overrides it).
///
/// Ported from three.js's `opaque_fragment.glsl.js`
/// (src/renderers/shaders/ShaderChunk/), copied unchanged. Runs before
/// `tonemapping_fragment` and `colorspace_fragment` in the shader body.
/// USE_TRANSMISSION is inactive until Section 4f.
const String fiber3dOpaqueFragment = r'''
#ifdef OPAQUE
diffuseColor.a = 1.0;
#endif

#ifdef USE_TRANSMISSION
diffuseColor.a *= material.transmissionAlpha;
#endif

gl_FragColor = vec4( outgoingLight, diffuseColor.a );
''';