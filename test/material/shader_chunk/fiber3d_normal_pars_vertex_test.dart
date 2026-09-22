import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_fiber/src/material/shader_chunk/fiber3d_normal_pars_fragment.dart';
import 'package:flutter_fiber/src/material/shader_chunk/fiber3d_normal_pars_vertex.dart';

void main() {
  group('fiber3dNormalParsVertex', () {
    test('declares the normal (and tangent frame) varyings', () {
      expect(fiber3dNormalParsVertex, contains('#ifndef FLAT_SHADED'));
      expect(fiber3dNormalParsVertex, contains('varying vec3 vNormal;'));
      expect(fiber3dNormalParsVertex, contains('#ifdef USE_TANGENT'));
      expect(fiber3dNormalParsVertex, contains('varying vec3 vTangent;'));
      expect(fiber3dNormalParsVertex, contains('varying vec3 vBitangent;'));
    });

    test('is identical to normal_pars_fragment, matching three.js', () {
      expect(fiber3dNormalParsVertex, fiber3dNormalParsFragment);
    });

    test('is balanced, plain ASCII, with no #include', () {
      expect(
        RegExp(r'^\s*#if', multiLine: true).allMatches(fiber3dNormalParsVertex).length,
        RegExp(r'^\s*#endif', multiLine: true).allMatches(fiber3dNormalParsVertex).length,
      );
      expect(fiber3dNormalParsVertex.codeUnits.every((c) => c < 128), isTrue);
      expect(fiber3dNormalParsVertex, isNot(contains('#include')));
    });
  });
}