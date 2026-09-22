import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_fiber/src/material/shader_chunk/fiber3d_beginnormal_vertex.dart';

void main() {
  const chunk = fiber3dBeginnormalVertex;

  group('fiber3dBeginnormalVertex', () {
    test('starts objectNormal from the normal attribute', () {
      expect(chunk, contains('vec3 objectNormal = vec3( normal );'));
    });

    test('reads the tangent attribute only when tangents are used', () {
      expect(chunk, contains('#ifdef USE_TANGENT'));
      expect(chunk, contains('vec3 objectTangent = vec3( tangent.xyz );'));
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