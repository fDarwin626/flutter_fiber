import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_fiber/src/material/fiber3d_prefiltered_cube.dart';

void main() {
  group('Fiber3DPrefilteredCube', () {
    void whiteFurnace(double x, double y, double z, List<double> out) {
      out[0] = 1.0;
      out[1] = 1.0;
      out[2] = 1.0;
    }

    test('rejects non-power-of-two size', () {
      expect(
        () => Fiber3DPrefilteredCube.generate(whiteFurnace, size: 100),
        throwsArgumentError,
      );
    });

    test('rejects size below minSize', () {
      expect(
        () => Fiber3DPrefilteredCube.generate(whiteFurnace, size: 4),
        throwsArgumentError,
      );
    });

    test('maxLod matches log2(size) - lodMin', () {
      final cube = Fiber3DPrefilteredCube.generate(
        whiteFurnace,
        size: 128,
        samples: 8,
      );
      // log2(128) - 3 = 4
      expect(cube.maxLod, 4);
      expect(cube.faces.length, 5);
    });

    test('each level has 6 faces sized faceSize(lod)^2 * 4', () {
      final cube = Fiber3DPrefilteredCube.generate(
        whiteFurnace,
        size: 64,
        samples: 8,
      );
      for (var lod = 0; lod <= cube.maxLod; lod++) {
        final n = cube.faceSize(lod);
        expect(n, 64 >> lod);
        expect(cube.faces[lod].length, 6);
        for (final face in cube.faces[lod]) {
          expect(face.length, n * n * 4);
        }
      }
    });

    test('white furnace: every texel stays white regardless of roughness', () {
      final cube = Fiber3DPrefilteredCube.generate(
        whiteFurnace,
        size: 32,
        samples: 32,
      );
      for (var lod = 0; lod <= cube.maxLod; lod++) {
        for (final face in cube.faces[lod]) {
          for (var i = 0; i < face.length; i += 4) {
            expect(face[i], closeTo(1.0, 1e-6));
            expect(face[i + 1], closeTo(1.0, 1e-6));
            expect(face[i + 2], closeTo(1.0, 1e-6));
            expect(face[i + 3], 1.0);
          }
        }
      }
    });

    test('lod 0 is unfiltered: matches radiance() directly', () {
      void colorByFace(double x, double y, double z, List<double> out) {
        out[0] = x.abs();
        out[1] = y.abs();
        out[2] = z.abs();
      }

      final cube = Fiber3DPrefilteredCube.generate(
        colorByFace,
        size: 16,
        samples: 8,
      );
      final n = cube.faceSize(0);
      final dir = List<double>.filled(3, 0);
      final expected = List<double>.filled(3, 0);

      for (var face = 0; face < 6; face++) {
        final data = cube.faces[0][face];
        // Sample a handful of texels rather than every one.
        for (final j in [0, n ~/ 2, n - 1]) {
          for (final i in [0, n ~/ 2, n - 1]) {
            final a = 2.0 * (i + 0.5) / n - 1.0;
            final b = 2.0 * (j + 0.5) / n - 1.0;
            Fiber3DPrefilteredCube.faceDirection(face, a, b, dir);
            colorByFace(dir[0], dir[1], dir[2], expected);

            final o = (j * n + i) * 4;
            expect(data[o], closeTo(expected[0], 1e-6));
            expect(data[o + 1], closeTo(expected[1], 1e-6));
            expect(data[o + 2], closeTo(expected[2], 1e-6));
          }
        }
      }
    });

    test('lodToRoughness / roughnessToMip are inverses at sampled lods', () {
      const maxLod = 4;
      for (var lod = 0; lod <= maxLod; lod++) {
        final r = Fiber3DPrefilteredCube.lodToRoughness(lod, maxLod);
        final back = Fiber3DPrefilteredCube.roughnessToMip(r, maxLod);
        expect(back, closeTo(lod.toDouble(), 1e-6));
      }
    });

    test('lodToRoughness is 0 at lod 0 and 1 at maxLod', () {
      expect(Fiber3DPrefilteredCube.lodToRoughness(0, 4), closeTo(0.0, 1e-9));
      expect(Fiber3DPrefilteredCube.lodToRoughness(4, 4), closeTo(1.0, 1e-9));
    });

    test('faceDirection returns unit vectors covering all 6 axes at center', () {
      final dir = List<double>.filled(3, 0);
      final expectedCenters = [
        [1.0, 0.0, 0.0],
        [-1.0, 0.0, 0.0],
        [0.0, 1.0, 0.0],
        [0.0, -1.0, 0.0],
        [0.0, 0.0, 1.0],
        [0.0, 0.0, -1.0],
      ];
      for (var face = 0; face < 6; face++) {
        Fiber3DPrefilteredCube.faceDirection(face, 0, 0, dir);
        final len = dir[0] * dir[0] + dir[1] * dir[1] + dir[2] * dir[2];
        expect(len, closeTo(1.0, 1e-9));
        expect(dir[0], closeTo(expectedCenters[face][0], 1e-9));
        expect(dir[1], closeTo(expectedCenters[face][1], 1e-9));
        expect(dir[2], closeTo(expectedCenters[face][2], 1e-9));
      }
    });
  });
}