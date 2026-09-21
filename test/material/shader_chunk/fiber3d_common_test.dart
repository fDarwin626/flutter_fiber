import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_fiber/src/material/shader_chunk/fiber3d_common.dart';

// Reads the numeric value of `#define NAME value` from the chunk.
double _define(String name) {
  final match = RegExp('#define $name ([0-9.e-]+)').firstMatch(fiber3dCommon);
  return double.parse(match!.group(1)!);
}

void main() {
  group('fiber3dCommon', () {
    test('math constants match dart:math', () {
      expect(_define('PI'), closeTo(pi, 1e-15));
      expect(_define('PI2'), closeTo(2 * pi, 1e-15));
      expect(_define('PI_HALF'), closeTo(pi / 2, 1e-15));
      expect(_define('RECIPROCAL_PI'), closeTo(1 / pi, 1e-15));
      expect(_define('RECIPROCAL_PI2'), closeTo(1 / (2 * pi), 1e-15));
      expect(_define('EPSILON'), 1e-6);
    });

    test('defines the helper and transform functions', () {
      for (final signature in [
        'float pow2( const in float x )',
        'vec3 pow2( const in vec3 x )',
        'float pow3( const in float x )',
        'float pow4( const in float x )',
        'float max3( const in vec3 v )',
        'float average( const in vec3 v )',
        'highp float rand( const in vec2 uv )',
        'float precisionSafeLength( vec3 v )',
        'vec3 transformDirection( in vec3 dir, in mat4 matrix )',
        'vec3 transformNormalByInverseViewMatrix( in vec3 normal, in mat4 viewMatrix )',
        'vec3 transformDirectionByInverseViewMatrix( in vec3 dir, in mat4 viewMatrix )',
        'bool isPerspectiveMatrix( mat4 m )',
        'vec2 equirectUv( in vec3 dir )',
        'vec3 BRDF_Lambert( const in vec3 diffuseColor )',
        'vec3 F_Schlick( const in vec3 f0, const in float f90, const in float dotVH )',
        'float F_Schlick( const in float f0, const in float f90, const in float dotVH )',
      ]) {
        expect(fiber3dCommon, contains(signature));
      }
    });

    test('defines the light structs with their fields', () {
      expect(fiber3dCommon, contains('struct IncidentLight {'));
      expect(fiber3dCommon, contains('vec3 direction;'));
      expect(fiber3dCommon, contains('bool visible;'));
      expect(fiber3dCommon, contains('struct ReflectedLight {'));
      for (final field in [
        'vec3 directDiffuse;',
        'vec3 directSpecular;',
        'vec3 indirectDiffuse;',
        'vec3 indirectSpecular;',
      ]) {
        expect(fiber3dCommon, contains(field));
      }
    });

    test('saturate is only defined if the tone mapping chunk has not', () {
      expect(fiber3dCommon, contains('#ifndef saturate'));
    });

    test('BRDF_Lambert divides diffuse by pi', () {
      expect(fiber3dCommon, contains('return RECIPROCAL_PI * diffuseColor;'));
    });

    test('both F_Schlick overloads use the Epic exp2 approximation', () {
      const approximation = 'exp2( ( - 5.55473 * dotVH - 6.98316 ) * dotVH )';

      expect(approximation.allMatches(fiber3dCommon).length, 2);
    });

    test('the Schlick constants track pow(1 - x, 5)', () {
      final match = RegExp(
        r'exp2\( \( - ([0-9.]+) \* dotVH - ([0-9.]+) \) \* dotVH \)',
      ).firstMatch(fiber3dCommon)!;
      final a = double.parse(match.group(1)!);
      final b = double.parse(match.group(2)!);

      double approx(double x) => pow(2, (-a * x - b) * x).toDouble();

      for (final x in [0.0, 0.25, 0.5, 0.75, 1.0]) {
        expect(approx(x), closeTo(pow(1 - x, 5), 0.01));
      }
    });
  });
}