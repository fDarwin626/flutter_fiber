/// A cel-shaded (toon) material (three.js's MeshToonMaterial equivalent):
/// direct light is stepped into discrete bands rather than shaded
/// continuously, giving the classic flat cartoon look. No specular term
/// at all matching three.js's own MeshToonMaterial, which dropped
/// shininess/specular entirely (unlike Lambert, which at least keeps a
/// specularStrength field even with nothing feeding it yet).
class Fiber3DToonMaterial {
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

  const Fiber3DToonMaterial({
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