import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_fiber/src/geometry/fiber3d_ring.dart';

void main() {
  group('Fiber3DRing', () {
    test('default ring has correct buffer sizes', () {
      final ring = Fiber3DRing();

      // (thetaSegments+1) * (phiSegments+1) vertices
      final expectedVerts = (32 + 1) * (1 + 1);
      expect(ring.positions.length, expectedVerts * 3);
      expect(ring.normals.length, expectedVerts * 3);
      expect(ring.uvs.length, expectedVerts * 2);
      expect(ring.indices.length, 32 * 1 * 6); // thetaSegments * phiSegments * 2 tris * 3
    });

    test('all normals point along +Z', () {
      final ring = Fiber3DRing();

      for (var i = 0; i < ring.normals.length; i += 3) {
        expect(ring.normals[i], 0);
        expect(ring.normals[i + 1], 0);
        expect(ring.normals[i + 2], 1);
      }
    });

    test('all vertices lie flat on Z=0', () {
      final ring = Fiber3DRing();

      for (var i = 0; i < ring.positions.length; i += 3) {
        expect(ring.positions[i + 2], 0);
      }
    });

    test('inner ring vertices are at innerRadius, outer at outerRadius', () {
      final ring = Fiber3DRing(innerRadius: 1, outerRadius: 3, thetaSegments: 8, phiSegments: 1);

      // First (thetaSegments+1) vertices are the inner ring (j=0).
      for (var i = 0; i <= 8; i++) {
        final x = ring.positions[i * 3];
        final y = ring.positions[i * 3 + 1];
        final r = sqrt(x * x + y * y);
        expect(r, closeTo(1.0, 1e-6));
      }

      // Last (thetaSegments+1) vertices are the outer ring (j=phiSegments).
      final outerStart = 9; // (thetaSegments+1) * 1
      for (var i = 0; i <= 8; i++) {
        final idx = outerStart + i;
        final x = ring.positions[idx * 3];
        final y = ring.positions[idx * 3 + 1];
        final r = sqrt(x * x + y * y);
        expect(r, closeTo(3.0, 1e-6));
      }
    });

    test('minimum segment counts are enforced', () {
      final ring = Fiber3DRing(thetaSegments: 1, phiSegments: 0);

      expect(ring.thetaSegments, 3);
      expect(ring.phiSegments, 1);
    });
  });
}