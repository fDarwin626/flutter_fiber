import 'dart:math';
import 'fiber3d_color_management.dart';

class Fiber3DColor {
  double r;
  double g;
  double b;

  static final List<double> _scratch = List<double>.filled(3, 0);

  /// Creates a color from linear components (default white). No
  /// conversion is applied, matching three.js's `setRGB` default.
  Fiber3DColor([this.r = 1, this.g = 1, this.b = 1]);

  /// Creates a color from a 0xRRGGBB int. [colorSpace] defaults to sRGB,
  /// so the value is converted into the linear working space.
  Fiber3DColor.fromHex(
    int hex, {
    Fiber3DColorSpace colorSpace = Fiber3DColorSpace.srgb,
  }) : r = 1,
       g = 1,
       b = 1 {
    setHex(hex, colorSpace: colorSpace);
  }

  Fiber3DColor setScalar(double scalar) {
    r = scalar;
    g = scalar;
    b = scalar;
    return this;
  }

  Fiber3DColor setHex(
    int hex, {
    Fiber3DColorSpace colorSpace = Fiber3DColorSpace.srgb,
  }) {
    r = ((hex >> 16) & 255) / 255;
    g = ((hex >> 8) & 255) / 255;
    b = (hex & 255) / 255;

    _toWorking(colorSpace);
    return this;
  }

  Fiber3DColor setRGB(
    double r,
    double g,
    double b, {
    Fiber3DColorSpace colorSpace = Fiber3DColorManagement.workingColorSpace,
  }) {
    this.r = r;
    this.g = g;
    this.b = b;

    _toWorking(colorSpace);
    return this;
  }

  Fiber3DColor clone() => Fiber3DColor(r, g, b);

  Fiber3DColor copy(Fiber3DColor color) {
    r = color.r;
    g = color.g;
    b = color.b;
    return this;
  }

  /// Copies [color] into this color, converting sRGB to linear. Unlike
  /// [setHex], this ignores [Fiber3DColorManagement.enabled], as in three.js.
  Fiber3DColor copySRGBToLinear(Fiber3DColor color) {
    r = Fiber3DColorManagement.srgbToLinear(color.r);
    g = Fiber3DColorManagement.srgbToLinear(color.g);
    b = Fiber3DColorManagement.srgbToLinear(color.b);
    return this;
  }

  /// Copies [color] into this color, converting linear to sRGB. Ignores
  /// [Fiber3DColorManagement.enabled], as in three.js.
  Fiber3DColor copyLinearToSRGB(Fiber3DColor color) {
    r = Fiber3DColorManagement.linearToSrgb(color.r);
    g = Fiber3DColorManagement.linearToSrgb(color.g);
    b = Fiber3DColorManagement.linearToSrgb(color.b);
    return this;
  }

  Fiber3DColor convertSRGBToLinear() => copySRGBToLinear(this);

  Fiber3DColor convertLinearToSRGB() => copyLinearToSRGB(this);

  /// Returns this color as a 0xRRGGBB int in [colorSpace] (default sRGB).
  int getHex({Fiber3DColorSpace colorSpace = Fiber3DColorSpace.srgb}) {
    final rgb = _inSpace(colorSpace);

    return (rgb[0] * 255).clamp(0.0, 255.0).round() * 65536 +
        (rgb[1] * 255).clamp(0.0, 255.0).round() * 256 +
        (rgb[2] * 255).clamp(0.0, 255.0).round();
  }

  /// Lowercase hex string without '#', for example 'cc2952'.
  String getHexString({
    Fiber3DColorSpace colorSpace = Fiber3DColorSpace.srgb,
  }) {
    return getHex(colorSpace: colorSpace).toRadixString(16).padLeft(6, '0');
  }

  /// Writes this color's components, converted into [colorSpace] (default
  /// the working space), into [target] and returns it.
  Fiber3DColor getRGB(
    Fiber3DColor target, {
    Fiber3DColorSpace colorSpace = Fiber3DColorManagement.workingColorSpace,
  }) {
    final rgb = _inSpace(colorSpace);
    target.r = rgb[0];
    target.g = rgb[1];
    target.b = rgb[2];
    return target;
  }

  Fiber3DColor add(Fiber3DColor color) {
    r += color.r;
    g += color.g;
    b += color.b;
    return this;
  }

  Fiber3DColor addColors(Fiber3DColor color1, Fiber3DColor color2) {
    r = color1.r + color2.r;
    g = color1.g + color2.g;
    b = color1.b + color2.b;
    return this;
  }

  Fiber3DColor addScalar(double s) {
    r += s;
    g += s;
    b += s;
    return this;
  }

  /// Subtracts [color], clamping each component at 0 (as three.js does).
  Fiber3DColor sub(Fiber3DColor color) {
    r = max(0.0, r - color.r);
    g = max(0.0, g - color.g);
    b = max(0.0, b - color.b);
    return this;
  }

  Fiber3DColor multiply(Fiber3DColor color) {
    r *= color.r;
    g *= color.g;
    b *= color.b;
    return this;
  }

  Fiber3DColor multiplyScalar(double s) {
    r *= s;
    g *= s;
    b *= s;
    return this;
  }

  Fiber3DColor lerp(Fiber3DColor color, double alpha) {
    r += (color.r - r) * alpha;
    g += (color.g - g) * alpha;
    b += (color.b - b) * alpha;
    return this;
  }

  Fiber3DColor lerpColors(Fiber3DColor color1, Fiber3DColor color2, double alpha) {
    r = color1.r + (color2.r - color1.r) * alpha;
    g = color1.g + (color2.g - color1.g) * alpha;
    b = color1.b + (color2.b - color1.b) * alpha;
    return this;
  }

  bool equals(Fiber3DColor c) => c.r == r && c.g == g && c.b == b;

  Fiber3DColor fromArray(List<double> array, [int offset = 0]) {
    r = array[offset];
    g = array[offset + 1];
    b = array[offset + 2];
    return this;
  }

  /// Writes r, g, b into [array] at [offset] (growing it if needed), or
  /// into a new list when [array] is null.
  List<double> toArray({List<double>? array, int offset = 0}) {
    final out = array ?? <double>[];
    while (out.length < offset + 3) {
      out.add(0);
    }
    out[offset] = r;
    out[offset + 1] = g;
    out[offset + 2] = b;
    return out;
  }

  // Converts this color's components from [source] into the working space,
  // in place.
  void _toWorking(Fiber3DColorSpace source) {
    _scratch[0] = r;
    _scratch[1] = g;
    _scratch[2] = b;
    Fiber3DColorManagement.colorSpaceToWorking(_scratch, source);
    r = _scratch[0];
    g = _scratch[1];
    b = _scratch[2];
  }

  // This color's components converted into [target]. Returns the shared
  // scratch list, so read it immediately.
  List<double> _inSpace(Fiber3DColorSpace target) {
    _scratch[0] = r;
    _scratch[1] = g;
    _scratch[2] = b;
    Fiber3DColorManagement.workingToColorSpace(_scratch, target);
    return _scratch;
  }
}