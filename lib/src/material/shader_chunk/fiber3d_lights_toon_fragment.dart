/// Fills the `ToonMaterial` struct from the material's diffuse color.
/// Nothing else to fill Toon has no specularStrength/shininess-style
/// gap the way Lambert/Phong did, since MeshToonMaterial genuinely has
/// no specular response at all.
///
/// Ported from three.js's `lights_toon_fragment.glsl.js`
/// (src/renderers/shaders/ShaderChunk/), copied unchanged. Expects
/// `diffuseColor` to be defined earlier in main().
const String fiber3dLightsToonFragment = r'''
ToonMaterial material;
material.diffuseColor = diffuseColor.rgb;
''';