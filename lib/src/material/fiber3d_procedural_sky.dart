import 'dart:math';

import 'fiber3d_prefiltered_cube.dart';

class Fiber3DProceduralSky {
  /// Radiance straight up (y = 1).
  final List<double> skyColor;

  /// Radiance straight down (y = -1).
  final List<double> groundColor;

  /// Radiance at the horizon (y = 0), blended between [skyColor] and
  /// [groundColor] on either side of it.
  final List<double> horizonColor;

  /// Direction the (optional) sun points from, i.e. the direction you'd
  /// look to see it. Normalized internally. Null disables the sun disc.
  final List<double>? sunDirection;

  /// Sun disc radiance, added on top of the sky/ground gradient.
  final List<double> sunColor;

  /// Cosine of the sun disc's angular radius. Larger (closer to 1) means
  /// a smaller, sharper disc.
  final double sunCosAngle;

  final List<double> _sunDirNormalized;

  Fiber3DProceduralSky({
    this.skyColor = const [0.4, 0.6, 0.9],
    this.groundColor = const [0.2, 0.2, 0.2],
    this.horizonColor = const [0.7, 0.75, 0.8],
    this.sunDirection = const [0.3, 0.6, 0.5],
    this.sunColor = const [8.0, 7.5, 6.5],
    this.sunCosAngle = 0.999,
  }) : _sunDirNormalized = _normalized(sunDirection);

  static List<double> _normalized(List<double>? v) {
    if (v == null) return const [0.0, 1.0, 0.0];
    final len = sqrt(v[0] * v[0] + v[1] * v[1] + v[2] * v[2]);
    if (len <= 0) return const [0.0, 1.0, 0.0];
    return [v[0] / len, v[1] / len, v[2] / len];
  }

  /// Smoothstep-blended two-tone gradient by [y], plus the sun disc when
  /// [sunDirection] is set. Suitable as [Fiber3DRadianceFunction].
  void radiance(double x, double y, double z, List<double> out) {
    // t = 0 at horizon, 1 at zenith/nadir; smoothstep for a soft band
    // rather than a hard seam at y = 0.
    if (y >= 0) {
      final t = _smoothstep(0.0, 0.35, y);
      out[0] = _lerp(horizonColor[0], skyColor[0], t);
      out[1] = _lerp(horizonColor[1], skyColor[1], t);
      out[2] = _lerp(horizonColor[2], skyColor[2], t);
    } else {
      final t = _smoothstep(0.0, 0.35, -y);
      out[0] = _lerp(horizonColor[0], groundColor[0], t);
      out[1] = _lerp(horizonColor[1], groundColor[1], t);
      out[2] = _lerp(horizonColor[2], groundColor[2], t);
    }

    if (sunDirection != null) {
      final d = x * _sunDirNormalized[0] +
          y * _sunDirNormalized[1] +
          z * _sunDirNormalized[2];
      if (d > sunCosAngle) {
        final edge = _smoothstep(sunCosAngle, 1.0, d);
        out[0] += sunColor[0] * edge;
        out[1] += sunColor[1] * edge;
        out[2] += sunColor[2] * edge;
      }
    }
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  static double _smoothstep(double edge0, double edge1, double x) {
    final t = ((x - edge0) / (edge1 - edge0)).clamp(0.0, 1.0);
    return t * t * (3.0 - 2.0 * t);
  }
}