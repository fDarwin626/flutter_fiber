import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_fiber/src/material/shader_chunk/fiber3d_common.dart';
import 'package:flutter_fiber/src/material/shader_chunk/fiber3d_lights_pars_begin.dart';

void main() {
  group('fiber3dLightsParsBegin', () {
    test('declares the ambient and shadow uniforms', () {
      expect(fiber3dLightsParsBegin, contains('uniform bool receiveShadow;'));
      expect(fiber3dLightsParsBegin, contains('uniform vec3 ambientLightColor;'));
    });

    test('defines the shared irradiance and attenuation functions', () {
      for (final signature in [
        'vec3 shGetIrradianceAt( in vec3 normal, in vec3 shCoefficients[ 9 ] )',
        'vec3 getLightProbeIrradiance( const in vec3 lightProbe[ 9 ], const in vec3 normal )',
        'vec3 getAmbientLightIrradiance( const in vec3 ambientLightColor )',
        'float getDistanceAttenuation( const in float lightDistance, const in float cutoffDistance, const in float decayExponent )',
        'float getSpotAttenuation( const in float coneCosine, const in float penumbraCosine, const in float angleCosine )',
      ]) {
        expect(fiber3dLightsParsBegin, contains(signature));
      }
    });

    test('ambient irradiance is the light color, with no 1/pi', () {
      expect(
        fiber3dLightsParsBegin,
        contains('vec3 irradiance = ambientLightColor;'),
      );
      expect(fiber3dLightsParsBegin, isNot(contains('RECIPROCAL_PI')));
    });

    test('distance attenuation follows Frostbite 3', () {
      expect(
        fiber3dLightsParsBegin,
        contains('1.0 / max( pow( lightDistance, decayExponent ), 0.01 )'),
      );
      expect(
        fiber3dLightsParsBegin,
        contains('pow2( saturate( 1.0 - pow4( lightDistance / cutoffDistance ) ) )'),
      );
    });

    test('keeps the spherical-harmonics coefficients', () {
      for (final c in ['0.886227', '0.511664', '0.429043', '0.743125', '0.247708']) {
        expect(fiber3dLightsParsBegin, contains(c));
      }
    });

    test('each light type is guarded by its NUM_*_LIGHTS count', () {
      for (final name in [
        'SUN',
        'DIR',
        'POINT',
        'SPOT',
        'RECT_AREA',
        'HEMI',
      ]) {
        expect(fiber3dLightsParsBegin, contains('#if NUM_${name}_LIGHTS > 0'));
      }
    });

    test('declares each light uniform array with its count', () {
      for (final decl in [
        'uniform SunLight sunLights[ NUM_SUN_LIGHTS ];',
        'uniform DirectionalLight directionalLights[ NUM_DIR_LIGHTS ];',
        'uniform PointLight pointLights[ NUM_POINT_LIGHTS ];',
        'uniform SpotLight spotLights[ NUM_SPOT_LIGHTS ];',
        'uniform RectAreaLight rectAreaLights[ NUM_RECT_AREA_LIGHTS ];',
        'uniform HemisphereLight hemisphereLights[ NUM_HEMI_LIGHTS ];',
      ]) {
        expect(fiber3dLightsParsBegin, contains(decl));
      }
    });

    test('the point light struct and getter match what the canvas will upload', () {
      expect(fiber3dLightsParsBegin, contains('struct PointLight {'));
      for (final field in [
        'vec3 position;',
        'vec3 color;',
        'float distance;',
        'float decay;',
      ]) {
        expect(fiber3dLightsParsBegin, contains(field));
      }
      expect(
        fiber3dLightsParsBegin,
        contains(
          'void getPointLightInfo( const in PointLight pointLight, const in vec3 geometryPosition, out IncidentLight light )',
        ),
      );
    });

    test('the hemisphere irradiance blends ground to sky by dot(N, L)', () {
      expect(
        fiber3dLightsParsBegin,
        contains('float hemiDiffuseWeight = 0.5 * dotNL + 0.5;'),
      );
      expect(
        fiber3dLightsParsBegin,
        contains('mix( hemiLight.groundColor, hemiLight.skyColor, hemiDiffuseWeight )'),
      );
    });

    test('preprocessor conditionals are balanced', () {
      final opens = RegExp(r'^\s*#if', multiLine: true)
          .allMatches(fiber3dLightsParsBegin)
          .length;
      final closes = RegExp(r'^\s*#endif', multiLine: true)
          .allMatches(fiber3dLightsParsBegin)
          .length;

      expect(opens, 7);
      expect(closes, opens);
    });

    test('has no #include left to resolve', () {
      expect(fiber3dLightsParsBegin, isNot(contains('#include')));
    });

    test('everything it relies on is defined by the common chunk', () {
      expect(fiber3dCommon, contains('struct IncidentLight {'));
      expect(fiber3dCommon, contains('float pow2( const in float x )'));
      expect(fiber3dCommon, contains('float pow4( const in float x )'));
      expect(fiber3dCommon, contains('#define saturate( a )'));
      expect(
        fiber3dCommon,
        contains('vec3 transformNormalByInverseViewMatrix( in vec3 normal, in mat4 viewMatrix )'),
      );
    });
  });
}