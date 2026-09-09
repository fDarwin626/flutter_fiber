import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_fiber/src/geometry/fiber3d_sphere.dart';
import 'dart:math';
void main() {
  group('Fiber3DSphere', () {
    test('default sphere has correct vertex count', () {
      final sphere = Fiber3DSphere();

      // (widthSegments + 1) * (heightSegments + 1) vertices
      final expectedVertexCount = (32 + 1) * (16 + 1);
      expect(sphere.positions.length, expectedVertexCount * 3);
      expect(sphere.normals.length, expectedVertexCount * 3);
      expect(sphere.uvs.length, expectedVertexCount * 2);
    });

    test('every vertex lies on the sphere surface (radius 1)', () {
      final sphere = Fiber3DSphere();

      for (var i = 0; i < sphere.positions.length; i += 3) {
        final x = sphere.positions[i];
        final y = sphere.positions[i + 1];
        final z = sphere.positions[i + 2];
        final dist = x * x + y * y + z * z;
        expect(dist, closeTo(1.0, 1e-6));
      }
    });

    test('every normal is a unit vector', () {
      final sphere = Fiber3DSphere();

      for (var i = 0; i < sphere.normals.length; i += 3) {
        final nx = sphere.normals[i];
        final ny = sphere.normals[i + 1];
        final nz = sphere.normals[i + 2];
        final len = nx * nx + ny * ny + nz * nz;
        expect(len, closeTo(1.0, 1e-6));
      }
    });

    test('normal matches normalized position for a non-pole vertex', () {
      final sphere = Fiber3DSphere();

      // Pick a vertex safely away from either pole.
      const i = 300;
      final px = sphere.positions[i * 3];
      final py = sphere.positions[i * 3 + 1];
      final pz = sphere.positions[i * 3 + 2];

      expect(sphere.normals[i * 3], closeTo(px, 1e-9));
      expect(sphere.normals[i * 3 + 1], closeTo(py, 1e-9));
      expect(sphere.normals[i * 3 + 2], closeTo(pz, 1e-9));
    });

    test('respects a custom radius', () {
      final sphere = Fiber3DSphere(radius: 5);

      for (var i = 0; i < sphere.positions.length; i += 3) {
        final x = sphere.positions[i];
        final y = sphere.positions[i + 1];
        final z = sphere.positions[i + 2];
        final dist = sqrt(x * x + y * y + z * z);
        expect(dist, closeTo(5.0, 1e-6));
      }
    });

    test('minimum segment counts are enforced', () {
      final sphere = Fiber3DSphere(widthSegments: 1, heightSegments: 1);

      expect(sphere.widthSegments, 3);
      expect(sphere.heightSegments, 2);
    });
  });
}