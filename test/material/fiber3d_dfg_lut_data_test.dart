import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_fiber/src/material/fiber3d_dfg_lut_data.dart';

void main() {
  group('halfToDouble', () {
    test('decodes zero', () {
      expect(halfToDouble(0x0000), 0.0);
    });

    test('decodes 1.0', () {
      expect(halfToDouble(0x3c00), closeTo(1.0, 1e-9));
    });

    test('decodes 2.0', () {
      expect(halfToDouble(0x4000), closeTo(2.0, 1e-9));
    });

    test('decodes 0.5', () {
      expect(halfToDouble(0x3800), closeTo(0.5, 1e-9));
    });

    test('decodes a negative value', () {
      expect(halfToDouble(0xbc00), closeTo(-1.0, 1e-9));
    });

    test('decodes the first LUT texel scale (0x30b5) to roughly 0.147', () {
      expect(halfToDouble(0x30b5), closeTo(0.14709, 1e-4));
    });
  });

  group('dfgLutData', () {
    test('has 512 entries (16 x 16 x 2)', () {
      expect(dfgLutData.length, 16 * 16 * 2);
      expect(dfgLutSize, 16);
    });

    test('every scale/bias pair sums to roughly 1 or less (energy conservation)', () {
      for (var i = 0; i < dfgLutData.length; i += 2) {
        final scale = dfgLutData[i];
        final bias = dfgLutData[i + 1];
        expect(scale + bias, lessThanOrEqualTo(1.05));
        expect(scale, greaterThanOrEqualTo(0.0));
        expect(bias, greaterThanOrEqualTo(0.0));
      }
    });

    test('decodes the last texel (row 15, col 15) correctly', () {
      final lastRowStart = 15 * 16 * 2;
      final finalScale = dfgLutData[lastRowStart + 15 * 2];
      final finalBias = dfgLutData[lastRowStart + 15 * 2 + 1];
      expect(finalScale, closeTo(0.3452, 1e-3));
      expect(finalBias, closeTo(halfToDouble(0x049f), 1e-9));
    });

    test('first-column scale values are all valid, finite, non-negative floats', () {
      for (var row = 0; row < dfgLutSize; row++) {
        final scale = dfgLutData[row * 16 * 2];
        expect(scale.isFinite, isTrue);
        expect(scale, greaterThanOrEqualTo(0.0));
      }
    });
  });
}