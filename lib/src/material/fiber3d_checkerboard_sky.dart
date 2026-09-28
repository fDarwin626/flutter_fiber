import 'dart:math';

/// A high-contrast black/white checkerboard over the sphere, usable
/// directly as a Fiber3DRadianceFunction.
///
/// Exists purely to make roughness-dependent environment blur visually
/// unmistakable: a smooth gradient (like Fiber3DProceduralSky's default)
/// barely changes when blurred, so it can't distinguish "the mip
/// selection is broken" from "the source has nothing to blur." A
/// checkerboard's hard edges make that distinction obvious at a glance —
/// sharp squares at low roughness, a flat gray blur at high roughness.
class Fiber3DCheckerboardSky {
  /// Number of checker columns around the full longitude (2*pi).
  final int columns;

  /// Number of checker rows from pole to pole (pi).
  final int rows;

  final List<double> lightColor;
  final List<double> darkColor;

  const Fiber3DCheckerboardSky({
    this.columns = 16,
    this.rows = 8,
    this.lightColor = const [1.0, 1.0, 1.0],
    this.darkColor = const [0.02, 0.02, 0.02],
  });

  /// Suitable as Fiber3DRadianceFunction. (x, y, z) is assumed unit
  /// length, matching every other radiance source in the pipeline.
  void radiance(double x, double y, double z, List<double> out) {
    // Longitude in [0, 1), latitude in [0, 1] (0 = +Y pole, 1 = -Y pole).
    final u = atan2(z, x) / (2 * pi) + 0.5;
    final v = acos(y.clamp(-1.0, 1.0)) / pi;

    final col = (u * columns).floor();
    final row = (v * rows).floor();
    final light = (col + row) % 2 == 0;

    final c = light ? lightColor : darkColor;
    out[0] = c[0];
    out[1] = c[1];
    out[2] = c[2];
  }
}