import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_fiber/src/material/fiber3d_standard_material.dart';

void main() {
  group('Fiber3DStandardMaterial', () {
    test('defaults match three.js (white, roughness 1, metalness 0)', () {
      final material = Fiber3DStandardMaterial();

      expect(material.color, 0xffffff);
      expect(material.roughness, 1.0);
      expect(material.metalness, 0.0);
      expect(material.emissive, 0x000000);
      expect(material.emissiveIntensity, 1.0);
      expect(material.wireframe, false);
      expect(material.flatShading, false);
    });

    test('decodes a custom color correctly', () {
      final material = Fiber3DStandardMaterial(color: 0x3366ff);

      expect(material.r, closeTo(0x33 / 255.0, 1e-9));
      expect(material.g, closeTo(0x66 / 255.0, 1e-9));
      expect(material.b, closeTo(1.0, 1e-9));
    });

    test('decodes a custom emissive color correctly', () {
      final material = Fiber3DStandardMaterial(emissive: 0xff0000, emissiveIntensity: 2.0);

      expect(material.emissiveR, closeTo(1.0, 1e-9));
      expect(material.emissiveG, closeTo(0.0, 1e-9));
      expect(material.emissiveB, closeTo(0.0, 1e-9));
      expect(material.emissiveIntensity, 2.0);
    });

    test('respects custom roughness and metalness', () {
      final material = Fiber3DStandardMaterial(roughness: 0.4, metalness: 0.8);

      expect(material.roughness, 0.4);
      expect(material.metalness, 0.8);
    });
  });
}