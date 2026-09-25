import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_fiber/src/material/shader_chunk/fiber3d_lights_phong_fragment.dart';

void main() {
  const chunk = fiber3dLightsPhongFragment;

  group('fiber3dLightsPhongFragment', () {
    test('fills the BlinnPhongMaterial struct from diffuseColor/specular/shininess', () {
      expect(chunk, contains('BlinnPhongMaterial material;'));
      expect(chunk, contains('material.diffuseColor = diffuseColor.rgb;'));
      expect(chunk, contains('material.specularColor = specular;'));
      expect(chunk, contains('material.specularShininess = shininess;'));
    });

    test('specularStrength defaults to 1.0 — same flutter_fiber deviation as '
        'Lambert, no specularmap_fragment ported yet to set a real value', () {
      expect(chunk, contains('material.specularStrength = 1.0;'));
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