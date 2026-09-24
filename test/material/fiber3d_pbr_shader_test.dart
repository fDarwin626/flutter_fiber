import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_fiber/src/material/fiber3d_pbr_shader.dart';

void main() {
  group('Fiber3DPbrShader', () {
    test('vertex shader includes the requested version and real uniform names', () {
      final src = Fiber3DPbrShader.vertex('300 es');
      expect(src, contains('#version 300 es'));
      expect(src, contains('uniform mat4 modelViewMatrix;'));
      expect(src, contains('uniform mat4 projectionMatrix;'));
      expect(src, contains('uniform mat3 normalMatrix;'));
    });

    test('fragment shader includes the ported GGX/Fresnel/attenuation functions', () {
      final src = Fiber3DPbrShader.fragment('300 es');
      expect(
        src,
        contains(
          'float D_GGX( const in float alpha, const in float dotNH ) {',
        ),
      );
      expect(
        src,
        contains(
          'float V_GGX_SmithCorrelated( const in float alpha, const in float dotNL, const in float dotNV ) {',
        ),
      );
      expect(
        src,
        contains(
          'vec3 F_Schlick( const in vec3 f0, const in float f90, const in float dotVH ) {',
        ),
      );
      expect(
        src,
        contains(
          'float getDistanceAttenuation( const in float lightDistance, const in float cutoffDistance, const in float decayExponent ) {',
        ),
      );
    });

    test('desktop version (150) is respected', () {
      final src = Fiber3DPbrShader.fragment('150');
      expect(src.startsWith('#version 150'), isTrue);
    });

    test('point light array size reflects maxPointLights after NUM_POINT_LIGHTS substitution', () {
      final src = Fiber3DPbrShader.fragment('300 es');
      expect(src, contains('uniform PointLight pointLights[ 4 ];'));
      expect(src, isNot(contains('NUM_POINT_LIGHTS')));
    });

    test('all #include directives are resolved', () {
      final src = Fiber3DPbrShader.fragment('300 es');
      expect(src, isNot(contains('#include')));
    });
  });
}