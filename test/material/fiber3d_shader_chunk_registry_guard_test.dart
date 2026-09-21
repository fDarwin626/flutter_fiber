import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_fiber/src/material/fiber3d_shader_chunk.dart';

void main() {
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