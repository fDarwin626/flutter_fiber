import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

/// A 2D image texture, decoded from raw bytes the caller supplies —
/// asset bundle, file, network, in-memory buffer. flutter_fiber doesn't
/// care about the source, only the bytes, per the deliberate choice not
/// to bundle any image-loading dependency of its own.
///
/// Decoding uses Flutter's own built-in `dart:ui` image codec no new
/// package dependency and is asynchronous even for already-in-memory
/// bytes, so a texture is not immediately usable after construction.
/// Check [isReady] (or await [ensureDecoded]) before a canvas attempts
/// to upload/bind it.
///
/// Holds decoded RGBA8 pixel data and dimensions only. Actual GL texture
/// creation/upload happens in Fiber3DCanvas once decoding completes
/// the same lazy, cached-on-first-use pattern the canvas already applies
/// to per-mesh GPU buffers, not duplicated here.
class Fiber3DTexture {
  final Uint8List sourceBytes;

  Uint8List? _pixels;
  int? _width;
  int? _height;
  Future<void>? _decodeFuture;

  Fiber3DTexture(this.sourceBytes);

  bool get isReady => _pixels != null;
  Uint8List? get pixels => _pixels;
  int? get width => _width;
  int? get height => _height;

  /// Decodes [sourceBytes] into raw RGBA8 pixel data. Safe to call more
  /// than once later calls return the same in-flight/completed future
  /// rather than re-decoding.
  Future<void> ensureDecoded() {
    return _decodeFuture ??= _decode();
  }

  Future<void> _decode() async {
    final codec = await ui.instantiateImageCodec(sourceBytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    final byteData = await image.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    );
    if (byteData == null) {
      throw StateError('Fiber3DTexture: failed to decode image bytes');
    }

    // asUint8List() is a copy-free view over byteData's own buffer, not
    // over the ui.Image itself, so it stays valid after image.dispose().
    _pixels = byteData.buffer.asUint8List();
    _width = image.width;
    _height = image.height;

    image.dispose();
    codec.dispose();
  }
}