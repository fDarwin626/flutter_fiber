import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_fiber/src/core/fiber3d_mutable_vector3.dart';

void main() {
  group('Fiber3DMutableVector3', () {
    test('defaults to zero', () {
      final v = Fiber3DMutableVector3();
      expect(v.x, 0);
      expect(v.y, 0);
      expect(v.z, 0);
    });

    test('mutates in place via direct field assignment', () {
      final v = Fiber3DMutableVector3();
      v.x += 5;
      v.y += 3;
      expect(v.x, 5);
      expect(v.y, 3);
    });

    test('add combines two vectors', () {
      final v = Fiber3DMutableVector3(1, 2, 3);
      v.add(Fiber3DMutableVector3(1, 1, 1));
      expect(v.x, 2);
      expect(v.y, 3);
      expect(v.z, 4);
    });

    test('normalize produces a unit vector', () {
      final v = Fiber3DMutableVector3(3, 0, 4);
      v.normalize();
      expect(v.length, closeTo(1.0, 1e-9));
    });

    test('toImmutable converts correctly', () {
      final v = Fiber3DMutableVector3(1, 2, 3);
      final immutable = v.toImmutable();
      expect(immutable.x, 1);
      expect(immutable.y, 2);
      expect(immutable.z, 3);
    });
  });
}