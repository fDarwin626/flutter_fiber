import 'package:flutter/widgets.dart';
import 'package:flutter_fiber/src/core/fiber3d_canvas.dart';
import 'fiber3d_object.dart';

/// A grouping container with no geometry/material of its own — lets
/// multiple Fiber3DMesh (or nested Fiber3DGroup) children be positioned,
/// rotated, and scaled together as one logical unit, instead of the
/// caller manually syncing several independent transforms by hand.
///
/// Mirrors three.js's `Group`/`Object3D`-as-container pattern: a group
/// is just a transform node in the scene graph with children attached
/// via Fiber3DObject.add(), so parent transforms compose into children's
/// matrixWorld automatically (already correct, untouched machinery in
/// Fiber3DObject.updateMatrixWorld).
class Fiber3DGroup extends StatefulWidget {
  final List<Widget> children;

  /// Per-frame callback for the group's own transform — rotate/move the
  /// group once here and every child mesh moves with it, same pattern
  /// as Fiber3DMesh.onFrame.
  final void Function(Duration elapsed, Duration delta, Fiber3DObject transform)? onFrame;

  const Fiber3DGroup({
    super.key,
    required this.children,
    this.onFrame,
  });

  @override
  State<Fiber3DGroup> createState() => Fiber3DGroupState();
}
class Fiber3DGroupState extends State<Fiber3DGroup> {
  /// The group's own transform. Fiber3DMesh/Fiber3DGroup children look
  /// this up via _Fiber3DGroupScope and add() their own transform to it,
  /// exactly like they'd otherwise stay flat under the canvas.
  final Fiber3DObject transform = Fiber3DObject();

  VoidCallback? _unregisterFrame;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final parentGroup = Fiber3DGroupScope.maybeOf(context);
    if (parentGroup != null && transform.parent != parentGroup.transform) {
      parentGroup.transform.add(transform);
    }

    if (widget.onFrame != null) {
      final canvasState = context.findAncestorStateOfType<Fiber3DCanvasState>();
      assert(canvasState != null,
          'Fiber3DGroup with onFrame must be a descendant of Fiber3DCanvas.');
      _unregisterFrame?.call();
      _unregisterFrame = canvasState?.registerFrameCallback((elapsed, delta) {
        widget.onFrame!(elapsed, delta, transform);
      });
    }
  }

  @override
  void dispose() {
    transform.removeFromParent();
    _unregisterFrame?.call();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return _Fiber3DGroupScope(
      state: this,
      child: Stack(children: widget.children),
    );
  }
}

/// InheritedWidget exposing the nearest Fiber3DGroup's transform, same
/// scoping pattern as _Fiber3DCanvasScope. A Fiber3DMesh mounted inside
/// a group finds this and attaches to it instead of being a root
/// transform.
class _Fiber3DGroupScope extends InheritedWidget {
  final Fiber3DGroupState state;

  const _Fiber3DGroupScope({required this.state, required super.child});

  @override
  bool updateShouldNotify(_Fiber3DGroupScope oldWidget) => false;
}

/// Public lookup for the nearest Fiber3DGroup's transform, used by
/// Fiber3DMesh (and nested Fiber3DGroup) to find their parent group.
class Fiber3DGroupScope {
  static Fiber3DGroupState? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_Fiber3DGroupScope>()
        ?.state;
  }
}