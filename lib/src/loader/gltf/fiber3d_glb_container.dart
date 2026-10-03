import 'dart:convert';
import 'dart:typed_data';

/// The two chunks a parsed .glb file breaks down into: the JSON chunk
/// (always present, decoded to a String) and the binary chunk (present
/// whenever the model's buffers aren't fully embedded as base64 data
/// URIs in the JSON itself).
class Fiber3DGlbChunks {
  final String json;
  final Uint8List? binary;

  const Fiber3DGlbChunks({required this.json, this.binary});
}

/// Parses the binary .glb container format (glTF 2.0 spec, chapter
/// "Binary glTF Layout") into its raw JSON text and binary chunk.
///
/// Layout: a 12-byte header (magic 'glTF', version, total length as
/// little-endian uint32s), followed by one or more chunks, each a
/// (chunkLength, chunkType, chunkData) triple, chunkData padded to a
/// 4-byte boundary. Only the first JSON chunk and first BIN chunk are
/// used the spec permits multiple chunks but no glTF exporter in
/// practice emits more than one of each.
class Fiber3DGlbContainer {
  Fiber3DGlbContainer._();

  static const int _magic = 0x46546C67; // 'glTF', little-endian
  static const int _chunkTypeJson = 0x4E4F534A; // 'JSON', little-endian
  static const int _chunkTypeBin = 0x004E4942; // 'BIN\0', little-endian

  /// Throws [FormatException] if [bytes] isn't a valid .glb container
  /// (wrong magic, unsupported version, or no JSON chunk found).
  static Fiber3DGlbChunks parse(Uint8List bytes) {
    if (bytes.length < 12) {
      throw const FormatException('Fiber3DGlbContainer: file too short to be a .glb (< 12 bytes)');
    }

    final data = ByteData.sublistView(bytes);

    final magic = data.getUint32(0, Endian.little);
    if (magic != _magic) {
      throw FormatException(
        'Fiber3DGlbContainer: not a .glb file (bad magic 0x${magic.toRadixString(16)})',
      );
    }

    final version = data.getUint32(4, Endian.little);
    if (version != 2) {
      throw FormatException(
        'Fiber3DGlbContainer: unsupported glTF binary version $version (only version 2 is supported)',
      );
    }

    final totalLength = data.getUint32(8, Endian.little);
    if (totalLength > bytes.length) {
      throw FormatException(
        'Fiber3DGlbContainer: declared length $totalLength exceeds actual byte count ${bytes.length}',
      );
    }

    String? jsonText;
    Uint8List? binChunk;

    var offset = 12;
    while (offset + 8 <= totalLength) {
      final chunkLength = data.getUint32(offset, Endian.little);
      final chunkType = data.getUint32(offset + 4, Endian.little);
      final chunkStart = offset + 8;
      final chunkEnd = chunkStart + chunkLength;

      if (chunkEnd > totalLength) {
        throw FormatException(
          'Fiber3DGlbContainer: chunk at offset $offset overruns declared file length',
        );
      }

      if (chunkType == _chunkTypeJson && jsonText == null) {
        jsonText = utf8.decode(bytes.sublist(chunkStart, chunkEnd)).trimRight();
      } else if (chunkType == _chunkTypeBin && binChunk == null) {
        binChunk = Uint8List.sublistView(bytes, chunkStart, chunkEnd);
      }

      // Chunks are padded to a 4-byte boundary; advance past the padding
      // too, not just the declared chunkLength.
      final padded = (chunkLength + 3) & ~3;
      offset = offset + 8 + padded;
    }

    if (jsonText == null) {
      throw const FormatException('Fiber3DGlbContainer: no JSON chunk found');
    }

    return Fiber3DGlbChunks(json: jsonText, binary: binChunk);
  }
}