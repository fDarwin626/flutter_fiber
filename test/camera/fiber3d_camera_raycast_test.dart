import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_fiber/src/camera/fiber3d_camera.dart';

void main() {
  group('Fiber3DCamera.rayFromNdc', () {
    test('a tap at NDC center (0,0) points toward the camera\'s target', () {
      final camera = Fiber3DCamera(); // at (0,0,5), looking at origin

      final ray = camera.rayFromNdc(0, 0);

      // Direction should point roughly toward -Z (from (0,0,5) toward origin).
      expect(ray.direction.z, lessThan(0));
      expect(ray.direction.x.abs(), lessThan(0.01));
      expect(ray.direction.y.abs(), lessThan(0.01));
    });

    test('ray origin matches the camera position', () {
      final camera = Fiber3DCamera();
      final ray = camera.rayFromNdc(0, 0);

      expect(ray.origin.x, camera.position.x);
      expect(ray.origin.y, camera.position.y);
      expect(ray.origin.z, camera.position.z);
    });
  });
}