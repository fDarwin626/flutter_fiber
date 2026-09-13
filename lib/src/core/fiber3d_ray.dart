import 'dart:math';
import 'fiber3d_vector3.dart';

/// A ray with an origin and normalized direction, used for hit-testing
/// (tap/pan) against meshes.
///
/// Ported from three.js's `Ray`, scoped to what flutter_fiber v1 actually
/// needs: bounding-sphere intersection only. Per-triangle intersection,
/// box/plane intersection, and line-segment distance are all dropped —
/// coarse-first approach three.js's own Raycaster uses before it ever
/// checks triangles), not exact per-triangle picking.
class Fiber3DRay {
  final Fiber3DVector3 origin;
  final Fiber3DVector3 direction;

  const Fiber3DRay({required this.origin, required this.direction});

  /// Returns the distance along the ray to the closest intersection with
  /// a sphere at [center] with the given [radius], or null if there is
  /// no intersection. Ported from three.js's Ray.intersectSphere.
  double? intersectSphereDistance(Fiber3DVector3 center, double radius) {
    if (radius < 0) return null;

    final vx = center.x - origin.x;
    final vy = center.y - origin.y;
    final vz = center.z - origin.z;

    final tca = vx * direction.x + vy * direction.y + vz * direction.z;
    final d2 = (vx * vx + vy * vy + vz * vz) - tca * tca;
    final radius2 = radius * radius;

    if (d2 > radius2) return null;

    final thc = sqrt(radius2 - d2);

    final t0 = tca - thc;
    final t1 = tca + thc;

    if (t1 < 0) return null;
    if (t0 < 0) return t1;
    return t0;
  }
}