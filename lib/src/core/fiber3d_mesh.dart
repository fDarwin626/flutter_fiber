import 'package:flutter/widgets.dart';
import 'fiber3d_canvas.dart';
import 'fiber3d_object.dart';
import 'fiber3d_vector3.dart';

/// A renderable mesh: a geometry, a material, and its own transform
/// (position/rotation/scale via [transform]).
///
/// Geometry and material are typed `dynamic` deliberately — flutter_fiber's
/// 5 geometries and 2 materials are plain data classes with no shared base
/// type, and retrofitting an inheritance hierarchy onto already-tested
/// code isn't worth it for what the renderer needs (a runtime type check
/// to pick the right buffer-building/uniform-upload path). The renderer
/// (Fiber3DCanvas's render loop) pattern-matches on the concrete type.
///
/// Registers itself with the ancestor [Fiber3DCanvas] on mount and
/// unregisters on dispose — same lifecycle-safe pattern as onFrame and
/// hittable registration, so a mesh removed from the tree can never leak
/// into the render loop.
class Fiber3DMesh extends StatefulWidget {
  final dynamic geometry;
  final dynamic material;

  final void Function(Duration elapsed, Duration delta, Fiber3DObject transform)? onFrame;
  final VoidCallback? onTap;
  final void Function(Offset delta)? onPan;
  final void Function(double scale)? onPinch;

  /// Bounding-sphere radius used for tap/pan hit-testing. A caller who
  /// knows their geometry's extent can override this; otherwise a
  /// reasonable default is used.
  final double hitRadius;

  const Fiber3DMesh({
    super.key,
    required this.geometry,
    required this.material,
    this.onFrame,
    this.onTap,
    this.onPan,
    this.onPinch,
    this.hitRadius = 1.0,
  });

  @override
  State<Fiber3DMesh> createState() => Fiber3DMeshState();
}

class Fiber3DMeshState extends State<Fiber3DMesh> {
  /// The mesh's own scene-graph transform — exposed so callers can do
  /// `mesh.transform.rotation.y += delta` inside an onFrame callback,
  /// matching the PRD's own usage pattern.
  final Fiber3DObject transform = Fiber3DObject();

  VoidCallback? _unregisterFrame;
  VoidCallback? _unregisterHittable;
  VoidCallback? _unregisterMesh;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final canvasState = context.findAncestorStateOfType<Fiber3DCanvasState>();
    assert(canvasState != null,
        'Fiber3DMesh must be a descendant of Fiber3DCanvas.');

    _unregisterMesh?.call();
    _unregisterMesh = canvasState?.registerMesh(this);

    if (widget.onFrame != null) {
      _unregisterFrame?.call();
      _unregisterFrame = canvasState?.registerFrameCallback((elapsed, delta) {
        widget.onFrame!(elapsed, delta, transform);
      });
    }
    
    if (widget.onTap != null || widget.onPan != null || widget.onPinch != null) {
      _unregisterHittable?.call();
      _unregisterHittable = canvasState?.registerHittable(
        getPosition: () {
          final pos = transform.position;
          return Fiber3DVector3(pos.x, pos.y, pos.z);
        },
        radius: widget.hitRadius,
        onTap: widget.onTap,
        onPan: widget.onPan,
        onPinch: widget.onPinch,
      );
    }
  }

  @override
  void dispose() {
    _unregisterMesh?.call();
    _unregisterFrame?.call();
    _unregisterHittable?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Fiber3DMesh has no visual footprint of its own in the Flutter
    // widget tree — it's rendered by Fiber3DCanvas's GL draw loop, not
    // by returning a widget subtree here.
    return const SizedBox.shrink();
  }
}