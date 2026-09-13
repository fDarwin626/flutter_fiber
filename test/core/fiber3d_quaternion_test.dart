import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_fiber/src/core/fiber3d_quaternion.dart';
import 'package:flutter_fiber/src/core/fiber3d_vector3.dart';
import 'package:flutter_fiber/src/core/fiber3d_matrix4.dart';

void main() {
  group('Fiber3DQuaternion', () {
    test('defaults to identity', () {
      final q = Fiber3DQuaternion();
      expect(q.x, 0);
      expect(q.y, 0);
      expect(q.z, 0);
      expect(q.w, 1);
    });

    test('setFromAxisAngle produces a unit quaternion', () {
      final q = Fiber3DQuaternion();
      q.setFromAxisAngle(const Fiber3DVector3(0, 1, 0), pi / 2);
      expect(q.length(), closeTo(1.0, 1e-9));
    });

    test('setFromEuler matches setFromAxisAngle for a pure Y rotation', () {
      final fromEuler = Fiber3DQuaternion();
      fromEuler.setFromEuler(0, pi / 2, 0);

      final fromAxis = Fiber3DQuaternion();
      fromAxis.setFromAxisAngle(const Fiber3DVector3(0, 1, 0), pi / 2);

      expect(fromEuler.x, closeTo(fromAxis.x, 1e-9));
      expect(fromEuler.y, closeTo(fromAxis.y, 1e-9));
      expect(fromEuler.z, closeTo(fromAxis.z, 1e-9));
      expect(fromEuler.w, closeTo(fromAxis.w, 1e-9));
    });

    test('setFromRotationMatrix round-trips a Y rotation matrix', () {
      final m = Fiber3DMatrix4();
      const angle = pi / 3;
      m.elements[0] = cos(angle);
      m.elements[2] = -sin(angle);
      m.elements[8] = sin(angle);
      m.elements[10] = cos(angle);
      
      final q = Fiber3DQuaternion();
      q.setFromRotationMatrix(m);

      final expected = Fiber3DQuaternion();
      expected.setFromAxisAngle(const Fiber3DVector3(0, 1, 0), angle);

      expect(q.x, closeTo(expected.x, 1e-6));
      expect(q.y, closeTo(expected.y, 1e-6));
      expect(q.z, closeTo(expected.z, 1e-6));
      expect(q.w, closeTo(expected.w, 1e-6));
    });

    test('setFromUnitVectors gives identity for identical vectors', () {
      final q = Fiber3DQuaternion();
      q.setFromUnitVectors(
          const Fiber3DVector3(0, 1, 0), const Fiber3DVector3(0, 1, 0));

      expect(q.x, closeTo(0, 1e-9));
      expect(q.y, closeTo(0, 1e-9));
      expect(q.z, closeTo(0, 1e-9));
      expect(q.w, closeTo(1, 1e-9));
    });

    test('multiplying a quaternion by its inverse gives identity', () {
      final q = Fiber3DQuaternion();
      q.setFromAxisAngle(const Fiber3DVector3(1, 0, 0), pi / 4);

      final inv = q.clone();
      inv.invert();

      final result = Fiber3DQuaternion();
      result.multiplyQuaternions(q, inv);

      expect(result.x, closeTo(0, 1e-9));
      expect(result.y, closeTo(0, 1e-9));
      expect(result.z, closeTo(0, 1e-9));
      expect(result.w, closeTo(1, 1e-9));
    });
  });
}