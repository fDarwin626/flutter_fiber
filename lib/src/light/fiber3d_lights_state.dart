import 'dart:math' as math;

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

/// One hemisphere light's GPU-ready uniform values: view-space direction
/// and the sky/ground colors, each pre-multiplied by intensity (matching
/// pointLightUniforms's own color*intensity convention the dormant
/// getHemisphereLightIrradiance shader chunk has no intensity term of
/// its own, so it's baked into the color here instead).
class Fiber3DHemisphereLightUniforms {
  final double dirX;
  final double dirY;
  final double dirZ;
  final double skyR;
  final double skyG;
  final double skyB;
  final double groundR;
  final double groundG;
  final double groundB;

  const Fiber3DHemisphereLightUniforms({
    required this.dirX,
    required this.dirY,
    required this.dirZ,
    required this.skyR,
    required this.skyG,
    required this.skyB,
    required this.groundR,
    required this.groundG,
    required this.groundB,
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

  /// Builds one hemisphere light's shader uniforms. [x], [y], [z] is the
  /// world-space direction, rotated into view space by [viewMatrix]'s
  /// upper-left 3x3 only (a direction has no position, so unlike
  /// pointLightUniforms's full transformPoint, translation must not be
  /// applied), then re-normalized in case the input wasn't unit length.
  /// [viewMatrix.elements] is column-major (matches every other use of
  /// it in this codebase): elements[0..2] is column 0, [4..6] column 1,
  /// [8..10] column 2.
  static Fiber3DHemisphereLightUniforms hemisphereLightUniforms({
    required double x,
    required double y,
    required double z,
    required List<double> skyColorLinear,
    required List<double> groundColorLinear,
    required double intensity,
    required Fiber3DMatrix4 viewMatrix,
  }) {
    final e = viewMatrix.elements;
    var vx = e[0] * x + e[4] * y + e[8] * z;
    var vy = e[1] * x + e[5] * y + e[9] * z;
    var vz = e[2] * x + e[6] * y + e[10] * z;

    final len = math.sqrt(vx * vx + vy * vy + vz * vz);
    if (len > 0) {
      vx /= len;
      vy /= len;
      vz /= len;
    }

    return Fiber3DHemisphereLightUniforms(
      dirX: vx,
      dirY: vy,
      dirZ: vz,
      skyR: skyColorLinear[0] * intensity,
      skyG: skyColorLinear[1] * intensity,
      skyB: skyColorLinear[2] * intensity,
      groundR: groundColorLinear[0] * intensity,
      groundG: groundColorLinear[1] * intensity,
      groundB: groundColorLinear[2] * intensity,
    );
  }
}