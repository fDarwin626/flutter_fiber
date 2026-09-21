import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_fiber/src/core/fiber3d_color_management.dart';
import 'package:flutter_fiber/src/material/fiber3d_program_functions.dart';
import 'package:flutter_fiber/src/material/shader_chunk/fiber3d_colorspace_pars_fragment.dart';
import 'package:flutter_fiber/src/material/shader_chunk/fiber3d_tonemapping_pars_fragment.dart';
import 'package:flutter_fiber/src/renderer/fiber3d_tone_mapping.dart';

void main() {
  group('Fiber3DProgramFunctions', () {
    test('texelEncodingFunction encodes sRGB output', () {
      expect(
        Fiber3DProgramFunctions.texelEncodingFunction(
          'linearToOutputTexel',
          Fiber3DColorSpace.srgb,
        ),
        'vec4 linearToOutputTexel( vec4 value ) {\n'
        '\treturn sRGBTransferOETF( value );\n'
        '}',
      );
    });

    test('texelEncodingFunction leaves linear and none output unencoded', () {
      for (final space in [Fiber3DColorSpace.linearSrgb, Fiber3DColorSpace.none]) {
        expect(
          Fiber3DProgramFunctions.texelEncodingFunction('f', space),
          'vec4 f( vec4 value ) {\n\treturn LinearTransferOETF( value );\n}',
        );
      }
    });

    test('texelEncodingFunction calls a function the colorspace chunk defines',
        () {
      for (final space in Fiber3DColorSpace.values) {
        final fn = Fiber3DProgramFunctions.texelEncodingFunction('f', space);
        final name = RegExp(r'return (\w+)\(').firstMatch(fn)!.group(1);
        expect(
          fiber3dColorspaceParsFragment,
          contains('vec4 $name( in vec4 value )'),
        );
      }
    });

    test('toneMappingFunction wraps the matching operator', () {
      const expected = {
        Fiber3DToneMapping.linear: 'Linear',
        Fiber3DToneMapping.reinhard: 'Reinhard',
        Fiber3DToneMapping.cineon: 'Cineon',
        Fiber3DToneMapping.acesFilmic: 'ACESFilmic',
        Fiber3DToneMapping.custom: 'Custom',
        Fiber3DToneMapping.agx: 'AgX',
        Fiber3DToneMapping.neutral: 'Neutral',
      };

      expected.forEach((mode, name) {
        expect(
          Fiber3DProgramFunctions.toneMappingFunction('toneMapping', mode),
          'vec3 toneMapping( vec3 color ) { return ${name}ToneMapping( color ); }',
        );
      });
    });

    test('toneMappingFunction falls back to Linear for none', () {
      expect(
        Fiber3DProgramFunctions.toneMappingFunction(
          'toneMapping',
          Fiber3DToneMapping.none,
        ),
        'vec3 toneMapping( vec3 color ) { return LinearToneMapping( color ); }',
      );
    });

    test('toneMappingFunction calls an operator the tonemapping chunk defines',
        () {
      for (final mode in Fiber3DToneMapping.values) {
        final fn = Fiber3DProgramFunctions.toneMappingFunction('toneMapping', mode);
        final name = RegExp(r'return (\w+)\(').firstMatch(fn)!.group(1);
        expect(
          fiber3dTonemappingParsFragment,
          contains('vec3 $name( vec3 color )'),
        );
      }
    });

    test('luminanceFunction uses the Rec.709 weights', () {
      expect(
        Fiber3DProgramFunctions.luminanceFunction(),
        'float luminance( const in vec3 rgb ) {\n'
        '\tconst vec3 weights = vec3( 0.2126, 0.7152, 0.0722 );\n'
        '\treturn dot( weights, rgb );\n'
        '}',
      );
    });
  });
}