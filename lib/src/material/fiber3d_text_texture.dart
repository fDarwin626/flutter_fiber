import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import 'fiber3d_texture.dart';

/// Rasterizes a string into a [Fiber3DTexture], usable directly as
/// `Fiber3DStandardMaterial.map` (or any material's map) on any mesh —
/// "text-in-shape" needs no new shape or shader work, only a texture.
///
/// Uses Flutter's own [TextPainter] plus a [ui.PictureRecorder], not a
/// new pub dependency. The result is RGBA8 straight out of
/// `Image.toByteData(format: rawRgba)`, same convention every other
/// texture in the pipeline uses.
class Fiber3DTextTexture {
  Fiber3DTextTexture._();

  /// Renders [text] once and returns a ready [Fiber3DTexture]. For text
  /// that changes over time, call this again and feed the result into
  /// the existing texture's [Fiber3DTexture.setPixels] rather than
  /// swapping the material's map (which would require rebuilding the
  /// mesh's material each change).
  static Future<Fiber3DTexture> render({
    required String text,
    double fontSize = 48,
    Color color = const Color(0xFFFFFFFF),
    Color backgroundColor = const Color(0x00000000),
    String? fontFamily,
    FontWeight fontWeight = FontWeight.normal,
    TextAlign textAlign = TextAlign.center,
    double padding = 16,
    double pixelRatio = 2.0,
  }) async {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize * pixelRatio,
          fontFamily: fontFamily,
          fontWeight: fontWeight,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: textAlign,
    )..layout();

    final scaledPadding = padding * pixelRatio;
    final w = painter.width + scaledPadding * 2;
    final h = painter.height + scaledPadding * 2;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, w, h));

    if (backgroundColor.alpha > 0) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, w, h),
        Paint()..color = backgroundColor,
      );
    }
    painter.paint(canvas, Offset(scaledPadding, scaledPadding));

    final picture = recorder.endRecording();
    final image = await picture.toImage(w.ceil(), h.ceil());
    final byteData = await image.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    );

    if (byteData == null) {
      image.dispose();
      picture.dispose();
      throw StateError('Fiber3DTextTexture: failed to rasterize text');
    }

    final pixels = byteData.buffer.asUint8List();
    final width = image.width;
    final height = image.height;

    image.dispose();
    picture.dispose();

    return Fiber3DTexture.raw(pixels, width, height);
  }
}