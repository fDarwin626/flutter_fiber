import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_fiber/src/material/shader_chunk/fiber3d_common.dart';
import 'package:flutter_fiber/src/material/shader_chunk/fiber3d_lights_lambert_pars_fragment.dart';

void main() {
  const chunk = fiber3dLightsLambertParsFragment;

  group('fiber3dLightsLambertParsFragment', () {
    test('declares vViewPosition', () {
      expect(chunk, contains('varying vec3 vViewPosition;'));
    });

    test('defines LambertMaterial with diffuseColor and specularStrength', () {
      expect(chunk, contains('struct LambertMaterial {'));
      expect(chunk, contains('vec3 diffuseColor;'));
      expect(chunk, contains('float specularStrength;'));
    });

    test('has no specular term at all — direct light is pure Lambert', () {
      expect(
        chunk,
        contains(
          'void RE_Direct_Lambert( const in IncidentLight directLight, const in vec3 geometryPosition, const in vec3 geometryNormal, const in vec3 geometryViewDir, const in vec3 geometryClearcoatNormal, const in LambertMaterial material, inout ReflectedLight reflectedLight )',
        ),
      );
      expect(
        chunk,
        contains(
          'reflectedLight.directDiffuse += irradiance * BRDF_Lambert( material.diffuseColor );',
        ),
      );
      expect(chunk, isNot(contains('reflectedLight.directSpecular')));
    });

    test('indirect diffuse also goes straight through BRDF_Lambert', () {
      expect(
        chunk,
        contains(
          'void RE_IndirectDiffuse_Lambert( const in vec3 irradiance, const in vec3 geometryPosition, const in vec3 geometryNormal, const in vec3 geometryViewDir, const in vec3 geometryClearcoatNormal, const in LambertMaterial material, inout ReflectedLight reflectedLight )',
        ),
      );
      expect(
        chunk,
        contains(
          'reflectedLight.indirectDiffuse += irradiance * BRDF_Lambert( material.diffuseColor );',
        ),
      );
    });

    test('aliases the RE_* names to the Lambert versions', () {
      expect(chunk, matches(RegExp(r'#define RE_Direct\s+RE_Direct_Lambert')));
      expect(
        chunk,
        matches(RegExp(r'#define RE_IndirectDiffuse\s+RE_IndirectDiffuse_Lambert')),
      );
    });

    test('has no preprocessor conditionals to balance', () {
      // Unlike Physical, Lambert has no #ifdef-guarded feature fields —
      // the struct is unconditional, so this chunk has zero #if/#endif.
      final opens = RegExp(r'^\s*#if', multiLine: true).allMatches(chunk).length;
      final closes = RegExp(r'^\s*#endif', multiLine: true).allMatches(chunk).length;

      expect(opens, 0);
      expect(closes, 0);
    });

    test('is plain ASCII', () {
      expect(chunk.codeUnits.every((c) => c < 128), isTrue);
    });

    test('has no #include left to resolve', () {
      expect(chunk, isNot(contains('#include')));
    });

    test('BRDF_Lambert is defined by an earlier chunk', () {
      expect(
        fiber3dCommon,
        contains('vec3 BRDF_Lambert( const in vec3 diffuseColor )'),
      );
    });
  });
}