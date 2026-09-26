import 'shader_chunk/fiber3d_begin_vertex.dart';
import 'shader_chunk/fiber3d_beginnormal_vertex.dart';
import 'shader_chunk/fiber3d_bsdfs.dart';
import 'shader_chunk/fiber3d_defaultnormal_vertex.dart';
import 'shader_chunk/fiber3d_gradientmap_pars_fragment.dart';
import 'shader_chunk/fiber3d_normal_pars_vertex.dart';
import 'shader_chunk/fiber3d_normal_vertex.dart';
import 'shader_chunk/fiber3d_project_vertex.dart';
import 'shader_chunk/fiber3d_colorspace_fragment.dart';
import 'shader_chunk/fiber3d_colorspace_pars_fragment.dart';
import 'shader_chunk/fiber3d_common.dart';
import 'shader_chunk/fiber3d_lights_fragment_begin.dart';
import 'shader_chunk/fiber3d_lights_fragment_end.dart';
import 'shader_chunk/fiber3d_lights_fragment_maps.dart';
import 'shader_chunk/fiber3d_lights_lambert_fragment.dart';
import 'shader_chunk/fiber3d_lights_lambert_pars_fragment.dart';
import 'shader_chunk/fiber3d_lights_pars_begin.dart';
import 'shader_chunk/fiber3d_lights_phong_fragment.dart';
import 'shader_chunk/fiber3d_lights_phong_pars_fragment.dart';
import 'shader_chunk/fiber3d_lights_physical_fragment.dart';
import 'shader_chunk/fiber3d_lights_toon_fragment.dart';
import 'shader_chunk/fiber3d_lights_toon_pars_fragment.dart';
import 'shader_chunk/fiber3d_map_pars_fragment.dart';
import 'shader_chunk/fiber3d_map_fragment.dart';
import 'shader_chunk/fiber3d_lights_physical_pars_fragment.dart';
import 'shader_chunk/fiber3d_metalnessmap_fragment.dart';
import 'shader_chunk/fiber3d_normal_fragment_begin.dart';
import 'shader_chunk/fiber3d_normal_pars_fragment.dart';
import 'shader_chunk/fiber3d_opaque_fragment.dart';
import 'shader_chunk/fiber3d_roughnessmap_fragment.dart';
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
    'begin_vertex': fiber3dBeginVertex,
    'beginnormal_vertex': fiber3dBeginnormalVertex,
    'bsdfs': fiber3dBsdfs,
    'defaultnormal_vertex': fiber3dDefaultnormalVertex,
    'gradientmap_pars_fragment': fiber3dGradientmapParsFragment,    
    'normal_pars_vertex': fiber3dNormalParsVertex,
    'normal_vertex': fiber3dNormalVertex,
    'project_vertex': fiber3dProjectVertex,
    'colorspace_fragment': fiber3dColorspaceFragment,
    'colorspace_pars_fragment': fiber3dColorspaceParsFragment,
    'common': fiber3dCommon,
    'lights_fragment_begin': fiber3dLightsFragmentBegin,
    'lights_fragment_end': fiber3dLightsFragmentEnd,
    'lights_fragment_maps': fiber3dLightsFragmentMaps,
    'lights_lambert_fragment': fiber3dLightsLambertFragment,
    'lights_lambert_pars_fragment': fiber3dLightsLambertParsFragment,
    'lights_pars_begin': fiber3dLightsParsBegin,
    'lights_phong_fragment': fiber3dLightsPhongFragment,
    'lights_phong_pars_fragment': fiber3dLightsPhongParsFragment,    
    'lights_physical_fragment': fiber3dLightsPhysicalFragment,
    'lights_physical_pars_fragment': fiber3dLightsPhysicalParsFragment,    
    'lights_toon_fragment': fiber3dLightsToonFragment,
    'lights_toon_pars_fragment': fiber3dLightsToonParsFragment,
    'map_pars_fragment': fiber3dMapParsFragment,
    'map_fragment': fiber3dMapFragment,
    'metalnessmap_fragment': fiber3dMetalnessmapFragment,    
    'normal_fragment_begin': fiber3dNormalFragmentBegin,
    'normal_pars_fragment': fiber3dNormalParsFragment,
    'opaque_fragment': fiber3dOpaqueFragment,
    'roughnessmap_fragment': fiber3dRoughnessmapFragment,
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