import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_fiber/src/material/shader_chunk/fiber3d_defaultnormal_vertex.dart';
import 'package:flutter_fiber/src/material/shader_chunk/fiber3d_normal_pars_vertex.dart';
import 'package:flutter_fiber/src/material/shader_chunk/fiber3d_normal_vertex.dart';

void main() {
  const chunk = fiber3dNormalVertex;

  group('fiber3dNormalVertex', () {
    test('writes the normalized normal, unless flat shaded', () {
      expect(chunk, contains('#ifndef FLAT_SHADED'));
      expect(chunk, contains('vNormal = normalize( transformedNormal );'));
    });

    test('writes the tangent frame only when tangents are used', () {
      expect(chunk, contains('#ifdef USE_TANGENT'));
      expect(chunk, contains('vTangent = normalize( transformedTangent );'));
      expect(
        chunk,
        contains('vBitangent = normalize( cross( vNormal, vTangent ) * tangent.w );'),
      );
    });

    test('flips the bitangent for FLIP_SIDED', () {
      expect(chunk, contains('#ifdef FLIP_SIDED'));
      expect(chunk, contains('vBitangent = - vBitangent;'));
    });

    test('reads transformedNormal from defaultnormal_vertex', () {
      expect(fiber3dDefaultnormalVertex, contains('transformedNormal = normalMatrix * transformedNormal;'));
    });

    test('writes the varyings normal_pars_vertex declares', () {
      expect(fiber3dNormalParsVertex, contains('varying vec3 vNormal;'));
    });

    test('is balanced, plain ASCII, with no #include', () {
      expect(
        RegExp(r'^\s*#if', multiLine: true).allMatches(chunk).length,
        RegExp(r'^\s*#endif', multiLine: true).allMatches(chunk).length,
      );
      expect(chunk.codeUnits.every((c) => c < 128), isTrue);
      expect(chunk, isNot(contains('#include')));
    });
  });
}