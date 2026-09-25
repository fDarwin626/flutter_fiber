import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_fiber/src/material/shader_chunk/fiber3d_common.dart';
import 'package:flutter_fiber/src/material/shader_chunk/fiber3d_gradientmap_pars_fragment.dart';
import 'package:flutter_fiber/src/material/shader_chunk/fiber3d_lights_toon_pars_fragment.dart';

void main() {
  const chunk = fiber3dLightsToonParsFragment;

  group('fiber3dLightsToonParsFragment', () {
    test('declares vViewPosition', () {
      expect(chunk, contains('varying vec3 vViewPosition;'));
    });

    test('defines ToonMaterial with diffuseColor only — no specular term at all', () {
      expect(chunk, contains('struct ToonMaterial {'));
      expect(chunk, contains('vec3 diffuseColor;'));
      expect(chunk, isNot(contains('specularColor')));
      expect(chunk, isNot(contains('shininess')));
    });

    test('direct light is stepped through getGradientIrradiance before '
        'the Lambert diffuse term is applied', () {
      expect(
        chunk,
        contains(
          'void RE_Direct_Toon( const in IncidentLight directLight, const in vec3 geometryPosition, const in vec3 geometryNormal, const in vec3 geometryViewDir, const in vec3 geometryClearcoatNormal, const in ToonMaterial material, inout ReflectedLight reflectedLight )',
        ),
      );
      expect(
        chunk,
        contains(
          'vec3 irradiance = getGradientIrradiance( geometryNormal, directLight.direction ) * directLight.color;',
        ),
      );
      expect(
        chunk,
        contains(
          'reflectedLight.directDiffuse += irradiance * BRDF_Lambert( material.diffuseColor );',
        ),
      );
    });

    test('indirect (ambient) light stays continuous/unstepped, same as Lambert/Phong', () {
      expect(
        chunk,
        contains(
          'void RE_IndirectDiffuse_Toon( const in vec3 irradiance, const in vec3 geometryPosition, const in vec3 geometryNormal, const in vec3 geometryViewDir, const in vec3 geometryClearcoatNormal, const in ToonMaterial material, inout ReflectedLight reflectedLight )',
        ),
      );
      expect(
        chunk,
        contains(
          'reflectedLight.indirectDiffuse += irradiance * BRDF_Lambert( material.diffuseColor );',
        ),
      );
    });

    test('aliases the RE_* names to the Toon versions', () {
      expect(chunk, matches(RegExp(r'#define RE_Direct\s+RE_Direct_Toon')));
      expect(
        chunk,
        matches(RegExp(r'#define RE_IndirectDiffuse\s+RE_IndirectDiffuse_Toon')),
      );
    });

    test('has no preprocessor conditionals to balance', () {
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

    test('everything it relies on is defined by earlier chunks', () {
      expect(
        fiber3dCommon,
        contains('vec3 BRDF_Lambert( const in vec3 diffuseColor )'),
      );
      expect(
        fiber3dGradientmapParsFragment,
        contains('vec3 getGradientIrradiance( vec3 normal, vec3 lightDirection )'),
      );
    });
  });
}