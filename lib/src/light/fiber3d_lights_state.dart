import '../core/fiber3d_matrix4.dart';

/// One point light's GPU ready uniform values, already transformed and
/// scaled the way the shader expects: view-space position, and color
/// pre-multiplied by intensity.
class Fiber3DPointLightUniforms {
  final double x;
  final double y;
  final double z;
  final double r;
  final double g;
  final double b;
  final double distance;
  final double decay;

  const Fiber3DPointLightUniforms({
    required this.x,
    required this.y,
    required this.z,
    required this.r,
    required this.g,
    required this.b,
    required this.distance,
    required this.decay,
  });
}

class Fiber3DLightsState {
  Fiber3DLightsState._();

  static List<double> sumAmbient({
    required List<List<double>> colorsLinear,
    required List<double> intensities,
  }) {
    var r = 0.0, g = 0.0, b = 0.0;
    for (var i = 0; i < colorsLinear.length; i++) {
      final c = colorsLinear[i];
      final intensity = intensities[i];
      r += c[0] * intensity;
      g += c[1] * intensity;
      b += c[2] * intensity;
    }
    return [r, g, b];
  }

  /// Builds one point light's shader uniforms: [x], [y], [z] (world-space
  /// position) transformed into view space via [viewMatrix] (three.js's
  /// `uniforms.position.applyMatrix4(viewMatrix)` in `setupView`), and
  /// [colorLinear] multiplied by [intensity] (three.js's
  /// `uniforms.color.copy(color).multiplyScalar(intensity)` in `setup`).
  static Fiber3DPointLightUniforms pointLightUniforms({
    required double x,
    required double y,
    required double z,
    required List<double> colorLinear,
    required double intensity,
    required double distance,
    required double decay,
    required Fiber3DMatrix4 viewMatrix,
  }) {
    final viewPos = viewMatrix.transformPoint(x, y, z);
    return Fiber3DPointLightUniforms(
      x: viewPos[0],
      y: viewPos[1],
      z: viewPos[2],
      r: colorLinear[0] * intensity,
      g: colorLinear[1] * intensity,
      b: colorLinear[2] * intensity,
      distance: distance,
      decay: decay,
    );
  }
}