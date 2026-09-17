import 'fiber3d_cylinder.dart';

/// A geometry class for representing a cone.
///
/// Ported from three.js's `ConeGeometry` (src/geometries/ConeGeometry.js),
/// which is itself a thin subclass of `CylinderGeometry` with
/// `radiusTop` fixed at 0. Mirrors that inheritance relationship
/// directly a cone is just a cylinder whose top radius is zero.
class Fiber3DCone extends Fiber3DCylinder {
  Fiber3DCone({
    double radius = 1,
    double height = 1,
    int radialSegments = 32,
    int heightSegments = 1,
    bool openEnded = false,
    double thetaStart = 0,
    double thetaLength = 2 * 3.141592653589793,
  }) : super(
          radiusTop: 0,
          radiusBottom: radius,
          height: height,
          radialSegments: radialSegments,
          heightSegments: heightSegments,
          openEnded: openEnded,
          thetaStart: thetaStart,
          thetaLength: thetaLength,
        );
}