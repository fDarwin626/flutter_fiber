class Fiber3DBasicMaterial {
  /// Color of the material, as 0xRRGGBB (matches three.js's hex convention).
  final int color;

  /// Renders the geometry as a wireframe instead of filled triangles.
  final bool wireframe;

  const Fiber3DBasicMaterial({
    this.color = 0xffffff,
    this.wireframe = false,
  });

  /// Red channel, normalized to [0, 1].
  double get r => ((color >> 16) & 0xff) / 255.0;

  /// Green channel, normalized to [0, 1].
  double get g => ((color >> 8) & 0xff) / 255.0;

  /// Blue channel, normalized to [0, 1].
  double get b => (color & 0xff) / 255.0;
}