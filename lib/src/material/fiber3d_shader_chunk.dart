import 'shader_chunk/fiber3d_bsdfs.dart';
import 'shader_chunk/fiber3d_colorspace_fragment.dart';
import 'shader_chunk/fiber3d_colorspace_pars_fragment.dart';
import 'shader_chunk/fiber3d_common.dart';
import 'shader_chunk/fiber3d_tonemapping_fragment.dart';
import 'shader_chunk/fiber3d_tonemapping_pars_fragment.dart';

/// Registry of GLSL chunks and the `#include <name>` resolver.
///
/// Ported from three.js's `ShaderChunk` (src/renderers/shaders/ShaderChunk.js)
/// and `resolveIncludes` (src/renderers/webgl/WebGLProgram.js). Only the
/// chunks flutter_fiber has ported are registered; each new chunk is one
/// import and one map entry. The ShaderLib vertex/fragment pairs are ported
/// per material.
class Fiber3DShaderChunk {
  Fiber3DShaderChunk._();

  static const Map<String, String> chunks = {
    'bsdfs': fiber3dBsdfs,
    'colorspace_fragment': fiber3dColorspaceFragment,
    'colorspace_pars_fragment': fiber3dColorspaceParsFragment,
    'common': fiber3dCommon,
    'tonemapping_fragment': fiber3dTonemappingFragment,
    'tonemapping_pars_fragment': fiber3dTonemappingParsFragment,
  };

  // Same pattern as three.js: a line holding only an #include directive.
  static final RegExp _includePattern = RegExp(
    r'^[ \t]*#include +<([\w\d./]+)>',
    multiLine: true,
  );

  /// Replaces every `#include <name>` line in [source] with the chunk of
  /// that name, recursively (chunks may include other chunks).
  ///
  /// [chunkSet] defaults to [chunks]; three.js resolves against a mutable
  /// global, and passing a set here allows the same, plus testing.
  /// Throws [ArgumentError] for an unknown name.
  static String resolveIncludes(
    String source, [
    Map<String, String>? chunkSet,
  ]) {
    final lookup = chunkSet ?? chunks;

    return source.replaceAllMapped(_includePattern, (match) {
      final name = match.group(1)!;
      final chunk = lookup[name];

      if (chunk == null) {
        throw ArgumentError(
          'Fiber3DShaderChunk: can not resolve #include <$name>',
        );
      }

      return resolveIncludes(chunk, lookup);
    });
  }
}