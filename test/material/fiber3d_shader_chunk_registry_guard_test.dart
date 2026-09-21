import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_fiber/src/material/fiber3d_shader_chunk.dart';

void main() {
  test('every registered chunk is plain ASCII', () {
    // Desktop GLSL 150 compilers can reject non-ASCII source characters.
    Fiber3DShaderChunk.chunks.forEach((name, source) {
      expect(
        source.codeUnits.every((c) => c < 128),
        isTrue,
        reason: '$name contains non-ASCII characters',
      );
    });
  });
  test('every chunk file in shader_chunk/ is registered', () {
    final files = Directory('lib/src/material/shader_chunk')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));

    expect(files, isNotEmpty);

    for (final file in files) {
      final name = file.uri.pathSegments.last
          .replaceFirst('fiber3d_', '')
          .replaceFirst('.dart', '');

      expect(
        Fiber3DShaderChunk.chunks.containsKey(name),
        isTrue,
        reason: '$name is not registered in Fiber3DShaderChunk.chunks',
      );
    }
  });
}