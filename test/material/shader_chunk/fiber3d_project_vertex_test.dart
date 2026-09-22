import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_fiber/src/material/shader_chunk/fiber3d_begin_vertex.dart';
import 'package:flutter_fiber/src/material/shader_chunk/fiber3d_project_vertex.dart';

void main() {
  const chunk = fiber3dProjectVertex;

  group('fiber3dProjectVertex', () {
    test('starts from the transformed position', () {
      expect(chunk, contains('vec4 mvPosition = vec4( transformed, 1.0 );'));
    });

    test('batching and instancing are inactive by default', () {
      expect(chunk, contains('#ifdef USE_BATCHING'));
      expect(chunk, contains('mvPosition = batchingMatrix * mvPosition;'));
      expect(chunk, contains('#ifdef USE_INSTANCING'));
      expect(chunk, contains('mvPosition = instanceMatrix * mvPosition;'));
    });

    test('transforms through modelViewMatrix, then projectionMatrix, to gl_Position', () {
      expect(chunk, contains('mvPosition = modelViewMatrix * mvPosition;'));
      expect(chunk, contains('gl_Position = projectionMatrix * mvPosition;'));
    });

    test('consumes the transformed variable begin_vertex declares', () {
      expect(fiber3dBeginVertex, contains('vec3 transformed = vec3( position );'));
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