import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_fiber/src/material/fiber3d_shader_chunk.dart';
import 'package:flutter_fiber/src/material/shader_chunk/fiber3d_bsdfs.dart';
import 'package:flutter_fiber/src/material/shader_chunk/fiber3d_colorspace_fragment.dart';
import 'package:flutter_fiber/src/material/shader_chunk/fiber3d_colorspace_pars_fragment.dart';
import 'package:flutter_fiber/src/material/shader_chunk/fiber3d_common.dart';
import 'package:flutter_fiber/src/material/shader_chunk/fiber3d_lights_fragment_begin.dart';
import 'package:flutter_fiber/src/material/shader_chunk/fiber3d_lights_fragment_end.dart';
import 'package:flutter_fiber/src/material/shader_chunk/fiber3d_lights_fragment_maps.dart';
import 'package:flutter_fiber/src/material/shader_chunk/fiber3d_lights_pars_begin.dart';
import 'package:flutter_fiber/src/material/shader_chunk/fiber3d_lights_physical_fragment.dart';
import 'package:flutter_fiber/src/material/shader_chunk/fiber3d_lights_physical_pars_fragment.dart';
import 'package:flutter_fiber/src/material/shader_chunk/fiber3d_metalnessmap_fragment.dart';
import 'package:flutter_fiber/src/material/shader_chunk/fiber3d_normal_fragment_begin.dart';
import 'package:flutter_fiber/src/material/shader_chunk/fiber3d_normal_pars_fragment.dart';
import 'package:flutter_fiber/src/material/shader_chunk/fiber3d_roughnessmap_fragment.dart';
import 'package:flutter_fiber/src/material/shader_chunk/fiber3d_tonemapping_fragment.dart';
import 'package:flutter_fiber/src/material/shader_chunk/fiber3d_tonemapping_pars_fragment.dart';

void main() {
  group('Fiber3DShaderChunk', () {
    test('registers the ported chunks under their three.js names', () {
      expect(
        Fiber3DShaderChunk.chunks['colorspace_fragment'],
        fiber3dColorspaceFragment,
      );
      expect(
        Fiber3DShaderChunk.chunks['colorspace_pars_fragment'],
        fiber3dColorspaceParsFragment,
      );
      expect(
        Fiber3DShaderChunk.chunks['tonemapping_fragment'],
        fiber3dTonemappingFragment,
      );
      expect(
        Fiber3DShaderChunk.chunks['tonemapping_pars_fragment'],
        fiber3dTonemappingParsFragment,
      );
    });

    test('registers lights_physical_fragment', () {
      expect(
        Fiber3DShaderChunk.chunks['lights_physical_fragment'],
        fiber3dLightsPhysicalFragment,
      );
    });

    test('registers lights_physical_pars_fragment', () {
      expect(
        Fiber3DShaderChunk.chunks['lights_physical_pars_fragment'],
        fiber3dLightsPhysicalParsFragment,
      );
    });

    test('registers lights_fragment_end', () {
      expect(
        Fiber3DShaderChunk.chunks['lights_fragment_end'],
        fiber3dLightsFragmentEnd,
      );
    });

    test('registers lights_fragment_maps', () {
      expect(
        Fiber3DShaderChunk.chunks['lights_fragment_maps'],
        fiber3dLightsFragmentMaps,
      );
    });

    test('registers lights_fragment_begin', () {
      expect(
        Fiber3DShaderChunk.chunks['lights_fragment_begin'],
        fiber3dLightsFragmentBegin,
      );
    });

    test('registers lights_pars_begin', () {
      expect(
        Fiber3DShaderChunk.chunks['lights_pars_begin'],
        fiber3dLightsParsBegin,
      );
    });

    test('registers common', () {
      expect(Fiber3DShaderChunk.chunks['common'], fiber3dCommon);
    });

    test('registers bsdfs', () {
      expect(Fiber3DShaderChunk.chunks['bsdfs'], fiber3dBsdfs);
    });

    test('registers metalnessmap_fragment', () {
      expect(
        Fiber3DShaderChunk.chunks['metalnessmap_fragment'],
        fiber3dMetalnessmapFragment,
      );
    });

    test('registers normal_fragment_begin', () {
      expect(
        Fiber3DShaderChunk.chunks['normal_fragment_begin'],
        fiber3dNormalFragmentBegin,
      );
    });

    test('registers normal_pars_fragment', () {
      expect(
        Fiber3DShaderChunk.chunks['normal_pars_fragment'],
        fiber3dNormalParsFragment,
      );
    });

    test('registers roughnessmap_fragment', () {
      expect(
        Fiber3DShaderChunk.chunks['roughnessmap_fragment'],
        fiber3dRoughnessmapFragment,
      );
    });

    test('resolveIncludes replaces a directive with the chunk text', () {
      expect(
        Fiber3DShaderChunk.resolveIncludes('#include <colorspace_fragment>'),
        fiber3dColorspaceFragment,
      );
    });

    test('resolveIncludes keeps the text around a directive', () {
      expect(
        Fiber3DShaderChunk.resolveIncludes(
          'before\n#include <colorspace_fragment>\nafter',
        ),
        'before\n$fiber3dColorspaceFragment\nafter',
      );
    });

    test('resolveIncludes drops the indentation of the directive line', () {
      expect(
        Fiber3DShaderChunk.resolveIncludes('    #include <colorspace_fragment>'),
        fiber3dColorspaceFragment,
      );
    });

    test('resolveIncludes resolves several directives', () {
      expect(
        Fiber3DShaderChunk.resolveIncludes(
          '#include <tonemapping_fragment>\n#include <colorspace_fragment>',
        ),
        '$fiber3dTonemappingFragment\n$fiber3dColorspaceFragment',
      );
    });

    test('resolveIncludes resolves nested includes', () {
      final custom = {
        'outer': 'A\n#include <inner>\nB',
        'inner': 'INNER',
      };

      expect(
        Fiber3DShaderChunk.resolveIncludes('#include <outer>', custom),
        'A\nINNER\nB',
      );
    });

    test('resolveIncludes leaves commented-out and unrelated lines alone', () {
      const source = '// #include <colorspace_fragment>\n#define FOO 1\nvoid main() {}';

      expect(Fiber3DShaderChunk.resolveIncludes(source), source);
    });

    test('resolveIncludes throws for an unknown chunk name', () {
      expect(
        () => Fiber3DShaderChunk.resolveIncludes('#include <nope>'),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message.toString(),
            'message',
            contains('nope'),
          ),
        ),
      );
    });
  });
}