import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_fiber/src/geometry/fiber3d_cylinder.dart';

void main() {
  group('Fiber3DCylinder', () {
    test('default capped cylinder has torso + 2 caps in buffers', () {
      final cyl = Fiber3DCylinder();

      // torso: (radialSegments+1) * (heightSegments+1) vertices
      // each cap: radialSegments (center dupes) + (radialSegments+1) (ring)
      final torsoVerts = (32 + 1) * (1 + 1);
      final capVerts = 32 + (32 + 1);
      final expectedVerts = torsoVerts + capVerts * 2;

      expect(cyl.positions.length, expectedVerts * 3);
      expect(cyl.normals.length, expectedVerts * 3);
      expect(cyl.uvs.length, expectedVerts * 2);
    });

    test('torso side vertices lie on the correct radius for their row', () {
      final cyl = Fiber3DCylinder(radiusTop: 1, radiusBottom: 1, height: 2);

      // With equal radii, every torso vertex should be at distance 1 from the Y axis.
      final torsoVertexCount = (32 + 1) * (1 + 1);
      for (var i = 0; i < torsoVertexCount; i++) {
        final x = cyl.positions[i * 3];
        final z = cyl.positions[i * 3 + 2];
        final r = sqrt(x * x + z * z);
        expect(r, closeTo(1.0, 1e-6));
      }
    });

    test('cone (radiusTop=0) has no degenerate top-cap and a valid apex', () {
      final cone = Fiber3DCylinder(radiusTop: 0, radiusBottom: 1, height: 2, heightSegments: 1);

      // Top row of torso should collapse to the apex (0, halfHeight, 0).
      for (var x = 0; x <= 32; x++) {
        final idx = x; // top row is written first, y=0
        expect(cone.positions[idx * 3], closeTo(0.0, 1e-9));
        expect(cone.positions[idx * 3 + 1], closeTo(1.0, 1e-9)); // halfHeight = 1
        expect(cone.positions[idx * 3 + 2], closeTo(0.0, 1e-9));
      }

      // No top cap generated since radiusTop == 0.
      // Total verts = torso + bottom cap only.
      final torsoVerts = (32 + 1) * (1 + 1);
      final capVerts = 32 + (32 + 1);
      expect(cone.positions.length, (torsoVerts + capVerts) * 3);
    });

    test('openEnded skips both caps entirely', () {
      final tube = Fiber3DCylinder(openEnded: true);
      final torsoVerts = (32 + 1) * (1 + 1);

      expect(tube.positions.length, torsoVerts * 3);
    });

    test('every normal is a unit vector', () {
      final cyl = Fiber3DCylinder();

      for (var i = 0; i < cyl.normals.length; i += 3) {
        final nx = cyl.normals[i];
        final ny = cyl.normals[i + 1];
        final nz = cyl.normals[i + 2];
        final len = nx * nx + ny * ny + nz * nz;
        expect(len, closeTo(1.0, 1e-6));
      }
    });
  });
}