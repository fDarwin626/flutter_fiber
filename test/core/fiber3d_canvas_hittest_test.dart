import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_fiber/src/renderer/fiber3d_canvas.dart';
import 'package:flutter_fiber/src/core/fiber3d_vector3.dart';
import 'package:flutter_fiber/src/camera/fiber3d_camera.dart';

class _HittableProbe extends StatefulWidget {
  final VoidCallback onTap;
  const _HittableProbe({required this.onTap});

  @override
  State<_HittableProbe> createState() => _HittableProbeState();
}

class _HittableProbeState extends State<_HittableProbe> {
  VoidCallback? _unregister;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _unregister?.call();
    final canvasState = context
        .findAncestorStateOfType<Fiber3DCanvasState>();
    _unregister = canvasState?.registerHittable(
      getPosition: () => const Fiber3DVector3.zero(),
      radius: 1.0,
      onTap: widget.onTap,
    );
  }

  @override
  void dispose() {
    _unregister?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

void main() {
  testWidgets('tapping the center hits a mesh at the origin', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Fiber3DCanvas(
          camera: Fiber3DCamera(
            position: const Fiber3DVector3(0, 0, 5),
            target: const Fiber3DVector3.zero(),
          ),
          children: [_HittableProbe(onTap: () => tapped = true)],
        ),
      ),
    );

    await tester.pump();

    // Tap the center of the canvas — should land on the mesh at the origin.
    await tester.tapAt(tester.getCenter(find.byType(Fiber3DCanvas)));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('tapping far from a mesh does not hit it', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Fiber3DCanvas(
          camera: Fiber3DCamera(
            position: const Fiber3DVector3(0, 0, 5),
            target: const Fiber3DVector3.zero(),
          ),
          children: [_HittableProbe(onTap: () => tapped = true)],
        ),
      ),
    );

    await tester.pump();

    // Tap a corner, far from center where the mesh actually is.
    final topLeft = tester.getTopLeft(find.byType(Fiber3DCanvas));
    await tester.tapAt(topLeft + const Offset(2, 2));
    await tester.pump();

    expect(tapped, isFalse);
  });
}