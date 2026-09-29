import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_fiber/src/material/fiber3d_texture.dart';
import 'package:flutter_fiber/src/material/fiber3d_widget_texture.dart';

void main() {
  testWidgets(
    'Fiber3DWidgetTexture builds as Positioned + RepaintBoundary inside a Stack',
    (tester) async {
      final texture = Fiber3DTexture.raw(Uint8List.fromList([0, 0, 0, 0]), 1, 1);

      await tester.pumpWidget(
        MaterialApp(
          home: Stack(
            children: [
              Fiber3DWidgetTexture(
                texture: texture,
                child: Container(color: Colors.red),
              ),
            ],
          ),
        ),
      );

      expect(find.byType(Positioned), findsOneWidget);
      expect(find.byType(RepaintBoundary), findsWidgets);
    },
  );

  testWidgets(
    'a captured frame replaces the placeholder pixels within a few ticks',
    (tester) async {
      final texture = Fiber3DTexture.raw(Uint8List.fromList([0, 0, 0, 0]), 1, 1);

      await tester.pumpWidget(
        MaterialApp(
          home: Stack(
            children: [
              Fiber3DWidgetTexture(
                texture: texture,
                width: 8,
                height: 8,
                fps: 30,
                child: Container(color: Colors.blue),
              ),
            ],
          ),
        ),
      );

      await tester.runAsync(() async {
        for (var i = 0; i < 8; i++) {
          await tester.pump(const Duration(milliseconds: 40));
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
      });
      expect(texture.width, 8);
      expect(texture.height, 8);
      expect(texture.pixels!.length, 8 * 8 * 4);
    },
  );
}