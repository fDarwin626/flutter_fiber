import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_fiber/src/material/fiber3d_pbr_shader.dart';

void main() {
  group('Fiber3DPbrShader', () {
    test('vertex shader includes the requested version and key uniforms', () {
      final src = Fiber3DPbrShader.vertex('300 es');
      expect(src.contains('#version 300 es'), isTrue);
      expect(src.contains('u_ModelMatrix'), isTrue);
      expect(src.contains('u_ViewMatrix'), isTrue);
      expect(src.contains('u_ProjectionMatrix'), isTrue);
    });

    test('fragment shader includes the GGX BRDF functions', () {
      final src = Fiber3DPbrShader.fragment('300 es');
      expect(src.contains('D_GGX'), isTrue);
      expect(src.contains('V_GGX_SmithCorrelated'), isTrue);
      expect(src.contains('F_Schlick'), isTrue);
      expect(src.contains('getDistanceAttenuation'), isTrue);
    });

    test('desktop version (150) is respected', () {
      final src = Fiber3DPbrShader.fragment('150');
      expect(src.contains('#version 150'), isTrue);
    });

    test('point light array size matches maxPointLights', () {
      final src = Fiber3DPbrShader.fragment('300 es');
      expect(src.contains('u_PointLightPosition[4]'), isTrue);
    });
  });
}