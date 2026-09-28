import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_fiber/src/material/fiber3d_procedural_sky.dart';

void main() {
  group('Fiber3DProceduralSky', () {
    test('zenith matches skyColor', () {
      final sky = Fiber3DProceduralSky(sunDirection: null);
      final out = List<double>.filled(3, 0);
      sky.radiance(0, 1, 0, out);
      expect(out[0], closeTo(sky.skyColor[0], 1e-6));
      expect(out[1], closeTo(sky.skyColor[1], 1e-6));
      expect(out[2], closeTo(sky.skyColor[2], 1e-6));
    });

    test('nadir matches groundColor', () {
      final sky = Fiber3DProceduralSky(sunDirection: null);
      final out = List<double>.filled(3, 0);
      sky.radiance(0, -1, 0, out);
      expect(out[0], closeTo(sky.groundColor[0], 1e-6));
      expect(out[1], closeTo(sky.groundColor[1], 1e-6));
      expect(out[2], closeTo(sky.groundColor[2], 1e-6));
    });

    test('horizon matches horizonColor', () {
      final sky = Fiber3DProceduralSky(sunDirection: null);
      final out = List<double>.filled(3, 0);
      sky.radiance(1, 0, 0, out);
      expect(out[0], closeTo(sky.horizonColor[0], 1e-6));
      expect(out[1], closeTo(sky.horizonColor[1], 1e-6));
      expect(out[2], closeTo(sky.horizonColor[2], 1e-6));
    });

    test('sun disc adds sunColor only within the disc angle', () {
      final sky = Fiber3DProceduralSky(
        sunDirection: [0, 1, 0],
        sunCosAngle: 0.999,
      );
      final inDisc = List<double>.filled(3, 0);
      final outDisc = List<double>.filled(3, 0);
      sky.radiance(0, 1, 0, inDisc); // looking straight at the sun
      sky.radiance(1, 0, 0, outDisc); // horizon, well outside the disc

      expect(inDisc[0], greaterThan(sky.skyColor[0]));
      expect(outDisc[0], closeTo(sky.horizonColor[0], 1e-6));
    });

    test('no sun disc when sunDirection is null', () {
      final sky = Fiber3DProceduralSky(sunDirection: null);
      final out = List<double>.filled(3, 0);
      sky.radiance(0, 1, 0, out);
      expect(out[0], closeTo(sky.skyColor[0], 1e-6));
    });
  });
}