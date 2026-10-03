import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_fiber/src/loader/gltf/fiber3d_glb_container.dart';

/// Builds a minimal valid .glb byte sequence from a JSON string and an
/// optional binary payload, mirroring exactly what a real exporter
/// produces used to test the parser without needing a real file.
Uint8List _buildGlb(String jsonText, [Uint8List? bin]) {
  final jsonBytes = utf8.encode(jsonText);
  final jsonPadded = (jsonBytes.length + 3) & ~3;
  final jsonPadding = jsonPadded - jsonBytes.length;

  final chunks = BytesBuilder();

  // JSON chunk
  final jsonHeader = ByteData(8);
  jsonHeader.setUint32(0, jsonPadded, Endian.little);
  jsonHeader.setUint32(4, 0x4E4F534A, Endian.little);
  chunks.add(jsonHeader.buffer.asUint8List());
  chunks.add(jsonBytes);
  chunks.add(List.filled(jsonPadding, 0x20)); // glTF pads JSON with spaces

  if (bin != null) {
    final binPadded = (bin.length + 3) & ~3;
    final binPadding = binPadded - bin.length;
    final binHeader = ByteData(8);
    binHeader.setUint32(0, binPadded, Endian.little);
    binHeader.setUint32(4, 0x004E4942, Endian.little);
    chunks.add(binHeader.buffer.asUint8List());
    chunks.add(bin);
    chunks.add(List.filled(binPadding, 0));
  }

  final chunkBytes = chunks.toBytes();

  final header = ByteData(12);
  header.setUint32(0, 0x46546C67, Endian.little); // 'glTF'
  header.setUint32(4, 2, Endian.little); // version
  header.setUint32(8, 12 + chunkBytes.length, Endian.little); // total length

  final result = BytesBuilder();
  result.add(header.buffer.asUint8List());
  result.add(chunkBytes);
  return result.toBytes();
}

void main() {
  group('Fiber3DGlbContainer', () {
    test('parses a JSON-only glb (no binary chunk)', () {
      final glb = _buildGlb('{"asset":{"version":"2.0"}}');
      final result = Fiber3DGlbContainer.parse(glb);
      expect(result.json, '{"asset":{"version":"2.0"}}');
      expect(result.binary, isNull);
    });

    test('parses a glb with both JSON and binary chunks', () {
      final bin = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]);
      final glb = _buildGlb('{"asset":{"version":"2.0"}}', bin);
      final result = Fiber3DGlbContainer.parse(glb);
      expect(result.json, '{"asset":{"version":"2.0"}}');
      expect(result.binary, bin);
    });

    test('handles JSON chunk requiring padding', () {
      // 5-char JSON body forces padding to the next 4-byte boundary.
      final glb = _buildGlb('{"a":1}'); // 7 bytes -> pads to 8
      final result = Fiber3DGlbContainer.parse(glb);
      expect(result.json, '{"a":1}');
    });

    test('rejects a file shorter than the header', () {
      expect(
        () => Fiber3DGlbContainer.parse(Uint8List.fromList([1, 2, 3])),
        throwsFormatException,
      );
    });

    test('rejects bad magic', () {
      final glb = _buildGlb('{}');
      glb[0] = 0x00; // corrupt the magic
      expect(() => Fiber3DGlbContainer.parse(glb), throwsFormatException);
    });

    test('rejects an unsupported version', () {
      final glb = _buildGlb('{}');
      final data = ByteData.sublistView(glb);
      data.setUint32(4, 1, Endian.little); // version 1, not 2
      expect(() => Fiber3DGlbContainer.parse(glb), throwsFormatException);
    });

    test('rejects a declared length exceeding actual byte count', () {
      final glb = _buildGlb('{}');
      final data = ByteData.sublistView(glb);
      data.setUint32(8, glb.length + 100, Endian.little);
      expect(() => Fiber3DGlbContainer.parse(glb), throwsFormatException);
    });

    test('rejects a file with no JSON chunk', () {
      final bin = Uint8List.fromList([1, 2, 3, 4]);
      final binHeader = ByteData(8);
      binHeader.setUint32(0, 4, Endian.little);
      binHeader.setUint32(4, 0x004E4942, Endian.little);

      final header = ByteData(12);
      header.setUint32(0, 0x46546C67, Endian.little);
      header.setUint32(4, 2, Endian.little);
      header.setUint32(8, 12 + 8 + 4, Endian.little);

      final glb = BytesBuilder();
      glb.add(header.buffer.asUint8List());
      glb.add(binHeader.buffer.asUint8List());
      glb.add(bin);

      expect(() => Fiber3DGlbContainer.parse(glb.toBytes()), throwsFormatException);
    });
  });
}