import 'dart:typed_data';

/// glTF accessor componentType constants (glTF 2.0 spec).
class Fiber3DGltfComponentType {
  static const int byte = 5120;
  static const int unsignedByte = 5121;
  static const int short = 5122;
  static const int unsignedShort = 5123;
  static const int unsignedInt = 5125;
  static const int float = 5126;
}

/// Decodes glTF accessors into flat Dart lists.
///
/// v1 scope, matching what flutter_fiber's existing geometry pipeline
/// and canvas actually consume: FLOAT data for vertex attributes
/// (POSITION/NORMAL/TEXCOORD_0/COLOR_0 all FLOAT per the accessors
/// this decoder targets), and UNSIGNED_BYTE/UNSIGNED_SHORT/UNSIGNED_INT
/// for indices (the only three componentTypes the glTF spec allows for
/// an indices accessor). Sparse accessors, normalized integer vertex
/// attributes (e.g. quantized BYTE/SHORT positions), and matrix types
/// (MAT2/MAT3/MAT4, used for skinning) are NOT supported flagged with
/// a clear error rather than silently producing wrong data.
class Fiber3DGltfAccessor {
  Fiber3DGltfAccessor._();

  static const Map<String, int> _numComponents = {
    'SCALAR': 1,
    'VEC2': 2,
    'VEC3': 3,
    'VEC4': 4,
    'MAT2': 4,
    'MAT3': 9,
    'MAT4': 16,
  };

  static int _componentByteSize(int componentType) {
    switch (componentType) {
      case Fiber3DGltfComponentType.byte:
      case Fiber3DGltfComponentType.unsignedByte:
        return 1;
      case Fiber3DGltfComponentType.short:
      case Fiber3DGltfComponentType.unsignedShort:
        return 2;
      case Fiber3DGltfComponentType.unsignedInt:
      case Fiber3DGltfComponentType.float:
        return 4;
      default:
        throw FormatException(
          'Fiber3DGltfAccessor: unsupported componentType $componentType',
        );
    }
  }

  /// Decodes a FLOAT vertex-attribute accessor (POSITION, NORMAL,
  /// TEXCOORD_0, or a FLOAT COLOR_0) into a flat list of doubles, one
  /// entry per component per element (e.g. count=3 VEC3 -> 9 doubles).
  ///
  /// [buffers] is every resolved buffer's raw bytes, indexed the same
  /// way the glTF JSON's own `buffers` array is indexed.
  static List<double> decodeFloat({
    required Map<String, dynamic> accessor,
    required List<Map<String, dynamic>> bufferViews,
    required List<Uint8List> buffers,
  }) {
    final componentType = accessor['componentType'] as int;
    if (componentType != Fiber3DGltfComponentType.float) {
      throw FormatException(
        'Fiber3DGltfAccessor: expected FLOAT vertex data, got componentType $componentType '
        '(quantized/normalized integer vertex attributes are not supported)',
      );
    }

    final type = accessor['type'] as String;
    final numComponents = _numComponents[type];
    if (numComponents == null || numComponents > 4) {
      throw FormatException(
        'Fiber3DGltfAccessor: unsupported accessor type "$type" for vertex data '
        '(matrix types are not supported no skinning support)',
      );
    }

    final count = accessor['count'] as int;
    final bufferViewIndex = accessor['bufferView'] as int?;
    if (bufferViewIndex == null) {
      // A bufferView-less accessor means "all zeros" per spec (used for
      // sparse-only accessors, which aren't supported) or genuinely
      // absent data. Either way, return zeros rather than guessing.
      return List<double>.filled(count * numComponents, 0.0);
    }

    final bufferView = bufferViews[bufferViewIndex];
    final bufferIndex = bufferView['buffer'] as int;
    final bufferBytes = buffers[bufferIndex];

    final bufferViewByteOffset = (bufferView['byteOffset'] as int?) ?? 0;
    final accessorByteOffset = (accessor['byteOffset'] as int?) ?? 0;
    final baseOffset = bufferViewByteOffset + accessorByteOffset;

    const componentSize = 4; // FLOAT is always 4 bytes
    final tightStride = componentSize * numComponents;
    final stride = (bufferView['byteStride'] as int?) ?? tightStride;

    final data = ByteData.sublistView(bufferBytes);
    final out = List<double>.filled(count * numComponents, 0.0);

    for (var i = 0; i < count; i++) {
      final elementOffset = baseOffset + i * stride;
      for (var c = 0; c < numComponents; c++) {
        out[i * numComponents + c] = data.getFloat32(
          elementOffset + c * componentSize,
          Endian.little,
        );
      }
    }

    return out;
  }

  /// Decodes an indices accessor (always SCALAR, always an unsigned
  /// integer componentType per spec) into a flat list of ints.
  static List<int> decodeIndices({
    required Map<String, dynamic> accessor,
    required List<Map<String, dynamic>> bufferViews,
    required List<Uint8List> buffers,
  }) {
    final componentType = accessor['componentType'] as int;
    final count = accessor['count'] as int;
    final bufferViewIndex = accessor['bufferView'] as int?;

    if (bufferViewIndex == null) {
      return List<int>.filled(count, 0);
    }

    final bufferView = bufferViews[bufferViewIndex];
    final bufferIndex = bufferView['buffer'] as int;
    final bufferBytes = buffers[bufferIndex];

    final bufferViewByteOffset = (bufferView['byteOffset'] as int?) ?? 0;
    final accessorByteOffset = (accessor['byteOffset'] as int?) ?? 0;
    final baseOffset = bufferViewByteOffset + accessorByteOffset;

    final componentSize = _componentByteSize(componentType);
    final stride = (bufferView['byteStride'] as int?) ?? componentSize;

    final data = ByteData.sublistView(bufferBytes);
    final out = List<int>.filled(count, 0);

    for (var i = 0; i < count; i++) {
      final offset = baseOffset + i * stride;
      switch (componentType) {
        case Fiber3DGltfComponentType.unsignedByte:
          out[i] = data.getUint8(offset);
        case Fiber3DGltfComponentType.unsignedShort:
          out[i] = data.getUint16(offset, Endian.little);
        case Fiber3DGltfComponentType.unsignedInt:
          out[i] = data.getUint32(offset, Endian.little);
        default:
          throw FormatException(
            'Fiber3DGltfAccessor: invalid indices componentType $componentType '
            '(must be UNSIGNED_BYTE, UNSIGNED_SHORT, or UNSIGNED_INT)',
          );
      }
    }

    return out;
  }
}