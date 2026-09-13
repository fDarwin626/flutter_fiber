import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_fiber/src/material/fiber3d_basic_material.dart';

void main() {
  group('Fiber3DBasicMaterial', () {
    test('defaults to white, no wireframe', () {
      const material = Fiber3DBasicMaterial();

      expect(material.color, 0xffffff);
      expect(material.wireframe, false);
      expect(material.r, closeTo(1.0, 1e-9));
      expect(material.g, closeTo(1.0, 1e-9));
      expect(material.b, closeTo(1.0, 1e-9));
    });

    test('decodes a custom color correctly', () {
      const material = Fiber3DBasicMaterial(color: 0xff8800);

      expect(material.r, closeTo(1.0, 1e-9));
      expect(material.g, closeTo(0x88 / 255.0, 1e-9));
      expect(material.b, closeTo(0.0, 1e-9));
    });

    test('wireframe flag is respected', () {
      const material = Fiber3DBasicMaterial(wireframe: true);

      expect(material.wireframe, true);
    });
  });
}