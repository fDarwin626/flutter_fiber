import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'fiber3d_texture.dart';

/// Captures [child] -- any Flutter widget -- off-screen, at [fps], into
/// [texture] via Fiber3DTexture.setPixels, so live Flutter content (a
/// Lottie animation, a video, an animated counter, anything) can be used
/// as `Fiber3DStandardMaterial.map` on a mesh's UV face.
///
/// This is the general mechanism behind "Lottie-in-shape". It has no
/// dependency on the `lottie` package or any other -- [child] can be a
/// Lottie widget, but this class never imports `lottie`, so
/// flutter_fiber stays free of that dependency; the caller's own app
/// brings whichever package produces [child]. For static (non-changing)
/// text, prefer Fiber3DTextTexture instead -- one rasterize, no
/// per-frame capture cost.
///
/// Must be a direct child of a Stack (uses Positioned to keep [child]
/// mounted -- and therefore actually painting -- without it being
/// visible on screen; Offstage would skip painting entirely and leave
/// nothing for RepaintBoundary.toImage() to capture).
class Fiber3DWidgetTexture extends StatefulWidget {
  final Widget child;
  final Fiber3DTexture texture;

  /// Render size of the off-screen widget, in logical pixels. Larger =
  /// sharper texture, more capture cost per frame.
  final double width;
  final double height;

  /// Capture rate, in frames per second. Independent of [child]'s own
  /// animation rate -- this just samples whatever [child] currently
  /// looks like, this often.
  final double fps;

  const Fiber3DWidgetTexture({
    super.key,
    required this.child,
    required this.texture,
    this.width = 256,
    this.height = 256,
    this.fps = 30,
  });

  @override
  State<Fiber3DWidgetTexture> createState() => _Fiber3DWidgetTextureState();
}

class _Fiber3DWidgetTextureState extends State<Fiber3DWidgetTexture>
    with SingleTickerProviderStateMixin {
  final _boundaryKey = GlobalKey();
  late final Ticker _ticker;
  Duration _lastCapture = Duration.zero;
  bool _capturing = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    final interval = Duration(microseconds: (1e6 / widget.fps).round());
    if (elapsed - _lastCapture < interval) return;
    if (_capturing) return;

    _lastCapture = elapsed;
    _capturing = true;

    // Deferred to after this frame's build/layout/paint -- capturing
    // synchronously here risks reading the render tree before [child]
    // has actually repainted for this tick.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _captureFrame().whenComplete(() => _capturing = false);
    });
  }

  Future<void> _captureFrame() async {
    final renderObject = _boundaryKey.currentContext?.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) return;
    if (renderObject.debugNeedsPaint) return;

    final image = await renderObject.toImage();
    final byteData = await image.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    );
    final width = image.width;
    final height = image.height;
    image.dispose();
    if (byteData == null) return;

    widget.texture.setPixels(byteData.buffer.asUint8List(), width, height);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: -100000,
      top: -100000,
      child: RepaintBoundary(
        key: _boundaryKey,
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: widget.child,
        ),
      ),
    );
  }
}