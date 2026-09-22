import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_fiber/src/core/fiber3d_matrix4.dart';
import 'package:flutter_fiber/src/light/fiber3d_lights_state.dart';

Fiber3DMatrix4 _translation(double x, double y, double z) {
  final m = Fiber3DMatrix4();
  m.setPosition(x, y, z);
  return m;
}

void main() {
  group('Fiber3DLightsState', () {
    test('sumAmbient adds a single light scaled by its intensity', () {
      final result = Fiber3DLightsState.sumAmbient(
        colorsLinear: [
          [1.0, 0.5, 0.25],
        ],
        intensities: [2.0],
      );

      expect(result, [closeTo(2.0, 1e-9), closeTo(1.0, 1e-9), closeTo(0.5, 1e-9)]);
    });

    test('sumAmbient sums contributions from multiple lights', () {
      final result = Fiber3DLightsState.sumAmbient(
        colorsLinear: [
          [0.2, 0.2, 0.2],
          [0.1, 0.3, 0.5],
        ],
        intensities: [1.0, 2.0],
      );

      expect(result[0], closeTo(0.4, 1e-9));
      expect(result[1], closeTo(0.8, 1e-9));
      expect(result[2], closeTo(1.2, 1e-9));
    });

    test('sumAmbient with no lights returns black', () {
      final result = Fiber3DLightsState.sumAmbient(
        colorsLinear: [],
        intensities: [],
      );

      expect(result, [0.0, 0.0, 0.0]);
    });

    test('pointLightUniforms leaves position unchanged under an identity view matrix', () {
      final uniforms = Fiber3DLightsState.pointLightUniforms(
        x: 3.0,
        y: 4.0,
        z: 5.0,
        colorLinear: [1.0, 1.0, 1.0],
        intensity: 1.0,
        distance: 0.0,
        decay: 2.0,
        viewMatrix: Fiber3DMatrix4(),
      );

      expect(uniforms.x, closeTo(3.0, 1e-9));
      expect(uniforms.y, closeTo(4.0, 1e-9));
      expect(uniforms.z, closeTo(5.0, 1e-9));
    });

    test('pointLightUniforms applies the view matrix translation', () {
      final uniforms = Fiber3DLightsState.pointLightUniforms(
        x: 3.0,
        y: 4.0,
        z: 5.0,
        colorLinear: [1.0, 1.0, 1.0],
        intensity: 1.0,
        distance: 0.0,
        decay: 2.0,
        viewMatrix: _translation(-1.0, -2.0, -3.0),
      );

      expect(uniforms.x, closeTo(2.0, 1e-9));
      expect(uniforms.y, closeTo(2.0, 1e-9));
      expect(uniforms.z, closeTo(2.0, 1e-9));
    });

    test('pointLightUniforms multiplies color by intensity', () {
      final uniforms = Fiber3DLightsState.pointLightUniforms(
        x: 0.0,
        y: 0.0,
        z: 0.0,
        colorLinear: [0.5, 0.25, 1.0],
        intensity: 3.0,
        distance: 10.0,
        decay: 2.0,
        viewMatrix: Fiber3DMatrix4(),
      );

      expect(uniforms.r, closeTo(1.5, 1e-9));
      expect(uniforms.g, closeTo(0.75, 1e-9));
      expect(uniforms.b, closeTo(3.0, 1e-9));
    });

    test('pointLightUniforms passes distance and decay through unchanged', () {
      final uniforms = Fiber3DLightsState.pointLightUniforms(
        x: 0.0,
        y: 0.0,
        z: 0.0,
        colorLinear: [1.0, 1.0, 1.0],
        intensity: 1.0,
        distance: 42.0,
        decay: 1.5,
        viewMatrix: Fiber3DMatrix4(),
      );

      expect(uniforms.distance, 42.0);
      expect(uniforms.decay, 1.5);
    });
  });
}