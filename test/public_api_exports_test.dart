import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// Files under lib/src that are deliberately NOT part of the public API.
// Everything under src/material/shader_chunk/ is internal too.
const _internal = <String>{
  'src/light/fiber3d_lights_state.dart',
  'src/material/fiber3d_shader_preprocess.dart',
  'src/material/fiber3d_dfg_lut_data.dart',
  'src/material/fiber3d_edge_shader.dart',
  'src/material/fiber3d_pbr_shader.dart',
  'src/material/fiber3d_lambert_shader.dart',
  'src/material/fiber3d_phong_shader.dart',
  'src/material/fiber3d_toon_shader.dart',
  'src/material/fiber3d_matcap_shader.dart',
  'src/material/fiber3d_program_functions.dart',   
  'src/material/fiber3d_shader_chunk.dart',
};
void main() {
  test('every public file under lib/src is exported from flutter_fiber.dart', () {
    final barrel = File('lib/flutter_fiber.dart').readAsStringSync();
    final files = Directory('lib/src')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));

    for (final file in files) {
      final relative = file.path
          .replaceAll('\\', '/')
          .replaceFirst(RegExp(r'^lib/'), '');

      if (_internal.contains(relative) ||
          relative.startsWith('src/material/shader_chunk/')) {
        continue;
      }

      expect(
        barrel,
        contains("export '$relative';"),
        reason: '$relative is not exported from lib/flutter_fiber.dart',
      );
    }
  });

  test('every export in flutter_fiber.dart points at an existing file', () {
    final barrel = File('lib/flutter_fiber.dart').readAsStringSync();
    final exports = RegExp(r"export '([^']+)';").allMatches(barrel);

    expect(exports, isNotEmpty);

    for (final match in exports) {
      final path = match.group(1)!;
      expect(File('lib/$path').existsSync(), isTrue, reason: '$path is missing');
    }
  });
}