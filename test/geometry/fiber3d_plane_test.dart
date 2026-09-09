import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_fiber/src/geometry/fiber3d_plane.dart';

void main() {
  group('Fiber3DPlane', () {
    test('default 1x1 plane has correct buffer sizes', () {
      final plane = Fiber3DPlane();

      // (widthSegments+1) * (heightSegments+1) vertices, default 1x1 segments = 2x2 grid
      expect(plane.positions.length, 4 * 3);
      expect(plane.normals.length, 4 * 3);
      expect(plane.uvs.length, 4 * 2);
      expect(plane.indices.length, 6); // 1 segment * 2 tris * 3 indices
    });

    test('all normals point along +Z', () {
      final plane = Fiber3DPlane();

      for (var i = 0; i < plane.normals.length; i += 3) {
        expect(plane.normals[i], 0);
        expect(plane.normals[i + 1], 0);
        expect(plane.normals[i + 2], 1);
      }
    });

    test('all vertices lie flat on Z=0', () {
      final plane = Fiber3DPlane();

      for (var i = 0; i < plane.positions.length; i += 3) {
        expect(plane.positions[i + 2], 0);
      }
    });

    test('vertices are bounded by ±width/2 and ±height/2', () {
      final plane = Fiber3DPlane(width: 2, height: 4);

      for (var i = 0; i < plane.positions.length; i += 3) {
        expect(plane.positions[i].abs() <= 1.0 + 1e-9, isTrue);
        expect(plane.positions[i + 1].abs() <= 2.0 + 1e-9, isTrue);
      }
    });

    test('segmented plane produces correct vertex and index counts', () {
      final plane = Fiber3DPlane(widthSegments: 4, heightSegments: 3);

      expect(plane.positions.length, (5 * 4) * 3);
      expect(plane.indices.length, (4 * 3) * 6);
    });
  });
}