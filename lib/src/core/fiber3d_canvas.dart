import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import '../camera/fiber3d_camera.dart';
import '../camera/fiber3d_orbit_controls.dart';
import 'fiber3d_vector3.dart';


/// Signature for a per-frame callback registered with [Fiber3DCanvas].
///
/// [elapsed] is the total time since the canvas's ticker started.
/// [delta] is the time since the previous frame.
typedef Fiber3DFrameCallback = void Function(Duration elapsed, Duration delta);

/// A mesh registered for hit-testing (tap/pan). Coarse bounding-sphere
class _Hittable {
  final Fiber3DVector3 Function() getPosition;
  final double radius;
  final VoidCallback? onTap;
  final void Function(Offset delta)? onPan;
  final void Function(double scale)? onPinch;

  _Hittable({
    required this.getPosition,
    required this.radius,
    this.onTap,
    this.onPan,
    this.onPinch,
  });
}
class Fiber3DCanvas extends StatefulWidget {
  final List<Widget> children;
  final Fiber3DCamera camera;
  final bool orbitEnabled;

  Fiber3DCanvas({
    super.key,
    this.children = const [],
    Fiber3DCamera? camera,
    this.orbitEnabled = false,
  }) : camera = camera ?? Fiber3DCamera();

  @override
  State<Fiber3DCanvas> createState() => Fiber3DCanvasState();
}

class Fiber3DCanvasState extends State<Fiber3DCanvas>
    with SingleTickerProviderStateMixin {
  final Set<Fiber3DFrameCallback> _frameCallbacks = {};
  final Set<_Hittable> _hittables = {};
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;

  late Fiber3DCamera _camera;
  Fiber3DOrbitControls? _orbitControls;
  bool _orbiting = false;

  /// The camera currently in effect — reflects live orbit/zoom state when
  /// orbitEnabled is true, otherwise just widget.camera.
  Fiber3DCamera get camera => _camera;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
    _camera = widget.camera;
    if (widget.orbitEnabled) {
      _orbitControls = Fiber3DOrbitControls(camera: widget.camera);
    }
  }
  void _onTick(Duration elapsed) {
    final delta = elapsed - _lastElapsed;
    _lastElapsed = elapsed;

    // Snapshot to avoid concurrent-modification if a callback registers
    // or unregisters another callback mid-tick.
    for (final callback in List<Fiber3DFrameCallback>.from(_frameCallbacks)) {
      callback(elapsed, delta);
    }
  }

  VoidCallback registerFrameCallback(Fiber3DFrameCallback callback) {
    _frameCallbacks.add(callback);
    return () => _frameCallbacks.remove(callback);
  }

  VoidCallback registerHittable({
    required Fiber3DVector3 Function() getPosition,
    required double radius,
    VoidCallback? onTap,
    void Function(Offset delta)? onPan,
    void Function(double scale)? onPinch,
  }) {
    final hittable = _Hittable(
      getPosition: getPosition,
      radius: radius,
      onTap: onTap,
      onPan: onPan,
      onPinch: onPinch,
    );
    _hittables.add(hittable);
    return () => _hittables.remove(hittable);
  }
  _Hittable? _closestHitAt(Offset localPosition, Size canvasSize) {
    // Convert a screen-space tap to normalized device coordinates (NDC),
    // each in [-1, 1], with Y flipped since screen Y grows downward while
    // NDC Y grows upward — same convention three.js's setFromCamera uses.
    final ndcX = (localPosition.dx / canvasSize.width) * 2 - 1;
    final ndcY = -((localPosition.dy / canvasSize.height) * 2 - 1);

    final ray = _camera.rayFromNdc(ndcX, ndcY);

    _Hittable? closest;
    double? closestDistance;

    for (final hittable in _hittables) {
      final distance =
          ray.intersectSphereDistance(hittable.getPosition(), hittable.radius);
      if (distance != null &&
          (closestDistance == null || distance < closestDistance)) {
        closest = hittable;
        closestDistance = distance;
      }
    }

    return closest;
  }
  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }


  _Hittable? _gestureTarget;

  @override
  Widget build(BuildContext context) {
    return _Fiber3DCanvasScope(
      state: this,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (details) {
              final hit = _closestHitAt(details.localPosition, size);
              hit?.onTap?.call();
            },
            // Flutter's scale gesture subsumes single-finger pan: a
            // one-finger drag reports scale ~1.0 with a real
            // focalPointDelta; a two-finger pinch reports both a
            // changing scale and a delta. onPan and onScale can't both
            // be registered on one GestureDetector (conflicting
            // recognizers), so this one recognizer drives both
            // onPan, onPinch, and — when the gesture starts on empty
            // space with orbitEnabled — camera orbit/zoom.
            onScaleStart: (details) {
              _gestureTarget = _closestHitAt(details.localFocalPoint, size);
              _orbiting = _gestureTarget == null && _orbitControls != null;
            },
            onScaleUpdate: (details) {
              if (_orbiting) {
                _orbitControls!.rotate(
                  details.focalPointDelta.dx,
                  details.focalPointDelta.dy,
                  size.height,
                );
                if (details.pointerCount >= 2) {
                  _orbitControls!.zoom(details.scale);
                }
                setState(() {
                  _camera = _orbitControls!.camera;
                });
                return;
              }

              _gestureTarget?.onPan?.call(details.focalPointDelta);
              if (details.pointerCount >= 2) {
                _gestureTarget?.onPinch?.call(details.scale);
              }
            },
            onScaleEnd: (_) {
              _gestureTarget = null;
              _orbiting = false;
            },
            child: Stack(children: widget.children),
          );
        },
      ),
    );
  }
}

class _Fiber3DCanvasScope extends InheritedWidget {
  final Fiber3DCanvasState state;

  const _Fiber3DCanvasScope({required this.state, required super.child});

  static Fiber3DCanvasState of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<_Fiber3DCanvasScope>();
    assert(scope != null,
        'No Fiber3DCanvas found in context. onFrame requires being inside a Fiber3DCanvas.');
    return scope!.state;
  }

  @override
  bool updateShouldNotify(_Fiber3DCanvasScope oldWidget) => false;
}

mixin Fiber3DFrameCallbackMixin<T extends StatefulWidget> on State<T> {
  VoidCallback? _unregister;

  void onFrame(Duration elapsed, Duration delta);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _unregister?.call();
    _unregister =
        _Fiber3DCanvasScope.of(context).registerFrameCallback(onFrame);
  }

  @override
  void dispose() {
    _unregister?.call();
    super.dispose();
  }
}