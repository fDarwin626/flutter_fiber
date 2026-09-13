import 'dart:math';
import '../core/fiber3d_vector3.dart';

/// A light that emits from a single point in all directions, replicating
/// a bare lightbulb.
///
/// Ported from three.js's `PointLight`, with shadow support dropped
/// entirely shadow mapping is explicitly out of scope for flutter_fiber
/// v1 (deferred to v2+ per the PRD's non-goals).
class Fiber3DPointLight {
  /// The light's color, as 0xRRGGBB.
  final int color;

  /// The light's strength/intensity, measured in candela (cd).
  final double intensity;

  /// Maximum range of the light. 0 means no limit (inverse-square falloff
  /// to infinity).
  final double distance;

  /// How much the light dims over distance. For physically-correct
  /// rendering this should stay at its default.
  final double decay;

  /// World-space position of the light.
  final Fiber3DVector3 position;

  const Fiber3DPointLight({
    this.color = 0xffffff,
    this.intensity = 1.0,
    this.distance = 0,
    this.decay = 2,
    this.position = const Fiber3DVector3.zero(),
  });

  /// Luminous power in lumens, derived from intensity (candela) for an
  /// isotropic point source: power = 4π × intensity.
  double get power => intensity * 4 * pi;

  double get r => ((color >> 16) & 0xff) / 255.0;
  double get g => ((color >> 8) & 0xff) / 255.0;
  double get b => (color & 0xff) / 255.0;
}