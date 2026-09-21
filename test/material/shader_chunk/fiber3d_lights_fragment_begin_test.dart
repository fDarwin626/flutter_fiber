import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_fiber/src/material/shader_chunk/fiber3d_lights_fragment_begin.dart';

void main() {
  const chunk = fiber3dLightsFragmentBegin;

  group('fiber3dLightsFragmentBegin', () {
    test('sets up the lighting geometry in view space', () {
      expect(chunk, contains('vec3 geometryPosition = - vViewPosition;'));
      expect(chunk, contains('vec3 geometryNormal = normal;'));
      expect(
        chunk,
        contains('vec3 geometryViewDir = ( isOrthographic ) ? vec3( 0, 0, 1 ) : normalize( vViewPosition );'),
      );
    });

    test('STANDARD materials read the DFG texture and set the compensation', () {
      expect(chunk, contains('#ifdef STANDARD'));
      expect(
        chunk,
        contains('material.dfg = texture2D( dfgLUT, vec2( material.roughness, dotNVms ) ).rg;'),
      );
      expect(chunk, contains('float EssMs = material.dfg.x + material.dfg.y;'));
      expect(
        chunk,
        contains('material.multiScatteringCompensation = 1.0 + material.specularColorBlended * ( 1.0 / EssMs - 1.0 );'),
      );
    });

    test('the compensation is only computed when a direct light exists', () {
      expect(
        chunk,
        contains('#if ( NUM_SUN_LIGHTS > 0 || NUM_DIR_LIGHTS > 0 || NUM_POINT_LIGHTS > 0 || NUM_SPOT_LIGHTS > 0 )'),
      );
    });

    test('each direct light type has a guarded loop that calls RE_Direct', () {
      for (final name in ['POINT', 'SPOT', 'SUN', 'DIR']) {
        expect(chunk, contains('#if ( NUM_${name}_LIGHTS > 0 ) && defined( RE_Direct )'));
      }
      expect(
        chunk,
        contains('#if ( NUM_RECT_AREA_LIGHTS > 0 ) && defined( RE_Direct_RectArea )'),
      );

      const call =
          'RE_Direct( directLight, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight );';
      expect(call.allMatches(chunk).length, 4);
      expect(chunk, contains('RE_Direct_RectArea( rectAreaLight,'));
    });

    test('point lights read the uniform array and the getter from lights_pars_begin', () {
      expect(chunk, contains('pointLight = pointLights[ i ];'));
      expect(
        chunk,
        contains('getPointLightInfo( pointLight, geometryPosition, directLight );'),
      );
    });

    test('every light loop is marked for unrolling with a countable bound', () {
      final starts = '#pragma unroll_loop_start'.allMatches(chunk).length;
      final ends = '#pragma unroll_loop_end'.allMatches(chunk).length;

      // point, spot, sun, directional, rect area, hemisphere
      expect(starts, 6);
      expect(ends, starts);

      final loops = RegExp(
        r'#pragma unroll_loop_start\s+for \( int i = 0; i < NUM_[A-Z_]+_LIGHTS; i \+\+ \) \{',
      ).allMatches(chunk).length;

      expect(loops, starts);
    });

    test('indirect diffuse starts from the ambient and hemisphere irradiance', () {
      expect(
        chunk,
        contains('vec3 irradiance = getAmbientLightIrradiance( ambientLightColor );'),
      );
      expect(
        chunk,
        contains('irradiance += getHemisphereLightIrradiance( hemisphereLights[ i ], geometryNormal );'),
      );
    });

    test('indirect specular radiance is initialised when RE_IndirectSpecular exists', () {
      expect(chunk, contains('#if defined( RE_IndirectSpecular )'));
      expect(chunk, contains('vec3 radiance = vec3( 0.0 );'));
      expect(chunk, contains('vec3 clearcoatRadiance = vec3( 0.0 );'));
    });

    test('shadow and light-probe-grid blocks stay behind their defines', () {
      expect(chunk, contains('#if defined( USE_SHADOWMAP )'));
      expect(chunk, contains('#ifdef USE_LIGHT_PROBES_GRID'));
      expect(chunk, contains('#if defined( USE_LIGHT_PROBES )'));
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