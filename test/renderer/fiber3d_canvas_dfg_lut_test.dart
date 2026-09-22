import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_fiber/src/renderer/fiber3d_canvas.dart';

void main() {
  testWidgets('canvas mounts and disposes cleanly with the DFG LUT setup added',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: Fiber3DCanvas(children: const [])),
    );

    await tester.pump(const Duration(milliseconds: 16));

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));

    expect(tester.takeException(), isNull);
  });
}