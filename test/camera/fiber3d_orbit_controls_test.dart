import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_fiber/src/camera/fiber3d_orbit_controls.dart';
import 'package:flutter_fiber/src/camera/fiber3d_camera.dart';
import 'package:flutter_fiber/src/core/fiber3d_vector3.dart';

void main() {
  group('Fiber3DOrbitControls', () {
    test('camera getter round-trips the seed camera position', () {
      final seed = Fiber3DCamera(position: const Fiber3DVector3(0, 0, 5));
      final controls = Fiber3DOrbitControls(camera: seed);

      final result = controls.camera;
      expect(result.position.x, closeTo(0, 1e-9));
      expect(result.position.y, closeTo(0, 1e-9));
      expect(result.position.z, closeTo(5, 1e-9));
    });

    test('rotate changes theta, moving the camera around the target', () {
      final seed = Fiber3DCamera(position: const Fiber3DVector3(0, 0, 5));
      final controls = Fiber3DOrbitControls(camera: seed);

      // Rotate a quarter turn (viewportHeight chosen so deltaX/height * 2π = π/2).
      controls.rotate(100, 0, 400); // 2π * 100/400 = π/2

      final result = controls.camera;
      // After a 90° rotation around Y, a camera that was at (0,0,5)
      // should now be roughly on the X axis, not Z.
      expect(result.position.z.abs(), lessThan(1.0));
    });

    test('zoom moves the camera closer or further from target', () {
      final seed = Fiber3DCamera(position: const Fiber3DVector3(0, 0, 10));
      final controls = Fiber3DOrbitControls(camera: seed);

      controls.zoom(2.0); // zoom in — should halve the distance
      final closer = controls.camera;
      final closerDist = sqrt(
          closer.position.x * closer.position.x +
          closer.position.y * closer.position.y +
          closer.position.z * closer.position.z);
      expect(closerDist, closeTo(5.0, 1e-6));
    });

    test('zoom respects minDistance and maxDistance clamps', () {
      final seed = Fiber3DCamera(position: const Fiber3DVector3(0, 0, 10));
      final controls = Fiber3DOrbitControls(
        camera: seed,
        minDistance: 5,
        maxDistance: 20,
      );

      controls.zoom(100); // would zoom way past minDistance without clamping
      var result = controls.camera;
      var dist = sqrt(result.position.x * result.position.x +
          result.position.y * result.position.y +
          result.position.z * result.position.z);
      expect(dist, closeTo(5.0, 1e-6));

      controls.zoom(0.001); // would zoom way past maxDistance without clamping
      result = controls.camera;
      dist = sqrt(result.position.x * result.position.x +
          result.position.y * result.position.y +
          result.position.z * result.position.z);
      expect(dist, closeTo(20.0, 1e-6));
    });

    test('rotate clamps phi away from the poles', () {
      final seed = Fiber3DCamera(position: const Fiber3DVector3(0, 0, 5));
      final controls = Fiber3DOrbitControls(camera: seed);

      // Huge deltaY should try to rotate way past the pole.
      controls.rotate(0, 100000, 400);

      final result = controls.camera;
      final dist = sqrt(result.position.x * result.position.x +
          result.position.y * result.position.y +
          result.position.z * result.position.z);
      // Distance from target should still be ~5 even at the clamped pole.
      expect(dist, closeTo(5.0, 1e-6));
    });
  });
}