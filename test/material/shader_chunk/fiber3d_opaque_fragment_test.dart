import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_fiber/src/material/shader_chunk/fiber3d_opaque_fragment.dart';

void main() {
  const chunk = fiber3dOpaqueFragment;

  group('fiber3dOpaqueFragment', () {
    test('forces full alpha for opaque materials', () {
      expect(chunk, contains('#ifdef OPAQUE'));
      expect(chunk, contains('diffuseColor.a = 1.0;'));
    });

    test('transmission overrides alpha only when enabled', () {
      expect(chunk, contains('#ifdef USE_TRANSMISSION'));
      expect(chunk, contains('diffuseColor.a *= material.transmissionAlpha;'));
    });

    test('writes gl_FragColor from outgoingLight and the final alpha', () {
      expect(
        chunk,
        contains('gl_FragColor = vec4( outgoingLight, diffuseColor.a );'),
      );
    });

    test('preprocessor conditionals are balanced', () {
      final opens = RegExp(r'^\s*#if', multiLine: true).allMatches(chunk).length;
      final closes = RegExp(r'^\s*#endif', multiLine: true).allMatches(chunk).length;

      expect(opens, 2);
      expect(closes, opens);
    });

    test('is plain ASCII with no #include', () {
      expect(chunk.codeUnits.every((c) => c < 128), isTrue);
      expect(chunk, isNot(contains('#include')));
    });
  });
}