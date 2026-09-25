import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_fiber/src/material/shader_chunk/fiber3d_bsdfs.dart';
import 'package:flutter_fiber/src/material/shader_chunk/fiber3d_common.dart';
import 'package:flutter_fiber/src/material/shader_chunk/fiber3d_lights_phong_pars_fragment.dart';

void main() {
  const chunk = fiber3dLightsPhongParsFragment;

  group('fiber3dLightsPhongParsFragment', () {
    test('declares vViewPosition', () {
      expect(chunk, contains('varying vec3 vViewPosition;'));
    });

    test('defines BlinnPhongMaterial with diffuse, specular, shininess, specularStrength', () {
      expect(chunk, contains('struct BlinnPhongMaterial {'));
      expect(chunk, contains('vec3 diffuseColor;'));
      expect(chunk, contains('vec3 specularColor;'));
      expect(chunk, contains('float specularShininess;'));
      expect(chunk, contains('float specularStrength;'));
    });

    test('direct light has both a Lambert diffuse term and a Blinn-Phong specular term', () {
      expect(
        chunk,
        contains(
          'void RE_Direct_BlinnPhong( const in IncidentLight directLight, const in vec3 geometryPosition, const in vec3 geometryNormal, const in vec3 geometryViewDir, const in vec3 geometryClearcoatNormal, const in BlinnPhongMaterial material, inout ReflectedLight reflectedLight )',
        ),
      );
      expect(
        chunk,
        contains(
          'reflectedLight.directDiffuse += irradiance * BRDF_Lambert( material.diffuseColor );',
        ),
      );
      expect(
        chunk,
        contains(
          'reflectedLight.directSpecular += irradiance * BRDF_BlinnPhong( directLight.direction, geometryViewDir, geometryNormal, material.specularColor, material.specularShininess ) * material.specularStrength;',
        ),
      );
    });

    test('indirect (ambient) light stays diffuse-only, same as Lambert', () {
      expect(
        chunk,
        contains(
          'void RE_IndirectDiffuse_BlinnPhong( const in vec3 irradiance, const in vec3 geometryPosition, const in vec3 geometryNormal, const in vec3 geometryViewDir, const in vec3 geometryClearcoatNormal, const in BlinnPhongMaterial material, inout ReflectedLight reflectedLight )',
        ),
      );
      expect(
        chunk,
        contains(
          'reflectedLight.indirectDiffuse += irradiance * BRDF_Lambert( material.diffuseColor );',
        ),
      );
      expect(chunk, isNot(contains('reflectedLight.indirectSpecular')));
    });

    test('aliases the RE_* names to the Blinn-Phong versions', () {
      expect(chunk, matches(RegExp(r'#define RE_Direct\s+RE_Direct_BlinnPhong')));
      expect(
        chunk,
        matches(RegExp(r'#define RE_IndirectDiffuse\s+RE_IndirectDiffuse_BlinnPhong')),
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
        fiber3dBsdfs,
        contains(
          'vec3 BRDF_BlinnPhong( const in vec3 lightDir, const in vec3 viewDir, const in vec3 normal, const in vec3 specularColor, const in float shininess )',
        ),
      );
    });
  });
}