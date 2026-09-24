import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_fiber/src/core/fiber3d_color_management.dart';
import 'package:flutter_fiber/src/material/fiber3d_pbr_shader.dart';
import 'package:flutter_fiber/src/renderer/fiber3d_tone_mapping.dart';

void main() {
  group('Fiber3DPbrShader output pipeline', () {
    test('sRGB output is the default', () {
      final src = Fiber3DPbrShader.fragment('300 es');

      expect(src, contains('vec4 linearToOutputTexel( vec4 value ) {'));
      expect(src, contains('return sRGBTransferOETF( value );'));
      expect(
        src,
        contains('gl_FragColor = linearToOutputTexel( gl_FragColor );'),
      );
    });

    test('linear output leaves the image unencoded (v1 look)', () {
      final src = Fiber3DPbrShader.fragment(
        '300 es',
        outputColorSpace: Fiber3DColorSpace.linearSrgb,
      );

      expect(src, contains('return LinearTransferOETF( value );'));
      expect(src, isNot(contains('return sRGBTransferOETF( value );')));
    });

    test('no tone mapping by default', () {
      final src = Fiber3DPbrShader.fragment('300 es');

      expect(src, isNot(contains('#define TONE_MAPPING\n')));
      expect(src, isNot(contains('uniform float toneMappingExposure;')));
    });

    test('an active tone-mapping mode defines TONE_MAPPING and its operator',
        () {
      final src = Fiber3DPbrShader.fragment(
        '300 es',
        toneMapping: Fiber3DToneMapping.acesFilmic,
      );

      expect(src, contains('#define TONE_MAPPING\n'));
      expect(src, contains('uniform float toneMappingExposure;'));
      expect(
        src,
        contains(
          'vec3 toneMapping( vec3 color ) { return ACESFilmicToneMapping( color ); }',
        ),
      );
    });

        test('tone mapping runs before output encoding, both after lighting', () {
      final src = Fiber3DPbrShader.fragment(
        '300 es',
        toneMapping: Fiber3DToneMapping.acesFilmic,
      );

      final lit = src.indexOf('gl_FragColor = vec4( outgoingLight, diffuseColor.a );');
      final tone = src.indexOf(
        'gl_FragColor.rgb = toneMapping( gl_FragColor.rgb );',
      );
      final encode = src.indexOf(
        'gl_FragColor = linearToOutputTexel( gl_FragColor );',
      );

      expect(lit, greaterThan(-1));
      expect(tone, greaterThan(lit));
      expect(encode, greaterThan(tone));
    });
    
    test('helper functions are defined before main()', () {
      final src = Fiber3DPbrShader.fragment(
        '300 es',
        toneMapping: Fiber3DToneMapping.agx,
      );
      final main = src.indexOf('void main()');

      expect(src.indexOf('vec4 sRGBTransferOETF('), lessThan(main));
      expect(src.indexOf('vec4 linearToOutputTexel('), lessThan(main));
      expect(src.indexOf('vec3 toneMapping('), lessThan(main));
      expect(src.indexOf('#define TONE_MAPPING'), lessThan(main));
    });

        test('all #include directives are resolved', () {
      expect(Fiber3DPbrShader.fragment('300 es'), isNot(contains('#include')));
    });

    test('the version directive is still the first line', () {
      expect(
        Fiber3DPbrShader.fragment('300 es').startsWith('#version 300 es'),
        isTrue,
      );
    });
  });
}