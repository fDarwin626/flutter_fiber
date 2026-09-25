/// A non-physically-based material with a classic Blinn-Phong specular
/// highlight (three.js's MeshPhongMaterial equivalent): Lambertian
/// diffuse plus a tunable specular highlight controlled by `specular`
/// color and `shininess`, rather than the roughness/metalness model
/// [Fiber3DStandardMaterial] uses.
class Fiber3DPhongMaterial {
  /// Base color of the material, as 0xRRGGBB.
  final int color;

  /// Emissive (self-lit, glow) color, as 0xRRGGBB. Unaffected by lighting.
  final int emissive;

  /// Intensity multiplier applied to the emissive color.
  final double emissiveIntensity;

  /// Color of the specular highlight, as 0xRRGGBB.
  final int specular;

  /// Controls the tightness/size of the specular highlight — higher
  /// values give a smaller, sharper highlight (a "shinier" look).
  final double shininess;

  /// Renders the geometry as a wireframe instead of filled triangles.
  final bool wireframe;

  /// Whether the material is rendered with flat (faceted) shading instead
  /// of smooth per-vertex-normal shading.
  final bool flatShading;

  const Fiber3DPhongMaterial({
    this.color = 0xffffff,
    this.emissive = 0x000000,
    this.emissiveIntensity = 1.0,
    this.specular = 0x111111,
    this.shininess = 30.0,
    this.wireframe = false,
    this.flatShading = false,
  });

  double get r => ((color >> 16) & 0xff) / 255.0;
  double get g => ((color >> 8) & 0xff) / 255.0;
  double get b => (color & 0xff) / 255.0;

  double get emissiveR => ((emissive >> 16) & 0xff) / 255.0;
  double get emissiveG => ((emissive >> 8) & 0xff) / 255.0;
  double get emissiveB => (emissive & 0xff) / 255.0;

  double get specularR => ((specular >> 16) & 0xff) / 255.0;
  double get specularG => ((specular >> 8) & 0xff) / 255.0;
  double get specularB => (specular & 0xff) / 255.0;
}