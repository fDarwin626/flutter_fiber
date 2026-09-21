import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_fiber/src/material/shader_chunk/fiber3d_common.dart';
import 'package:flutter_fiber/src/material/shader_chunk/fiber3d_lights_pars_begin.dart';
import 'package:flutter_fiber/src/material/shader_chunk/fiber3d_lights_physical_pars_fragment.dart';

void main() {
  const chunk = fiber3dLightsPhysicalParsFragment;

  group('fiber3dLightsPhysicalParsFragment', () {
    test('declares the DFG lookup texture', () {
      expect(chunk, contains('uniform sampler2D dfgLUT;'));
    });

    test('defines PhysicalMaterial with the core fields', () {
      expect(chunk, contains('struct PhysicalMaterial {'));
      for (final field in [
        'vec3 diffuseColor;',
        'vec3 diffuseContribution;',
        'vec3 specularColor;',
        'vec3 specularColorBlended;',
        'float roughness;',
        'float metalness;',
        'float specularF90;',
        'vec2 dfg;',
        'vec3 multiScatteringCompensation;',
      ]) {
        expect(chunk, contains(field));
      }
    });

    test('feature fields sit behind their #ifdef guards', () {
      for (final guard in [
        '#ifdef USE_DIFFUSE_ROUGHNESS',
        '#ifdef USE_RETROREFLECTION',
        '#ifdef USE_CLEARCOAT',
        '#ifdef USE_IRIDESCENCE',
        '#ifdef USE_SHEEN',
        '#ifdef IOR',
        '#ifdef USE_TRANSMISSION',
        '#ifdef USE_ANISOTROPY',
      ]) {
        expect(chunk, contains(guard));
      }
    });

    test('defines the GGX specular pieces', () {
      expect(
        chunk,
        contains('float V_GGX_SmithCorrelated( const in float alpha, const in float dotNL, const in float dotNV )'),
      );
      expect(chunk, contains('float D_GGX( const in float alpha, const in float dotNH )'));
      expect(
        chunk,
        contains('vec3 BRDF_GGX( const in vec3 lightDir, const in vec3 viewDir, const in vec3 normal, const in PhysicalMaterial material )'),
      );
      expect(chunk, contains('return RECIPROCAL_PI * a2 / pow2( denom );'));
      expect(chunk, contains('return 0.5 / max( gv + gl, EPSILON );'));
    });

    test('punctual lights use a minimum roughness of 0.0525', () {
      expect(chunk, contains('max( material.roughness, 0.0525 )'));
      expect(chunk, contains('max( material.clearcoatRoughness, 0.0525 )'));
    });

    test('defines the rect-area, sheen and environment helpers', () {
      for (final signature in [
        'vec2 LTC_Uv( const in vec3 N, const in vec3 V, const in float roughness )',
        'float LTC_ClippedSphereFormFactor( const in vec3 f )',
        'vec3 LTC_EdgeVectorFormFactor( const in vec3 v1, const in vec3 v2 )',
        'vec3 LTC_Evaluate( const in vec3 N, const in vec3 V, const in vec3 P, const in mat3 mInv, const in vec3 rectCoords[ 4 ] )',
        'float IBLSheenBRDF( const in vec3 normal, const in vec3 viewDir, const in float roughness )',
        'vec3 EnvironmentBRDF( const in vec3 normal, const in vec3 viewDir, const in vec3 specularColor, const in float specularF90, const in float roughness )',
        'vec3 Schlick_to_F0( const in vec3 f, const in float f90, const in float dotVH )',
        'float computeSpecularOcclusion( const in float dotNV, const in float ambientOcclusion, const in float roughness )',
      ]) {
        expect(chunk, contains(signature));
      }
    });

    test('environment BRDF reads the DFG texture', () {
      expect(
        chunk,
        contains('texture2D( dfgLUT, vec2( roughness, dotNV ) ).rg'),
      );
    });

    test('defines both multiscattering variants', () {
      expect(
        chunk,
        contains('void computeMultiscattering( const in vec2 fab, const in vec3 specularColor, const in float specularF90, inout vec3 singleScatter, inout vec3 multiScatter )'),
      );
      expect(
        chunk,
        contains('void computeMultiscatteringIridescence( const in vec2 fab,'),
      );
    });

    test('defines the three entry points', () {
      expect(
        chunk,
        contains('void RE_Direct_Physical( const in IncidentLight directLight, const in vec3 geometryPosition, const in vec3 geometryNormal, const in vec3 geometryViewDir, const in vec3 geometryClearcoatNormal, const in PhysicalMaterial material, inout ReflectedLight reflectedLight )'),
      );
      expect(
        chunk,
        contains('void RE_IndirectDiffuse_Physical( const in vec3 irradiance,'),
      );
      expect(
        chunk,
        contains('void RE_IndirectSpecular_Physical( const in vec3 radiance, const in vec3 irradiance, const in vec3 clearcoatRadiance,'),
      );
    });

    test('aliases the RE_* names to the physical versions', () {
      expect(chunk, matches(RegExp(r'#define RE_Direct\s+RE_Direct_Physical')));
      expect(
        chunk,
        matches(RegExp(r'#define RE_Direct_RectArea\s+RE_Direct_RectArea_Physical')),
      );
      expect(
        chunk,
        matches(RegExp(r'#define RE_IndirectDiffuse\s+RE_IndirectDiffuse_Physical')),
      );
      expect(
        chunk,
        matches(RegExp(r'#define RE_IndirectSpecular\s+RE_IndirectSpecular_Physical')),
      );
    });

    test('direct diffuse is Lambert scaled by (1 - fresnel)', () {
      expect(
        chunk,
        contains('vec3 diffuseBRDF = BRDF_Lambert( material.diffuseContribution );'),
      );
      expect(
        chunk,
        contains('reflectedLight.directDiffuse += irradiance * diffuseBRDF * ( 1.0 - F );'),
      );
    });

    test('indirect (ambient / sky) diffuse goes through BRDF_Lambert, i.e. 1/pi', () {
      expect(
        chunk,
        contains('vec3 diffuse = irradiance * BRDF_Lambert( material.diffuseContribution ) * ( 1.0 - singleScattering - multiScattering );'),
      );
    });

    test('specular is scaled by the multiscattering compensation', () {
      expect(
        chunk,
        contains('irradiance * specularBRDF * material.multiScatteringCompensation'),
      );
    });

    test('preprocessor conditionals are balanced', () {
      final opens = RegExp(r'^\s*#if', multiLine: true).allMatches(chunk).length;
      final closes = RegExp(r'^\s*#endif', multiLine: true).allMatches(chunk).length;

      expect(opens, greaterThan(0));
      expect(closes, opens);
    });

    test('is plain ASCII', () {
      expect(chunk.codeUnits.every((c) => c < 128), isTrue);
    });

    test('has no #include left to resolve', () {
      expect(chunk, isNot(contains('#include')));
    });

    test('everything it relies on is defined by earlier chunks', () {
      expect(fiber3dCommon, contains('vec3 BRDF_Lambert( const in vec3 diffuseColor )'));
      expect(
        fiber3dCommon,
        contains('vec3 F_Schlick( const in vec3 f0, const in float f90, const in float dotVH )'),
      );
      expect(fiber3dCommon, contains('#define EPSILON '));
      expect(fiber3dCommon, contains('float max3( const in vec3 v )'));
      expect(fiber3dCommon, contains('struct ReflectedLight {'));
      expect(fiber3dLightsParsBegin, contains('struct RectAreaLight {'));
    });
  });
}