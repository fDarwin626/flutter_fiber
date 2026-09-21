import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_fiber/src/core/fiber3d_color.dart';
import 'package:flutter_fiber/src/core/fiber3d_color_management.dart';

void main() {
  group('Fiber3DColor', () {
    tearDown(() {
      Fiber3DColorManagement.enabled = true;
    });

    test('defaults to white', () {
      final c = Fiber3DColor();
      expect(c.r, 1);
      expect(c.g, 1);
      expect(c.b, 1);
    });

    test('fromHex keeps black and white unchanged', () {
      final black = Fiber3DColor.fromHex(0x000000);
      expect(black.r, closeTo(0, 1e-9));
      expect(black.g, closeTo(0, 1e-9));
      expect(black.b, closeTo(0, 1e-9));

      final white = Fiber3DColor.fromHex(0xFFFFFF);
      expect(white.r, closeTo(1, 1e-9));
      expect(white.g, closeTo(1, 1e-9));
      expect(white.b, closeTo(1, 1e-9));
    });

    test('setHex converts sRGB grey 0x808080 to linear 0.21586', () {
      final c = Fiber3DColor()..setHex(0x808080);
      expect(c.r, closeTo(0.21586, 1e-4));
      expect(c.g, closeTo(0.21586, 1e-4));
      expect(c.b, closeTo(0.21586, 1e-4));
    });

    test('setHex converts the reference-scene color 0xCC2952 to linear', () {
      final c = Fiber3DColor.fromHex(0xCC2952);
      expect(c.r, closeTo(0.6038, 1e-3));
      expect(c.g, closeTo(0.0222, 1e-3));
      expect(c.b, closeTo(0.0844, 1e-3));
    });

    test('setHex with linearSrgb applies no conversion', () {
      final c = Fiber3DColor()
        ..setHex(0x808080, colorSpace: Fiber3DColorSpace.linearSrgb);
      expect(c.r, closeTo(128 / 255, 1e-9));
    });

    test('setHex applies no conversion when color management is disabled', () {
      Fiber3DColorManagement.enabled = false;
      final c = Fiber3DColor.fromHex(0x808080);
      expect(c.r, closeTo(128 / 255, 1e-9));
    });

    test('setRGB assumes the working space by default (no conversion)', () {
      final c = Fiber3DColor()..setRGB(0.5, 0.25, 0.75);
      expect(c.r, 0.5);
      expect(c.g, 0.25);
      expect(c.b, 0.75);
    });

    test('setRGB converts when told the source is sRGB', () {
      final c = Fiber3DColor()
        ..setRGB(0.5, 0.5, 0.5, colorSpace: Fiber3DColorSpace.srgb);
      expect(c.r, closeTo(0.214041, 1e-4));
    });

    test('setScalar sets all components', () {
      final c = Fiber3DColor()..setScalar(0.3);
      expect(c.r, 0.3);
      expect(c.g, 0.3);
      expect(c.b, 0.3);
    });

    test('getHex round-trips setHex', () {
      for (final hex in [0x000000, 0xFFFFFF, 0xCC2952, 0x123456, 0x828282]) {
        expect(Fiber3DColor.fromHex(hex).getHex(), hex);
      }
    });

    test('getHex clamps out-of-range components', () {
      final c = Fiber3DColor()..setRGB(2, -1, 0);
      expect(c.getHex(), 0xFF0000);
    });

    test('getHexString pads to six lowercase digits', () {
      expect(Fiber3DColor.fromHex(0xCC2952).getHexString(), 'cc2952');
      expect(Fiber3DColor.fromHex(0x000001).getHexString(), '000001');
    });

    test('getRGB writes sRGB components into the target', () {
      final c = Fiber3DColor.fromHex(0x808080);
      final target = Fiber3DColor();
      final result = c.getRGB(target, colorSpace: Fiber3DColorSpace.srgb);

      expect(identical(result, target), isTrue);
      expect(target.r, closeTo(128 / 255, 1e-4));
    });

    test('getRGB defaults to the working space and leaves the source alone', () {
      final c = Fiber3DColor.fromHex(0x808080);
      final before = c.r;
      final target = Fiber3DColor();
      c.getRGB(target);

      expect(target.r, closeTo(before, 1e-9));
      expect(c.r, before);
    });

    test('clone is independent of the original', () {
      final a = Fiber3DColor(0.1, 0.2, 0.3);
      final b = a.clone();
      b.r = 0.9;

      expect(a.r, 0.1);
      expect(b.r, 0.9);
    });

    test('copy copies all components', () {
      final a = Fiber3DColor(0.1, 0.2, 0.3);
      final b = Fiber3DColor()..copy(a);

      expect(b.r, 0.1);
      expect(b.g, 0.2);
      expect(b.b, 0.3);
    });

    test('convertSRGBToLinear and convertLinearToSRGB round-trip', () {
      final c = Fiber3DColor(0.5, 0.25, 0.75);
      c.convertSRGBToLinear();
      expect(c.r, closeTo(0.214041, 1e-4));
      c.convertLinearToSRGB();

      expect(c.r, closeTo(0.5, 1e-4));
      expect(c.g, closeTo(0.25, 1e-4));
      expect(c.b, closeTo(0.75, 1e-4));
    });

    test('copySRGBToLinear ignores the enabled flag, as in three.js', () {
      Fiber3DColorManagement.enabled = false;
      final c = Fiber3DColor()..copySRGBToLinear(Fiber3DColor(0.5, 0.5, 0.5));
      expect(c.r, closeTo(0.214041, 1e-4));
    });

    test('copyLinearToSRGB brightens linear values', () {
      final c = Fiber3DColor()
        ..copyLinearToSRGB(Fiber3DColor(0.214041, 0.214041, 0.214041));
      expect(c.r, closeTo(0.5, 1e-4));
    });

    test('add, addColors and addScalar', () {
      final c = Fiber3DColor(0.1, 0.2, 0.3)..add(Fiber3DColor(0.1, 0.1, 0.1));
      expect(c.r, closeTo(0.2, 1e-9));
      expect(c.g, closeTo(0.3, 1e-9));
      expect(c.b, closeTo(0.4, 1e-9));

      final d = Fiber3DColor()
        ..addColors(Fiber3DColor(0.1, 0.2, 0.3), Fiber3DColor(0.4, 0.5, 0.6));
      expect(d.r, closeTo(0.5, 1e-9));
      expect(d.g, closeTo(0.7, 1e-9));
      expect(d.b, closeTo(0.9, 1e-9));

      final e = Fiber3DColor(0.1, 0.2, 0.3)..addScalar(0.1);
      expect(e.r, closeTo(0.2, 1e-9));
      expect(e.b, closeTo(0.4, 1e-9));
    });

    test('sub clamps each component at zero', () {
      final c = Fiber3DColor(0.5, 0.1, 0.3)..sub(Fiber3DColor(0.2, 0.4, 0.3));
      expect(c.r, closeTo(0.3, 1e-9));
      expect(c.g, 0);
      expect(c.b, closeTo(0, 1e-9));
    });

    test('multiply and multiplyScalar', () {
      final c = Fiber3DColor(0.5, 0.5, 0.5)
        ..multiply(Fiber3DColor(0.5, 1.0, 0.2));
      expect(c.r, closeTo(0.25, 1e-9));
      expect(c.g, closeTo(0.5, 1e-9));
      expect(c.b, closeTo(0.1, 1e-9));

      final d = Fiber3DColor(0.2, 0.4, 0.6)..multiplyScalar(2);
      expect(d.r, closeTo(0.4, 1e-9));
      expect(d.g, closeTo(0.8, 1e-9));
      expect(d.b, closeTo(1.2, 1e-9));
    });

    test('lerp and lerpColors interpolate', () {
      final c = Fiber3DColor(0, 0, 0)..lerp(Fiber3DColor(1, 0.5, 0.25), 0.5);
      expect(c.r, closeTo(0.5, 1e-9));
      expect(c.g, closeTo(0.25, 1e-9));
      expect(c.b, closeTo(0.125, 1e-9));

      final d = Fiber3DColor()
        ..lerpColors(Fiber3DColor(0, 0, 0), Fiber3DColor(1, 1, 1), 0.25);
      expect(d.r, closeTo(0.25, 1e-9));
    });

    test('equals compares components', () {
      expect(Fiber3DColor(0.1, 0.2, 0.3).equals(Fiber3DColor(0.1, 0.2, 0.3)), isTrue);
      expect(Fiber3DColor(0.1, 0.2, 0.3).equals(Fiber3DColor(0.1, 0.2, 0.4)), isFalse);
    });

    test('toArray and fromArray round-trip with an offset', () {
      final out = Fiber3DColor(0.1, 0.2, 0.3).toArray(offset: 2);
      expect(out, [0, 0, 0.1, 0.2, 0.3]);

      final c = Fiber3DColor()..fromArray(out, 2);
      expect(c.r, 0.1);
      expect(c.g, 0.2);
      expect(c.b, 0.3);
    });
  });
}