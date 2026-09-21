import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_fiber/src/core/fiber3d_color_management.dart';

void main() {
  group('Fiber3DColorManagement', () {
    tearDown(() {
      Fiber3DColorManagement.enabled = true;
    });

    test('srgbToLinear keeps the endpoints', () {
      expect(Fiber3DColorManagement.srgbToLinear(0), closeTo(0, 1e-9));
      expect(Fiber3DColorManagement.srgbToLinear(1), closeTo(1, 1e-9));
    });

    test('srgbToLinear uses the linear segment below 0.04045', () {
      expect(
        Fiber3DColorManagement.srgbToLinear(0.04),
        closeTo(0.04 * 0.0773993808, 1e-9),
      );
    });

    test('srgbToLinear maps mid-grey 0.5 to about 0.2140', () {
      expect(Fiber3DColorManagement.srgbToLinear(0.5), closeTo(0.214041, 1e-4));
    });

    test('linearToSrgb uses the linear segment below 0.0031308', () {
      expect(
        Fiber3DColorManagement.linearToSrgb(0.003),
        closeTo(0.003 * 12.92, 1e-9),
      );
    });

    test('linearToSrgb round-trips srgbToLinear', () {
      for (final c in [0.0, 0.1, 0.25, 0.5, 0.75, 1.0]) {
        final linear = Fiber3DColorManagement.srgbToLinear(c);
        expect(Fiber3DColorManagement.linearToSrgb(linear), closeTo(c, 1e-4));
      }
    });

    test('getLuminanceCoefficients returns the Rec.709 weights', () {
      final w = Fiber3DColorManagement.getLuminanceCoefficients();
      expect(w[0], closeTo(0.2126, 1e-9));
      expect(w[1], closeTo(0.7152, 1e-9));
      expect(w[2], closeTo(0.0722, 1e-9));
      expect(w[0] + w[1] + w[2], closeTo(1.0, 1e-9));
    });

    test('getTransfer treats none and linearSrgb as linear', () {
      expect(
        Fiber3DColorManagement.getTransfer(Fiber3DColorSpace.none),
        Fiber3DColorTransfer.linear,
      );
      expect(
        Fiber3DColorManagement.getTransfer(Fiber3DColorSpace.linearSrgb),
        Fiber3DColorTransfer.linear,
      );
      expect(
        Fiber3DColorManagement.getTransfer(Fiber3DColorSpace.srgb),
        Fiber3DColorTransfer.srgb,
      );
    });

    test('convert srgb to linear modifies in place and returns the same list',
        () {
      final rgb = [0.5, 0.5, 0.5];
      final result = Fiber3DColorManagement.convert(
        rgb,
        Fiber3DColorSpace.srgb,
        Fiber3DColorSpace.linearSrgb,
      );

      expect(identical(result, rgb), isTrue);
      expect(rgb[0], closeTo(0.214041, 1e-4));
      expect(rgb[1], closeTo(0.214041, 1e-4));
      expect(rgb[2], closeTo(0.214041, 1e-4));
    });

    test('workingToColorSpace brightens linear values into sRGB', () {
      final rgb = [0.214041, 0.214041, 0.214041];
      Fiber3DColorManagement.workingToColorSpace(rgb, Fiber3DColorSpace.srgb);

      expect(rgb[0], closeTo(0.5, 1e-4));
    });

    test('convert leaves colors alone for the same space', () {
      final rgb = [0.3, 0.6, 0.9];
      Fiber3DColorManagement.convert(
        rgb,
        Fiber3DColorSpace.srgb,
        Fiber3DColorSpace.srgb,
      );

      expect(rgb, [0.3, 0.6, 0.9]);
    });

    test('convert leaves colors alone when either space is none', () {
      final rgb = [0.3, 0.6, 0.9];
      Fiber3DColorManagement.convert(
        rgb,
        Fiber3DColorSpace.none,
        Fiber3DColorSpace.linearSrgb,
      );

      expect(rgb, [0.3, 0.6, 0.9]);
    });

    test('convert leaves colors alone when disabled', () {
      Fiber3DColorManagement.enabled = false;
      final rgb = [0.3, 0.6, 0.9];
      Fiber3DColorManagement.convert(
        rgb,
        Fiber3DColorSpace.srgb,
        Fiber3DColorSpace.linearSrgb,
      );

      expect(rgb, [0.3, 0.6, 0.9]);
    });
  });
}