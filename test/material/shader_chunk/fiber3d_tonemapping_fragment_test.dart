import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_fiber/src/material/shader_chunk/fiber3d_tonemapping_fragment.dart';

void main() {
  group('fiber3dTonemappingFragment', () {
    test('guards tone mapping behind TONE_MAPPING', () {
      expect(fiber3dTonemappingFragment, contains('#if defined( TONE_MAPPING )'));
      expect(fiber3dTonemappingFragment, contains('#endif'));
    });

    test('applies toneMapping to the fragment color', () {
      expect(
        fiber3dTonemappingFragment,
        contains('gl_FragColor.rgb = toneMapping( gl_FragColor.rgb );'),
      );
    });
  });
}