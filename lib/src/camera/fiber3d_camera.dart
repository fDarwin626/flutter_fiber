import 'dart:math';
import '../core/fiber3d_vector3.dart';
import '../core/fiber3d_matrix4.dart';
import '../core/fiber3d_ray.dart';

/// A camera using perspective projection.
///
/// Ported from three.js's `PerspectiveCamera`, scoped down to v1's actual
/// needs: fov, aspect, near, far, position, and a look-at target. Zoom,
/// view offset (multi-monitor setups), filmGauge/filmOffset/focus, and
/// the focal-length conversions are all dropped — none appear in the
/// PRD's own usage example, and none are meaningful without features
///
/// Orbit/pinch-zoom controls are a separate, later feature — this class
/// only provides the view + projection math needed for correct 3D
/// rendering and, next, raycasting.
class Fiber3DCamera {
  final double fov;
  final double aspect;
  final double near;
  final double far;
  final Fiber3DVector3 position;
  final Fiber3DVector3 target;
  final Fiber3DVector3 up;

  Fiber3DCamera({
    this.fov = 50,
    this.aspect = 1,
    this.near = 0.1,
    this.far = 2000,
    this.position = const Fiber3DVector3(0, 0, 5),
    this.target = const Fiber3DVector3.zero(),
    this.up = const Fiber3DVector3(0, 1, 0),
  });

  /// Ported from three.js's PerspectiveCamera.updateProjectionMatrix,
  /// with zoom and view-offset logic dropped.
  Fiber3DMatrix4 get projectionMatrix {
    final top = near * tan(_degToRad(0.5 * fov));
    final height = 2 * top;
    final width = aspect * height;
    final left = -0.5 * width;

    final m = Fiber3DMatrix4();
    m.makePerspective(left, left + width, top, top - height, near, far);
    return m;
  }

  /// The camera's world transform (rotation from lookAt + position).
  ///
  /// See the class-level note on why this composes lookAt's rotation
  /// directly with position rather than going through a quaternion, the
  /// way three.js's Object3D-based Camera does.
  Fiber3DMatrix4 get worldMatrix {
    final world = Fiber3DMatrix4();
    world.lookAt(position, target, up);
    world.setPosition(position.x, position.y, position.z);
    return world;
  }

  /// The view matrix — inverse of the camera's world transform.
  Fiber3DMatrix4 get viewMatrix {
    final view = worldMatrix;
    view.invert();
    return view;
  }

  /// Builds a world-space ray from normalized device coordinates (each
  /// in [-1, 1]) — the same setFromCamera logic three.js's Raycaster uses:
  /// unproject a point in clip space back to world space via the inverse
  /// projection matrix, then transform by the camera's world matrix.
  Fiber3DRay rayFromNdc(double ndcX, double ndcY) {
    final invProjection = projectionMatrix;
    invProjection.invert();

    final world = worldMatrix;

    // Unproject a point at NDC z=0.5 (mid-frustum) back to camera space,
    // then into world space via the camera's world matrix.
    final camSpace = invProjection.transformPoint(ndcX, ndcY, 0.5);
    final worldPoint = world.transformPoint(camSpace[0], camSpace[1], camSpace[2]);

    final dx = worldPoint[0] - position.x;
    final dy = worldPoint[1] - position.y;
    final dz = worldPoint[2] - position.z;
    final len = sqrt(dx * dx + dy * dy + dz * dz);

    return Fiber3DRay(
      origin: position,
      direction: Fiber3DVector3(dx / len, dy / len, dz / len),
    );
  }
  double _degToRad(double degrees) => degrees * pi / 180.0;
}