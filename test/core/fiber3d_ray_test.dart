import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_fiber/src/core/fiber3d_ray.dart';
import 'package:flutter_fiber/src/core/fiber3d_vector3.dart';

void main() {
  group('Fiber3DRay', () {
    test('ray straight through a sphere\'s center hits at the near edge', () {
      const ray = Fiber3DRay(
        origin: Fiber3DVector3(0, 0, 5),
        direction: Fiber3DVector3(0, 0, -1),
      );

      final t = ray.intersectSphereDistance(const Fiber3DVector3.zero(), 1);
      expect(t, closeTo(4.0, 1e-9)); // 5 - radius(1) = 4
    });

    test('ray missing the sphere entirely returns null', () {
      const ray = Fiber3DRay(
        origin: Fiber3DVector3(10, 10, 5),
        direction: Fiber3DVector3(0, 0, -1),
      );

      final t = ray.intersectSphereDistance(const Fiber3DVector3.zero(), 1);
      expect(t, isNull);
    });

    test('ray pointing away from the sphere returns null', () {
      const ray = Fiber3DRay(
        origin: Fiber3DVector3(0, 0, 5),
        direction: Fiber3DVector3(0, 0, 1), // pointing away
      );

      final t = ray.intersectSphereDistance(const Fiber3DVector3.zero(), 1);
      expect(t, isNull);
    });

    test('ray originating inside the sphere hits the exit point', () {
      const ray = Fiber3DRay(
        origin: Fiber3DVector3(0, 0, 0),
        direction: Fiber3DVector3(0, 0, -1),
      );

      final t = ray.intersectSphereDistance(const Fiber3DVector3.zero(), 1);
      expect(t, closeTo(1.0, 1e-9));
    });
  });
}