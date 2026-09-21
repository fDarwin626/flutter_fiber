import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_fiber/src/renderer/fiber3d_canvas.dart';

void main() {
  testWidgets('canvas disposed before GL init finishes does not throw',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: Fiber3DCanvas(children: const [])),
    );

    // No extra pump: GL initialization has not completed yet.
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));

    expect(tester.takeException(), isNull);
  });
}