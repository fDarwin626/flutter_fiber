import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_fiber/src/material/shader_chunk/fiber3d_gradientmap_pars_fragment.dart';

void main() {
  const chunk = fiber3dGradientmapParsFragment;

  group('fiber3dGradientmapParsFragment', () {
    test('declares getGradientIrradiance', () {
      expect(
        chunk,
        contains('vec3 getGradientIrradiance( vec3 normal, vec3 lightDirection )'),
      );
    });

    test('the USE_GRADIENTMAP texture path exists but is dormant — '
        'flutter_fiber has no texture pipeline yet, so this never '
        'triggers', () {
      expect(chunk, contains('#ifdef USE_GRADIENTMAP'));
      expect(chunk, contains('uniform sampler2D gradientMap;'));
      expect(chunk, contains('texture2D( gradientMap, coord )'));
    });

    test('the fallback (no gradient map) path is a fixed two-band step '
        'at coord.x = 0.7, anti-aliased via fwidth', () {
      expect(chunk, contains('#else'));
      expect(chunk, contains('vec2 fw = fwidth( coord ) * 0.5;'));
      expect(
        chunk,
        contains(
          'mix( vec3( 0.7 ), vec3( 1.0 ), smoothstep( 0.7 - fw.x, 0.7 + fw.x, coord.x ) )',
        ),
      );
    });

    test('coord remaps dotNL from [-1, 1] into [0, 1]', () {
      expect(chunk, contains('float dotNL = dot( normal, lightDirection );'));
      expect(
        chunk,
        contains('vec2 coord = vec2( dotNL * 0.5 + 0.5, 0.0 );'),
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
  });
}