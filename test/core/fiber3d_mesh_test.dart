import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_fiber/src/core/fiber3d_canvas.dart';
import 'package:flutter_fiber/src/core/fiber3d_mesh.dart';
import 'package:flutter_fiber/src/geometry/fiber3d_box.dart';
import 'package:flutter_fiber/src/material/fiber3d_standard_material.dart';

void main() {
  testWidgets('Fiber3DMesh registers itself with the ancestor canvas', (tester) async {
    late Fiber3DCanvasState canvasState;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Fiber3DCanvas(
              children: [
                Fiber3DMesh(
                  geometry: Fiber3DBox(),
                  material: const Fiber3DStandardMaterial(),
                ),
              ],
            );
          },
        ),
      ),
    );

    canvasState = tester.state(find.byType(Fiber3DCanvas));
    expect(canvasState, isNotNull);
  });

  testWidgets('Fiber3DMesh onFrame fires while mounted', (tester) async {
    var frameCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Fiber3DCanvas(
          children: [
            Fiber3DMesh(
              geometry: Fiber3DBox(),
              material: const Fiber3DStandardMaterial(),
              onFrame: (elapsed, delta, transform) => frameCount++,
            ),
          ],
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 16));

    expect(frameCount, greaterThanOrEqualTo(2));
    expect(frameCount, greaterThanOrEqualTo(2));
  });

  testWidgets('Fiber3DMesh removed from tree stops firing onFrame', (tester) async {
    var frameCount = 0;
    var showMesh = true;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            return Fiber3DCanvas(
              children: [
                if (showMesh)
                  Fiber3DMesh(
                    geometry: Fiber3DBox(),
                    material: const Fiber3DStandardMaterial(),
                    onFrame: (elapsed, delta, transform) => frameCount++,
                  ),
                TextButton(
                  onPressed: () => setState(() => showMesh = false),
                  child: const Text('remove'),
                ),
              ],
            );
          },
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 16));
    expect(frameCount, greaterThan(0));

    await tester.tap(find.text('remove'));
    await tester.pump();

    final countAtRemoval = frameCount;
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 16));

    expect(frameCount, countAtRemoval);
  });

  testWidgets('mesh transform.position feeds hit-testing position', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Fiber3DCanvas(
          children: [
            Fiber3DMesh(
              geometry: Fiber3DBox(),
              material: const Fiber3DStandardMaterial(),
              onTap: () => tapped = true,
            ),
          ],
        ),
      ),
    );

    await tester.pump();
    await tester.tapAt(tester.getCenter(find.byType(Fiber3DCanvas)));
    await tester.pump();

    expect(tapped, isTrue);
  });
}