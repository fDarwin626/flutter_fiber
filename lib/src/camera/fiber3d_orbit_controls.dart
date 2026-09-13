import 'dart:math';
import '../core/fiber3d_vector3.dart';
import 'fiber3d_camera.dart';

/// Orbit controls: lets the camera orbit around a target via drag, and
/// zoom via pinch/dolly.
///
/// A scoped-down port of three.js's `OrbitControls` addon, matching what
/// the PRD's own usage example needs (`orbitEnabled: true`) — damping/
/// inertia, panning, keyboard controls, auto-rotate, mouse-button
/// switching, and screen-space panning mode are all dropped. The orbit
/// math (spherical coordinates around a target, ported from
/// OrbitControls' update()/_rotateLeft/_rotateUp) and pinch-zoom distance
/// clamping (_dollyIn/_dollyOut/_clampDistance) are kept.
class Fiber3DOrbitControls {
  final Fiber3DVector3 target;
  final double minDistance;
  final double maxDistance;
  final double rotateSpeed;
  final double zoomSpeed;

  // Preserved from the seed camera — orbiting/zooming only ever changes
  // position, never these.
  final double _fov;
  final double _aspect;
  final double _near;
  final double _far;

  double _radius = 0;
  double _theta = 0;
  double _phi = 0;

  static const double _epsilon = 1e-6;

  Fiber3DOrbitControls({
    required Fiber3DCamera camera,
    this.target = const Fiber3DVector3.zero(),
    this.minDistance = 0,
    this.maxDistance = double.infinity,
    this.rotateSpeed = 1.0,
    this.zoomSpeed = 1.0,
  })  : _fov = camera.fov,
        _aspect = camera.aspect,
        _near = camera.near,
        _far = camera.far {
    _setFromPosition(camera.position);
  }

  void _setFromPosition(Fiber3DVector3 position) {
    final dx = position.x - target.x;
    final dy = position.y - target.y;
    final dz = position.z - target.z;

    _radius = sqrt(dx * dx + dy * dy + dz * dz);
    if (_radius == 0) {
      _theta = 0;
      _phi = 0;
      return;
    }
    _theta = atan2(dx, dz);
    _phi = acos((dy / _radius).clamp(-1.0, 1.0));
  }

  /// Rotates the camera around [target]. [deltaX]/[deltaY] are pixel
  /// deltas from a drag gesture; [viewportHeight] normalizes rotation
  /// speed to canvas size — same `2π * delta / clientHeight` formula
  /// OrbitControls itself uses (height for both axes, so aspect ratio
  /// doesn't distort rotation speed).
  void rotate(double deltaX, double deltaY, double viewportHeight) {
    final twoPi = 2 * pi;

    _theta -= twoPi * deltaX / viewportHeight * rotateSpeed;
    _phi -= twoPi * deltaY / viewportHeight * rotateSpeed;

    // Clamp phi away from the poles so orbiting straight overhead/underneath
    // can't flip the camera upside down — ported from Spherical.makeSafe.
    _phi = _phi.clamp(_epsilon, pi - _epsilon);
  }

  /// Zooms by dollying toward/away from [target].
  /// [scaleFactor] > 1 zooms in (moves closer); < 1 zooms out — matches
  /// Flutter's ScaleGestureDetector convention (pinch-out increases scale).
  void zoom(double scaleFactor) {
    if (scaleFactor <= 0) return;
    _radius = (_radius / scaleFactor).clamp(minDistance, maxDistance);
  }

  /// The current camera, recomputed from the orbit's spherical state.
  Fiber3DCamera get camera {
    final sinPhiRadius = sin(_phi) * _radius;
    final x = sinPhiRadius * sin(_theta);
    final y = cos(_phi) * _radius;
    final z = sinPhiRadius * cos(_theta);

    return Fiber3DCamera(
      fov: _fov,
      aspect: _aspect,
      near: _near,
      far: _far,
      position: Fiber3DVector3(target.x + x, target.y + y, target.z + z),
      target: target,
    );
  }
}