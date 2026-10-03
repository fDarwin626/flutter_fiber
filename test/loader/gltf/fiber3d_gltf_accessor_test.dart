import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_fiber/src/loader/gltf/fiber3d_gltf_accessor.dart';

Uint8List _floatBuffer(List<double> values) {
  final data = ByteData(values.length * 4);
  for (var i = 0; i < values.length; i++) {
    data.setFloat32(i * 4, values[i], Endian.little);
  }
  return data.buffer.asUint8List();
}

void main() {
  group('Fiber3DGltfAccessor.decodeFloat', () {
    test('decodes a tightly packed VEC3 accessor (e.g. POSITION)', () {
      final buffer = _floatBuffer([
        1.0, 2.0, 3.0, // vertex 0
        4.0, 5.0, 6.0, // vertex 1
      ]);
      final accessor = {
        'bufferView': 0,
        'componentType': Fiber3DGltfComponentType.float,
        'count': 2,
        'type': 'VEC3',
      };
      final bufferView = {'buffer': 0, 'byteOffset': 0, 'byteLength': 24};

      final result = Fiber3DGltfAccessor.decodeFloat(
        accessor: accessor,
        bufferViews: [bufferView],
        buffers: [buffer],
      );

      expect(result, [1.0, 2.0, 3.0, 4.0, 5.0, 6.0]);
    });

    test('respects accessor.byteOffset within a shared bufferView', () {
      final buffer = _floatBuffer([
        99.0, 99.0, // padding before the accessor's own data starts
        1.0, 2.0,
      ]);
      final accessor = {
        'bufferView': 0,
        'byteOffset': 8, // skip the first two floats
        'componentType': Fiber3DGltfComponentType.float,
        'count': 1,
        'type': 'VEC2',
      };
      final bufferView = {'buffer': 0, 'byteOffset': 0, 'byteLength': 16};

      final result = Fiber3DGltfAccessor.decodeFloat(
        accessor: accessor,
        bufferViews: [bufferView],
        buffers: [buffer],
      );

      expect(result, [1.0, 2.0]);
    });

    test('respects bufferView.byteOffset', () {
      final buffer = _floatBuffer([
        99.0, 99.0, 99.0, // an earlier, unrelated bufferView's data
        1.0, 2.0, 3.0,
      ]);
      final accessor = {
        'bufferView': 0,
        'componentType': Fiber3DGltfComponentType.float,
        'count': 1,
        'type': 'VEC3',
      };
      final bufferView = {'buffer': 0, 'byteOffset': 12, 'byteLength': 12};

      final result = Fiber3DGltfAccessor.decodeFloat(
        accessor: accessor,
        bufferViews: [bufferView],
        buffers: [buffer],
      );

      expect(result, [1.0, 2.0, 3.0]);
    });

    test('respects byteStride for interleaved attributes', () {
      final buffer = _floatBuffer([
        1.0, 2.0, 3.0, 0.0, 0.0, 0.0, // vertex 0: pos, other
        4.0, 5.0, 6.0, 0.0, 0.0, 0.0, // vertex 1: pos, other
      ]);
      final accessor = {
        'bufferView': 0,
        'componentType': Fiber3DGltfComponentType.float,
        'count': 2,
        'type': 'VEC3',
      };
      final bufferView = {
        'buffer': 0,
        'byteOffset': 0,
        'byteLength': 48,
        'byteStride': 24,
      };

      final result = Fiber3DGltfAccessor.decodeFloat(
        accessor: accessor,
        bufferViews: [bufferView],
        buffers: [buffer],
      );

      expect(result, [1.0, 2.0, 3.0, 4.0, 5.0, 6.0]);
    });

    test('returns zeros for a bufferView-less accessor', () {
      final accessor = {
        'componentType': Fiber3DGltfComponentType.float,
        'count': 2,
        'type': 'VEC2',
      };

      final result = Fiber3DGltfAccessor.decodeFloat(
        accessor: accessor,
        bufferViews: const [],
        buffers: const [],
      );

      expect(result, [0.0, 0.0, 0.0, 0.0]);
    });

    test('rejects a non-FLOAT componentType', () {
      final accessor = {
        'bufferView': 0,
        'componentType': Fiber3DGltfComponentType.unsignedShort,
        'count': 1,
        'type': 'VEC3',
      };
      expect(
        () => Fiber3DGltfAccessor.decodeFloat(
          accessor: accessor,
          bufferViews: [
            {'buffer': 0, 'byteLength': 6},
          ],
          buffers: [Uint8List(6)],
        ),
        throwsFormatException,
      );
    });

    test('rejects a matrix type', () {
      final accessor = {
        'bufferView': 0,
        'componentType': Fiber3DGltfComponentType.float,
        'count': 1,
        'type': 'MAT4',
      };
      expect(
        () => Fiber3DGltfAccessor.decodeFloat(
          accessor: accessor,
          bufferViews: [
            {'buffer': 0, 'byteLength': 64},
          ],
          buffers: [Uint8List(64)],
        ),
        throwsFormatException,
      );
    });
  });

  group('Fiber3DGltfAccessor.decodeIndices', () {
    test('decodes UNSIGNED_SHORT indices', () {
      final data = ByteData(6);
      data.setUint16(0, 0, Endian.little);
      data.setUint16(2, 1, Endian.little);
      data.setUint16(4, 2, Endian.little);
      final buffer = data.buffer.asUint8List();

      final accessor = {
        'bufferView': 0,
        'componentType': Fiber3DGltfComponentType.unsignedShort,
        'count': 3,
      };
      final bufferView = {'buffer': 0, 'byteOffset': 0, 'byteLength': 6};

      final result = Fiber3DGltfAccessor.decodeIndices(
        accessor: accessor,
        bufferViews: [bufferView],
        buffers: [buffer],
      );

      expect(result, [0, 1, 2]);
    });

    test('decodes UNSIGNED_BYTE indices', () {
      final buffer = Uint8List.fromList([0, 2, 1]);
      final accessor = {
        'bufferView': 0,
        'componentType': Fiber3DGltfComponentType.unsignedByte,
        'count': 3,
      };
      final bufferView = {'buffer': 0, 'byteOffset': 0, 'byteLength': 3};

      final result = Fiber3DGltfAccessor.decodeIndices(
        accessor: accessor,
        bufferViews: [bufferView],
        buffers: [buffer],
      );

      expect(result, [0, 2, 1]);
    });

    test('decodes UNSIGNED_INT indices', () {
      final data = ByteData(8);
      data.setUint32(0, 70000, Endian.little); // exceeds 16-bit range
      data.setUint32(4, 1, Endian.little);
      final buffer = data.buffer.asUint8List();

      final accessor = {
        'bufferView': 0,
        'componentType': Fiber3DGltfComponentType.unsignedInt,
        'count': 2,
      };
      final bufferView = {'buffer': 0, 'byteOffset': 0, 'byteLength': 8};

      final result = Fiber3DGltfAccessor.decodeIndices(
        accessor: accessor,
        bufferViews: [bufferView],
        buffers: [buffer],
      );

      expect(result, [70000, 1]);
    });

    test('rejects a signed componentType for indices', () {
      final accessor = {
        'bufferView': 0,
        'componentType': Fiber3DGltfComponentType.short,
        'count': 1,
      };
      expect(
        () => Fiber3DGltfAccessor.decodeIndices(
          accessor: accessor,
          bufferViews: [
            {'buffer': 0, 'byteLength': 2},
          ],
          buffers: [Uint8List(2)],
        ),
        throwsFormatException,
      );
    });
  });
}