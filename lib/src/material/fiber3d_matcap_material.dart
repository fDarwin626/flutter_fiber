class Fiber3DMatcapMaterial {
  /// Base color of the material, as 0xRRGGBB.
  final int color;

  /// Renders the geometry as a wireframe instead of filled triangles.
  final bool wireframe;

  /// Whether the material is rendered with flat (faceted) shading instead
  /// of smooth per-vertex-normal shading.
  final bool flatShading;

  const Fiber3DMatcapMaterial({
    this.color = 0xffffff,
    this.wireframe = false,
    this.flatShading = false,
  });

  double get r => ((color >> 16) & 0xff) / 255.0;
  double get g => ((color >> 8) & 0xff) / 255.0;
  double get b => (color & 0xff) / 255.0;
}