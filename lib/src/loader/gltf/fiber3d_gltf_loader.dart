import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import '../../material/fiber3d_texture.dart';
import 'fiber3d_glb_container.dart';
import 'fiber3d_gltf_accessor.dart';
import 'fiber3d_gltf_material.dart';
import 'fiber3d_gltf_scene.dart';

class Fiber3DGltfLoader {
  Fiber3DGltfLoader._();

  static Future<Fiber3DGltfScene> loadGlb(Uint8List bytes) async {
    final chunks = Fiber3DGlbContainer.parse(bytes);
    final json = jsonDecode(chunks.json) as Map<String, dynamic>;
    return _buildScene(json, chunks.binary);
  }

  /// For a .gltf file whose buffers/images are ALL base64 data URIs
  /// (jsonText is the file's raw text content, already read by the
  /// caller this class does no file I/O of its own).
  static Future<Fiber3DGltfScene> loadEmbeddedGltf(String jsonText) async {
    final json = jsonDecode(jsonText) as Map<String, dynamic>;
    return _buildScene(json, null);
  }

  static Future<Fiber3DGltfScene> _buildScene(
    Map<String, dynamic> json,
    Uint8List? glbBinary,
  ) async {
    final buffers = _resolveBuffers(json, glbBinary);

    final bufferViews =
        (json['bufferViews'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    final accessors =
        (json['accessors'] as List?)?.cast<Map<String, dynamic>>() ?? const [];

    final textures = await _resolveTextures(json, bufferViews, buffers);

    final materialsJson =
        (json['materials'] as List?)?.cast<Map<String, dynamic>>() ?? const [];

    final meshesJson =
        (json['meshes'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    final decodedMeshes = meshesJson
        .map((m) => _decodeMeshPrimitives(m, accessors, bufferViews, buffers, materialsJson, textures))
        .toList();

    final nodesJson =
        (json['nodes'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    final nodeCache = <int, Fiber3DGltfNode>{};

    Fiber3DGltfNode buildNode(int index) {
      final cached = nodeCache[index];
      if (cached != null) return cached;

      final nodeJson = nodesJson[index];
      final trs = _resolveLocalTransform(nodeJson);

      final meshIdx = nodeJson['mesh'] as int?;
      final primitives =
          meshIdx != null && meshIdx < decodedMeshes.length ? decodedMeshes[meshIdx] : const <Fiber3DGltfPrimitive>[];

      final node = Fiber3DGltfNode(
        name: nodeJson['name'] as String?,
        posX: trs[0], posY: trs[1], posZ: trs[2],
        rotX: trs[3], rotY: trs[4], rotZ: trs[5],
        scaleX: trs[6], scaleY: trs[7], scaleZ: trs[8],
        primitives: primitives,
      );
      nodeCache[index] = node;

      final childIndices = (nodeJson['children'] as List?)?.cast<int>() ?? const [];
      for (final childIdx in childIndices) {
        node.children.add(buildNode(childIdx));
      }
      return node;
    }

    final scenesJson =
        (json['scenes'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    final sceneIdx = (json['scene'] as int?) ?? 0;

    final List<int> rootIndices;
    if (scenesJson.isNotEmpty && sceneIdx < scenesJson.length) {
      rootIndices = (scenesJson[sceneIdx]['nodes'] as List?)?.cast<int>() ?? const [];
    } else {
      // No scenes array (unusual but spec-tolerant) -- treat every node
      // as a root rather than producing an empty scene.
      rootIndices = List<int>.generate(nodesJson.length, (i) => i);
    }

    return Fiber3DGltfScene(rootIndices.map(buildNode).toList());
  }

  static List<Uint8List> _resolveBuffers(Map<String, dynamic> json, Uint8List? glbBinary) {
    final buffersJson =
        (json['buffers'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    final buffers = <Uint8List>[];

    for (var i = 0; i < buffersJson.length; i++) {
      final uri = buffersJson[i]['uri'] as String?;
      if (uri == null) {
        if (glbBinary == null) {
          throw FormatException(
            'Fiber3DGltfLoader: buffer $i has no uri and no GLB binary chunk is present',
          );
        }
        buffers.add(glbBinary);
      } else if (uri.startsWith('data:')) {
        buffers.add(base64Decode(uri.substring(uri.indexOf(',') + 1)));
      } else {
        throw FormatException(
          'Fiber3DGltfLoader: external buffer URIs are not supported (buffer $i: "$uri") '
          '-- only .glb and fully embedded (data-URI) .gltf are supported',
        );
      }
    }
    return buffers;
  }

  static Future<List<Fiber3DTexture>> _resolveTextures(
    Map<String, dynamic> json,
    List<Map<String, dynamic>> bufferViews,
    List<Uint8List> buffers,
  ) async {
    final imagesJson =
        (json['images'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    final decodedImages = <Fiber3DTexture>[];

    for (final imgJson in imagesJson) {
      final uri = imgJson['uri'] as String?;
      Uint8List imgBytes;

      if (uri != null) {
        if (!uri.startsWith('data:')) {
          throw FormatException(
            'Fiber3DGltfLoader: external image URIs are not supported ("$uri")',
          );
        }
        imgBytes = base64Decode(uri.substring(uri.indexOf(',') + 1));
      } else {
        final bvIndex = imgJson['bufferView'] as int?;
        if (bvIndex == null) {
          throw const FormatException(
            'Fiber3DGltfLoader: image has neither uri nor bufferView',
          );
        }
        final bv = bufferViews[bvIndex];
        final buf = buffers[bv['buffer'] as int];
        final offset = (bv['byteOffset'] as int?) ?? 0;
        final length = bv['byteLength'] as int;
        imgBytes = Uint8List.sublistView(buf, offset, offset + length);
      }

      final tex = Fiber3DTexture(imgBytes);
      await tex.ensureDecoded();
      decodedImages.add(tex);
    }

    final texturesJson =
        (json['textures'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    final textures = <Fiber3DTexture>[];
    for (final texJson in texturesJson) {
      final sourceIndex = texJson['source'] as int?;
      if (sourceIndex != null && sourceIndex < decodedImages.length) {
        textures.add(decodedImages[sourceIndex]);
      }
    }
    return textures;
  }

  static List<Fiber3DGltfPrimitive> _decodeMeshPrimitives(
    Map<String, dynamic> meshJson,
    List<Map<String, dynamic>> accessors,
    List<Map<String, dynamic>> bufferViews,
    List<Uint8List> buffers,
    List<Map<String, dynamic>> materialsJson,
    List<Fiber3DTexture> textures,
  ) {
    final primitivesJson =
        (meshJson['primitives'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    final primitives = <Fiber3DGltfPrimitive>[];

    for (final primJson in primitivesJson) {
      final mode = (primJson['mode'] as int?) ?? 4;
      if (mode != 4) {
        // Only TRIANGLES supported -- skip LINES/POINTS/STRIP/FAN rather
        // than guess a conversion.
        continue;
      }

      final attrs = (primJson['attributes'] as Map).cast<String, dynamic>();
      final posAccessorIdx = attrs['POSITION'] as int?;
      if (posAccessorIdx == null) continue; // no positions, nothing to draw

      final positions = Fiber3DGltfAccessor.decodeFloat(
        accessor: accessors[posAccessorIdx],
        bufferViews: bufferViews,
        buffers: buffers,
      );

      final normAccessorIdx = attrs['NORMAL'] as int?;
      final normals = normAccessorIdx != null
          ? Fiber3DGltfAccessor.decodeFloat(
              accessor: accessors[normAccessorIdx],
              bufferViews: bufferViews,
              buffers: buffers,
            )
          : List<double>.filled(positions.length, 0.0);

      final uvAccessorIdx = attrs['TEXCOORD_0'] as int?;
      final uvs = uvAccessorIdx != null
          ? Fiber3DGltfAccessor.decodeFloat(
              accessor: accessors[uvAccessorIdx],
              bufferViews: bufferViews,
              buffers: buffers,
            )
          : List<double>.filled((positions.length ~/ 3) * 2, 0.0);

      final colors = _decodeColors(attrs['COLOR_0'] as int?, accessors, bufferViews, buffers);

      final indicesAccessorIdx = primJson['indices'] as int?;
      final indices = indicesAccessorIdx != null
          ? Fiber3DGltfAccessor.decodeIndices(
              accessor: accessors[indicesAccessorIdx],
              bufferViews: bufferViews,
              buffers: buffers,
            )
          : List<int>.generate(positions.length ~/ 3, (i) => i);

      final maxIndex = indices.isEmpty ? 0 : indices.reduce(math.max);
      if (maxIndex > 65535) {
        throw FormatException(
          'Fiber3DGltfLoader: primitive has a vertex index of $maxIndex, exceeding '
          'the 16-bit index limit Fiber3DCanvas currently supports (Uint16Array)',
        );
      }

      final materialIdx = primJson['material'] as int?;
      final materialJson = materialIdx != null && materialIdx < materialsJson.length
          ? materialsJson[materialIdx]
          : null;
      final material = Fiber3DGltfMaterial.build(materialJson: materialJson, textures: textures);

      primitives.add(
        Fiber3DGltfPrimitive(
          positions: positions,
          normals: normals,
          uvs: uvs,
          colors: colors,
          indices: indices,
          material: material,
        ),
      );
    }

    return primitives;
  }

  static List<double>? _decodeColors(
    int? colorAccessorIdx,
    List<Map<String, dynamic>> accessors,
    List<Map<String, dynamic>> bufferViews,
    List<Uint8List> buffers,
  ) {
    if (colorAccessorIdx == null) return null;
    final colorAccessor = accessors[colorAccessorIdx];

    // Only FLOAT COLOR_0 is supported -- normalized UBYTE/USHORT color
    // data is left out entirely (mesh just renders without vertex
    // colors) rather than guessing the normalization math.
    if (colorAccessor['componentType'] != Fiber3DGltfComponentType.float) {
      return null;
    }

    final raw = Fiber3DGltfAccessor.decodeFloat(
      accessor: colorAccessor,
      bufferViews: bufferViews,
      buffers: buffers,
    );

    if (colorAccessor['type'] == 'VEC4') {
      // Drop alpha -- flutter_fiber's vertex-color pipeline is RGB only.
      final rgb = <double>[];
      for (var i = 0; i < raw.length; i += 4) {
        rgb.addAll([raw[i], raw[i + 1], raw[i + 2]]);
      }
      return rgb;
    }
    return raw;
  }

  /// Returns [posX, posY, posZ, rotX, rotY, rotZ, scaleX, scaleY, scaleZ]
  /// -- rotation already converted to Euler XYZ (radians), since that's
  /// the only confirmed write path to a Fiber3DObject's rotation
  /// (transform.rotation.x/y/z, same as every other onFrame callback in
  /// this codebase already uses).
  static List<double> _resolveLocalTransform(Map<String, dynamic> nodeJson) {
    if (nodeJson.containsKey('matrix')) {
      final m = (nodeJson['matrix'] as List).map((e) => (e as num).toDouble()).toList();
      return _decomposeMatrix(m);
    }

    final t = (nodeJson['translation'] as List?)?.map((e) => (e as num).toDouble()).toList() ??
        const [0.0, 0.0, 0.0];
    final s = (nodeJson['scale'] as List?)?.map((e) => (e as num).toDouble()).toList() ??
        const [1.0, 1.0, 1.0];
    final q = (nodeJson['rotation'] as List?)?.map((e) => (e as num).toDouble()).toList() ??
        const [0.0, 0.0, 0.0, 1.0];

    final euler = _quaternionToEulerXYZ(q[0], q[1], q[2], q[3]);
    return [t[0], t[1], t[2], euler[0], euler[1], euler[2], s[0], s[1], s[2]];
  }

  /// Extracts XYZ-order Euler angles from a column-major 3x3 rotation
  /// matrix given as the 9 values [m11,m21,m31,m12,m22,m32,m13,m23,m33]
  /// (i.e. column0, column1, column2) -- the exact same formula already
  /// used and proven correct in fiber3d_object.dart's
  /// _updateRotationFromQuaternion, applied here to matrices this loader
  /// builds itself rather than Fiber3DMatrix4's internals.
  static List<double> _extractEulerXYZ(List<double> col0, List<double> col1, List<double> col2) {
    final m11 = col0[0], m13 = col2[0];
    final m22 = col1[1], m23 = col2[1];
    final m32 = col1[2], m33 = col2[2];
    final m12 = col1[0];

    final ey = math.asin(m13.clamp(-1.0, 1.0));
    double ex, ez;
    if (m13.abs() < 0.9999999) {
      ex = math.atan2(-m23, m33);
      ez = math.atan2(-m12, m11);
    } else {
      ex = math.atan2(m32, m22);
      ez = 0.0;
    }
    return [ex, ey, ez];
  }

  static List<double> _quaternionToEulerXYZ(double x, double y, double z, double w) {
    // Standard unit-quaternion-to-rotation-matrix formula, laid out as
    // the same three columns _extractEulerXYZ expects.
    final col0 = [1 - 2 * (y * y + z * z), 2 * (x * y + w * z), 2 * (x * z - w * y)];
    final col1 = [2 * (x * y - w * z), 1 - 2 * (x * x + z * z), 2 * (y * z + w * x)];
    final col2 = [2 * (x * z + w * y), 2 * (y * z - w * x), 1 - 2 * (x * x + y * y)];
    return _extractEulerXYZ(col0, col1, col2);
  }

  /// Decomposes a glTF node's column-major 4x4 matrix (16 values) into
  /// translation, Euler rotation, and scale. Negative/mirrored scale
  /// (a negative determinant) is not specially handled -- rare in
  /// practice, and silently taking the absolute scale magnitude is a
  /// safe, documented simplification rather than a silent wrong answer.
  static List<double> _decomposeMatrix(List<double> m) {
    final sx = math.sqrt(m[0] * m[0] + m[1] * m[1] + m[2] * m[2]);
    final sy = math.sqrt(m[4] * m[4] + m[5] * m[5] + m[6] * m[6]);
    final sz = math.sqrt(m[8] * m[8] + m[9] * m[9] + m[10] * m[10]);

    final col0 = sx > 0 ? [m[0] / sx, m[1] / sx, m[2] / sx] : [1.0, 0.0, 0.0];
    final col1 = sy > 0 ? [m[4] / sy, m[5] / sy, m[6] / sy] : [0.0, 1.0, 0.0];
    final col2 = sz > 0 ? [m[8] / sz, m[9] / sz, m[10] / sz] : [0.0, 0.0, 1.0];

    final euler = _extractEulerXYZ(col0, col1, col2);
    return [m[12], m[13], m[14], euler[0], euler[1], euler[2], sx, sy, sz];
  }
}