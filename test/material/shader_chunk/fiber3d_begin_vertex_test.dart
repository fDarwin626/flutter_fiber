import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_fiber/src/material/shader_chunk/fiber3d_begin_vertex.dart';

void main() {
  const chunk = fiber3dBeginVertex;

  group('fiber3dBeginVertex', () {
    test('starts transformed from the position attribute', () {
      expect(chunk, contains('vec3 transformed = vec3( position );'));
    });

    test('records vPosition only for alpha hashing', () {
      expect(chunk, contains('#ifdef USE_ALPHAHASH'));
      expect(chunk, contains('vPosition = vec3( position );'));
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