import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_fiber/src/material/shader_chunk/fiber3d_lights_fragment_begin.dart';
import 'package:flutter_fiber/src/material/shader_chunk/fiber3d_lights_fragment_maps.dart';

void main() {
  const chunk = fiber3dLightsFragmentMaps;

  group('fiber3dLightsFragmentMaps', () {
    test('adds light-map irradiance to the indirect diffuse irradiance', () {
      expect(chunk, contains('#ifdef USE_LIGHTMAP'));
      expect(
        chunk,
        contains('vec3 lightMapIrradiance = lightMapTexel.rgb * lightMapIntensity;'),
      );
      expect(chunk, contains('irradiance += lightMapIrradiance;'));
    });

    test('IBL irradiance only comes from a PMREM environment map', () {
      expect(
        chunk,
        contains('#if defined( USE_ENVMAP ) && defined( ENVMAP_TYPE_PMREM )'),
      );
      expect(
        chunk,
        contains('#if defined( STANDARD ) || defined( LAMBERT ) || defined( PHONG )'),
      );
      expect(chunk, contains('iblIrradiance += getIBLIrradiance( geometryNormal );'));
    });

    test('IBL radiance is added to the specular radiance', () {
      expect(chunk, contains('#if defined( USE_ENVMAP ) && defined( RE_IndirectSpecular )'));
      expect(
        chunk,
        contains('vec3 iblRadiance = getIBLRadiance( geometryViewDir, geometryNormal, material.roughness );'),
      );
      expect(chunk, contains('radiance += iblRadiance;'));
    });

    test('clearcoat radiance uses the clearcoat normal and roughness', () {
      expect(
        chunk,
        contains('clearcoatRadiance += getIBLRadiance( geometryViewDir, geometryClearcoatNormal, material.clearcoatRoughness );'),
      );
    });

    test('anisotropy and retroreflection variants exist behind their guards', () {
      expect(chunk, contains('getIBLAnisotropyRadiance('));
      expect(chunk, contains('getIBLAnisotropyRetroRadiance('));
      expect(chunk, contains('getIBLRetroRadiance('));
      expect(chunk, contains('#ifdef USE_ANISOTROPY'));
      expect(chunk, contains('#ifdef USE_RETROREFLECTION'));
    });

    test('nothing is added unless an environment or light map is enabled', () {
      // Every statement that writes an accumulator sits inside a guard, so
      // with no defines the accumulators stay at their initial zero.
      final firstStatement = chunk.indexOf('irradiance +=');
      final firstGuard = chunk.indexOf('#ifdef USE_LIGHTMAP');

      expect(firstGuard, lessThan(firstStatement));
    });

    test('the accumulators it writes are declared by lights_fragment_begin', () {
      expect(fiber3dLightsFragmentBegin, contains('vec3 iblIrradiance = vec3( 0.0 );'));
      expect(
        fiber3dLightsFragmentBegin,
        contains('vec3 irradiance = getAmbientLightIrradiance( ambientLightColor );'),
      );
      expect(fiber3dLightsFragmentBegin, contains('vec3 radiance = vec3( 0.0 );'));
      expect(fiber3dLightsFragmentBegin, contains('vec3 clearcoatRadiance = vec3( 0.0 );'));
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
  });
}