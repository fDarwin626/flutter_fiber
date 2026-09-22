import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_fiber/src/material/shader_chunk/fiber3d_defaultnormal_vertex.dart';

void main() {
  const chunk = fiber3dDefaultnormalVertex;

  group('fiber3dDefaultnormalVertex', () {
    test('starts from objectNormal', () {
      expect(chunk, contains('vec3 transformedNormal = objectNormal;'));
    });

    test('batching and instancing normal correction is inactive by default', () {
      expect(chunk, contains('#ifdef USE_BATCHING'));
      expect(chunk, contains('#ifdef USE_INSTANCING'));
      expect(chunk, contains('mat3 bm = mat3( batchingMatrix );'));
      expect(chunk, contains('mat3 im = mat3( instanceMatrix );'));
    });

    test('transforms the normal into view space via normalMatrix', () {
      expect(chunk, contains('transformedNormal = normalMatrix * transformedNormal;'));
    });

    test('flips the normal for FLIP_SIDED', () {
      expect(chunk, contains('#ifdef FLIP_SIDED'));
      expect(chunk, contains('transformedNormal = - transformedNormal;'));
    });

    test('transforms the tangent through modelViewMatrix when used', () {
      expect(
        chunk,
        contains('transformedTangent = ( modelViewMatrix * vec4( transformedTangent, 0.0 ) ).xyz;'),
      );
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