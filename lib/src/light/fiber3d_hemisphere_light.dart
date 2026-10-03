import '../core/fiber3d_vector3.dart';

/// A light that blends between a sky color and a ground color depending
/// on a surface normal's alignment with [direction] no position, no
/// falloff, no shadows a soft ambient-like fill that at least varies
/// with orientation, unlike Fiber3DAmbientLight's flat contribution.
///
/// Ported from three.js's `HemisphereLight`. Three.js derives its
/// light's direction from a world-space position (defaulting to
/// straight up); flutter_fiber has no lights-in-the-scene-graph
/// plumbing to make that meaningful yet, so [direction] is taken
/// directly rather than derived from a position, matching the shader
/// struct's own `direction` field exactly (see
/// fiber3d_lights_pars_begin.dart's HemisphereLight/
/// getHemisphereLightIrradiance).
class Fiber3DHemisphereLight {
  /// Color blended in on surfaces facing toward [direction].
  final int skyColor;

  /// Color blended in on surfaces facing away from [direction].
  final int groundColor;

  /// The light's strength/intensity.
  final double intensity;

  /// World-space direction surfaces are compared against. Does not need
  /// to be normalized the shader normal it's dotted against already
  /// is, but the blend weight is a raw dot product, so an unnormalized
  /// direction would scale the sky/ground blend unevenly; normalize
  /// this yourself if you're not passing a unit vector.
  final Fiber3DVector3 direction;

  const Fiber3DHemisphereLight({
    this.skyColor = 0xffffff,
    this.groundColor = 0x444444,
    this.intensity = 1.0,
    this.direction = const Fiber3DVector3(0, 1, 0),
  });

  double get skyR => ((skyColor >> 16) & 0xff) / 255.0;
  double get skyG => ((skyColor >> 8) & 0xff) / 255.0;
  double get skyB => (skyColor & 0xff) / 255.0;

  double get groundR => ((groundColor >> 16) & 0xff) / 255.0;
  double get groundG => ((groundColor >> 8) & 0xff) / 255.0;
  double get groundB => (groundColor & 0xff) / 255.0;
}