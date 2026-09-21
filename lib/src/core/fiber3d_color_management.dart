import 'dart:math';

/// Color spaces flutter_fiber understands.
///
/// three.js identifies these with string constants (`NoColorSpace`,
/// `SRGBColorSpace`, `LinearSRGBColorSpace`); an enum is the Dart
/// equivalent since only these names are ever compared.
enum Fiber3DColorSpace { none, srgb, linearSrgb }

/// Transfer function of a color space.
enum Fiber3DColorTransfer { linear, srgb }

/// sRGB <-> linear conversion, so colors are lit in linear space and
/// encoded back to sRGB for display.
///
/// Ported from three.js's `ColorManagement` (src/math/ColorManagement.js).
/// Scoped to sRGB and linear sRGB, which share Rec.709 primaries, so the
/// source's XYZ gamut-conversion branch (Matrix3) can never trigger and
/// is dropped, along with the color-space registry, tone-mapping-mode,
/// luminance-coefficient, drawing-buffer and unpack color space lookups.
class Fiber3DColorManagement {
  Fiber3DColorManagement._();

  /// When false, [convert] returns colors untouched (three.js
  /// `ColorManagement.enabled`).
  static bool enabled = true;

  /// Colors are stored and lit in linear sRGB.
  static const Fiber3DColorSpace workingColorSpace =
      Fiber3DColorSpace.linearSrgb;

  /// Converts [rgb] (three components, modified in place and returned)
  /// from [source] to [target].
  static List<double> convert(
    List<double> rgb,
    Fiber3DColorSpace source,
    Fiber3DColorSpace target,
  ) {
    if (!enabled ||
        source == target ||
        source == Fiber3DColorSpace.none ||
        target == Fiber3DColorSpace.none) {
      return rgb;
    }

    if (getTransfer(source) == Fiber3DColorTransfer.srgb) {
      rgb[0] = srgbToLinear(rgb[0]);
      rgb[1] = srgbToLinear(rgb[1]);
      rgb[2] = srgbToLinear(rgb[2]);
    }

    if (getTransfer(target) == Fiber3DColorTransfer.srgb) {
      rgb[0] = linearToSrgb(rgb[0]);
      rgb[1] = linearToSrgb(rgb[1]);
      rgb[2] = linearToSrgb(rgb[2]);
    }

    return rgb;
  }

  static List<double> workingToColorSpace(
    List<double> rgb,
    Fiber3DColorSpace target,
  ) => convert(rgb, workingColorSpace, target);

  static List<double> colorSpaceToWorking(
    List<double> rgb,
    Fiber3DColorSpace source,
  ) => convert(rgb, source, workingColorSpace);


  static List<double> getLuminanceCoefficients([
    Fiber3DColorSpace colorSpace = workingColorSpace,
  ]) => const [0.2126, 0.7152, 0.0722];

  /// No color space is treated as linear, matching three.js.
  static Fiber3DColorTransfer getTransfer(Fiber3DColorSpace colorSpace) {
    return switch (colorSpace) {
      Fiber3DColorSpace.none ||
      Fiber3DColorSpace.linearSrgb => Fiber3DColorTransfer.linear,
      Fiber3DColorSpace.srgb => Fiber3DColorTransfer.srgb,
    };
  }

  static double srgbToLinear(double c) => (c < 0.04045)
      ? c * 0.0773993808
      : pow(c * 0.9478672986 + 0.0521327014, 2.4).toDouble();

  static double linearToSrgb(double c) => (c < 0.0031308)
      ? c * 12.92
      : 1.055 * pow(c, 0.41666).toDouble() - 0.055;
}