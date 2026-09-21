import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_fiber/src/material/shader_chunk/fiber3d_colorspace_pars_fragment.dart';

void main() {
  group('fiber3dColorspaceParsFragment', () {
    test('defines the three transfer functions', () {
      expect(
        fiber3dColorspaceParsFragment,
        contains('vec4 LinearTransferOETF( in vec4 value )'),
      );
      expect(
        fiber3dColorspaceParsFragment,
        contains('vec4 sRGBTransferEOTF( in vec4 value )'),
      );
      expect(
        fiber3dColorspaceParsFragment,
        contains('vec4 sRGBTransferOETF( in vec4 value )'),
      );
    });

    test('EOTF uses the same constants as Fiber3DColorManagement.srgbToLinear',
        () {
      for (final c in ['0.9478672986', '0.0521327014', '2.4', '0.0773993808', '0.04045']) {
        expect(fiber3dColorspaceParsFragment, contains(c));
      }
    });

    test('OETF uses the same constants as Fiber3DColorManagement.linearToSrgb',
        () {
      for (final c in ['0.41666', '1.055', '0.055', '12.92', '0.0031308']) {
        expect(fiber3dColorspaceParsFragment, contains(c));
      }
    });
  });
}