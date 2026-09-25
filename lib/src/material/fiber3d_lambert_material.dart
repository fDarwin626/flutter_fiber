/// A non-physically-based material for non-shiny surfaces (three.js's
/// MeshLambertMaterial equivalent): pure Lambertian diffuse response, no
/// specular highlight at all. Cheaper to shade than
/// [Fiber3DStandardMaterial] and appropriate when a matte look is
/// actually wanted, not just an approximation of one.
class Fiber3DLambertMaterial {
  /// Base color of the material, as 0xRRGGBB.
  final int color;

  /// Emissive (self-lit, glow) color, as 0xRRGGBB. Unaffected by lighting.
  final int emissive;

  /// Intensity multiplier applied to the emissive color.
  final double emissiveIntensity;

  /// Renders the geometry as a wireframe instead of filled triangles.
  final bool wireframe;

  /// Whether the material is rendered with flat (faceted) shading instead
  /// of smooth per-vertex-normal shading.
  final bool flatShading;

  const Fiber3DLambertMaterial({
    this.color = 0xffffff,
    this.emissive = 0x000000,
    this.emissiveIntensity = 1.0,
    this.wireframe = false,
    this.flatShading = false,
  });

  double get r => ((color >> 16) & 0xff) / 255.0;
  double get g => ((color >> 8) & 0xff) / 255.0;
  double get b => (color & 0xff) / 255.0;

  double get emissiveR => ((emissive >> 16) & 0xff) / 255.0;
  double get emissiveG => ((emissive >> 8) & 0xff) / 255.0;
  double get emissiveB => (emissive & 0xff) / 255.0;
}