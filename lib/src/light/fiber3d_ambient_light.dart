/// light that globally illuminates all objects in the scene equally.
///
/// It cannot cast shadows or shading gradients, since it has no direction
/// or position it's a flat, uniform contribution added to every surface.
///
class Fiber3DAmbientLight {
  /// The light's color, as 0xRRGGBB.
  final int color;

  /// The light's strength/intensity.
  final double intensity;

  const Fiber3DAmbientLight({
    this.color = 0xffffff,
    this.intensity = 1.0,
  });

  double get r => ((color >> 16) & 0xff) / 255.0;
  double get g => ((color >> 8) & 0xff) / 255.0;
  double get b => (color & 0xff) / 255.0;
}