import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_fiber/src/camera/fiber3d_camera.dart';

void main() {
  group('Fiber3DCamera', () {
    test('defaults match three.js PerspectiveCamera defaults', () {
      final camera = Fiber3DCamera();

      expect(camera.fov, 50);
      expect(camera.aspect, 1);
      expect(camera.near, 0.1);
      expect(camera.far, 2000);
    });

    test('projectionMatrix has perspective markers', () {
      final camera = Fiber3DCamera();
      final m = camera.projectionMatrix;

      expect(m.elements[11], -1);
      expect(m.elements[15], 0);
    });

    test('viewMatrix places the world origin at (0,0,-5) for a camera at (0,0,5) looking at origin', () {
      final camera = Fiber3DCamera();
      final view = camera.viewMatrix;

      final result = view.transformPoint(0, 0, 0);
      expect(result[0], closeTo(0, 1e-9));
      expect(result[1], closeTo(0, 1e-9));
      expect(result[2], closeTo(-5, 1e-9));
    });
  });
}