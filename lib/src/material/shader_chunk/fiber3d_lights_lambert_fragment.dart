/// Ported from three.js's `lights_lambert_fragment.glsl.js`, with one
/// deliberate deviation: real three.js reads `specularStrength` from a
/// variable populated by `specularmap_fragment` (defaults to 1.0 with no
/// specular map bound). flutter_fiber hasn't ported specular maps yet,
/// so this is hardcoded to 1.0 directly numerically identical to the
/// real default today. Revisit when specular-map support lands.
const String fiber3dLightsLambertFragment = r'''
LambertMaterial material;
material.diffuseColor = diffuseColor.rgb;
material.specularStrength = 1.0;
''';