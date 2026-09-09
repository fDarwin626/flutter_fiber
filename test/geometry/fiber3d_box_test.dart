import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_fiber/src/geometry/fiber3d_box.dart';

void main() {
  group('Fiber3DBox', () {
    test('default 1x1x1 box has correct buffer sizes', () {
      final box = Fiber3DBox();

      expect(box.positions.length, 72); // 6 faces * 4 verts * 3 floats
      expect(box.normals.length, 72);
      expect(box.uvs.length, 48); // 6 faces * 4 verts * 2 floats
      expect(box.indices.length, 36); // 6 faces * 2 tris * 3 indices
    });

    test('+x face (first face built) has correct vertices and normal', () {
      final box = Fiber3DBox();

      final expectedPositions = [
        0.5, 0.5, 0.5,
        0.5, 0.5, -0.5,
        0.5, -0.5, 0.5,
        0.5, -0.5, -0.5,
      ];

      for (var i = 0; i < expectedPositions.length; i++) {
        expect(box.positions[i], closeTo(expectedPositions[i], 1e-9));
      }

      for (var i = 0; i < 4; i++) {
        expect(box.normals[i * 3], closeTo(1.0, 1e-9));
        expect(box.normals[i * 3 + 1], closeTo(0.0, 1e-9));
        expect(box.normals[i * 3 + 2], closeTo(0.0, 1e-9));
      }
    });

    test('every normal is a unit axis vector', () {
      final box = Fiber3DBox();

      for (var i = 0; i < box.normals.length; i += 3) {
        final nx = box.normals[i];
        final ny = box.normals[i + 1];
        final nz = box.normals[i + 2];
        expect(nx * nx + ny * ny + nz * nz, closeTo(1.0, 1e-9));
      }
    });

    test('all vertices lie on the unit cube surface (±0.5)', () {
      final box = Fiber3DBox();

      for (var i = 0; i < box.positions.length; i += 3) {
        expect(box.positions[i].abs() <= 0.5 + 1e-9, isTrue);
        expect(box.positions[i + 1].abs() <= 0.5 + 1e-9, isTrue);
        expect(box.positions[i + 2].abs() <= 0.5 + 1e-9, isTrue);
      }
    });
  });
}