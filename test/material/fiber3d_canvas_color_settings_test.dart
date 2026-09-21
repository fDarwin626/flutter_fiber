import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_fiber/src/renderer/fiber3d_canvas.dart';
import 'package:flutter_fiber/src/renderer/fiber3d_tone_mapping.dart';

void main() {
  group('Fiber3DCanvas color settings', () {
    test('defaults match three.js: managed color, no tone mapping', () {
      final canvas = Fiber3DCanvas();

      expect(canvas.colorManagement, isTrue);
      expect(canvas.toneMapping, Fiber3DToneMapping.none);
      expect(canvas.toneMappingExposure, 1.0);
    });

    test('accepts explicit settings', () {
      final canvas = Fiber3DCanvas(
        colorManagement: false,
        toneMapping: Fiber3DToneMapping.agx,
        toneMappingExposure: 1.5,
      );

      expect(canvas.colorManagement, isFalse);
      expect(canvas.toneMapping, Fiber3DToneMapping.agx);
      expect(canvas.toneMappingExposure, 1.5);
    });
  });
}