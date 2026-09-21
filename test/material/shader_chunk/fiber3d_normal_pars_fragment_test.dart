import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_fiber/src/material/shader_chunk/fiber3d_normal_pars_fragment.dart';

void main() {
  const chunk = fiber3dNormalParsFragment;

  group('fiber3dNormalParsFragment', () {
    test('declares the interpolated normal unless flat shaded', () {
      expect(chunk, contains('#ifndef FLAT_SHADED'));
      expect(chunk, contains('varying vec3 vNormal;'));
    });

    test('declares the tangent frame only when tangents are used', () {
      expect(chunk, contains('#ifdef USE_TANGENT'));
      expect(chunk, contains('varying vec3 vTangent;'));
      expect(chunk, contains('varying vec3 vBitangent;'));
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