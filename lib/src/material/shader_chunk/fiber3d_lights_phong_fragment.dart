/// Fills the `BlinnPhongMaterial` struct from the material's uniforms.
/// `specularStrength` has the same gap Lambert's accumulation chunk has —
/// it's really fed by `specularmap_fragment`, which flutter_fiber hasn't
/// ported so it gets the same three.js default of 1.0 (no specular map
/// bound). Currently inert beyond that default: nothing scales it down.
///
/// Ported from three.js's `lights_phong_fragment.glsl.js`
/// (src/renderers/shaders/ShaderChunk/), with that one deviation.
/// Expects `diffuseColor`, `specular`, and `shininess` to be defined
/// earlier in main().
const String fiber3dLightsPhongFragment = r'''
BlinnPhongMaterial material;
material.diffuseColor = diffuseColor.rgb;
material.specularColor = specular;
material.specularShininess = shininess;
material.specularStrength = 1.0;
''';