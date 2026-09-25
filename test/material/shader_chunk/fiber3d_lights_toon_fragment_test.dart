import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_fiber/src/material/shader_chunk/fiber3d_lights_toon_fragment.dart';

void main() {
  const chunk = fiber3dLightsToonFragment;

  group('fiber3dLightsToonFragment', () {
    test('fills the ToonMaterial struct from diffuseColor — nothing else to fill', () {
      expect(chunk, contains('ToonMaterial material;'));
      expect(chunk, contains('material.diffuseColor = diffuseColor.rgb;'));
    });

    test('has no preprocessor conditionals to balance', () {
      final opens = RegExp(r'^\s*#if', multiLine: true).allMatches(chunk).length;
      final closes = RegExp(r'^\s*#endif', multiLine: true).allMatches(chunk).length;

      expect(opens, 0);
      expect(closes, 0);
    });

    test('is plain ASCII', () {
      expect(chunk.codeUnits.every((c) => c < 128), isTrue);
    });

    test('has no #include left to resolve', () {
      expect(chunk, isNot(contains('#include')));
    });
  });
}