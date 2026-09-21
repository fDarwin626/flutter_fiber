import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_fiber/src/material/shader_chunk/fiber3d_colorspace_fragment.dart';

void main() {
  group('fiber3dColorspaceFragment', () {
    test('encodes gl_FragColor through linearToOutputTexel', () {
      expect(
        fiber3dColorspaceFragment,
        contains('gl_FragColor = linearToOutputTexel( gl_FragColor );'),
      );
    });
  });
}