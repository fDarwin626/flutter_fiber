import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_fiber/src/material/fiber3d_checkerboard_sky.dart';

void main() {
  group('Fiber3DCheckerboardSky', () {
    test('output is always exactly lightColor or darkColor', () {
      const sky = Fiber3DCheckerboardSky();
      final out = List<double>.filled(3, 0);
      final dirs = [
        [1.0, 0.0, 0.0],
        [0.0, 1.0, 0.0],
        [0.0, -1.0, 0.0],
        [0.0, 0.0, 1.0],
        [0.7071, 0.0, 0.7071],
        [0.3, 0.9, 0.1],
      ];
      for (final d in dirs) {
        sky.radiance(d[0], d[1], d[2], out);
        final matchesLight = out[0] == sky.lightColor[0] &&
            out[1] == sky.lightColor[1] &&
            out[2] == sky.lightColor[2];
        final matchesDark = out[0] == sky.darkColor[0] &&
            out[1] == sky.darkColor[1] &&
            out[2] == sky.darkColor[2];
        expect(matchesLight || matchesDark, isTrue);
      }
    });

    test('adjacent checker cells differ (pattern actually alternates)', () {
      const sky = Fiber3DCheckerboardSky(columns: 4, rows: 2);
      final a = List<double>.filled(3, 0);
      final b = List<double>.filled(3, 0);

      // Two points at the same latitude, one checker-cell apart in
      // longitude (2*pi / columns radians).
      sky.radiance(1.0, 0.0, 0.0, a); // longitude 0
      sky.radiance(0.0, 0.0, 1.0, b); // longitude pi/2 = one cell over
      expect(a[0] == b[0], isFalse);
    });

    test('is deterministic for the same direction', () {
      const sky = Fiber3DCheckerboardSky();
      final a = List<double>.filled(3, 0);
      final b = List<double>.filled(3, 0);
      sky.radiance(0.5, 0.5, 0.7071, a);
      sky.radiance(0.5, 0.5, 0.7071, b);
      expect(a, b);
    });

    test('respects custom light/dark colors', () {
      const sky = Fiber3DCheckerboardSky(
        lightColor: [2.0, 0.0, 0.0],
        darkColor: [0.0, 0.0, 3.0],
      );
      final out = List<double>.filled(3, 0);
      sky.radiance(1.0, 0.0, 0.0, out);
      final isRed = out[0] == 2.0 && out[2] == 0.0;
      final isBlue = out[0] == 0.0 && out[2] == 3.0;
      expect(isRed || isBlue, isTrue);
    });
  });
}