import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_fiber/src/light/fiber3d_point_light.dart';
import 'package:flutter_fiber/src/core/fiber3d_vector3.dart';

void main() {
  group('Fiber3DPointLight', () {
    test('defaults match three.js (white, intensity 1, distance 0, decay 2)', () {
      const light = Fiber3DPointLight();

      expect(light.color, 0xffffff);
      expect(light.intensity, 1.0);
      expect(light.distance, 0.0);
      expect(light.decay, 2.0);
      expect(light.position.x, 0.0);
      expect(light.position.y, 0.0);
      expect(light.position.z, 0.0);
    });

    test('decodes a custom color correctly', () {
      const light = Fiber3DPointLight(color: 0xff0000);

      expect(light.r, closeTo(1.0, 1e-9));
      expect(light.g, closeTo(0.0, 1e-9));
      expect(light.b, closeTo(0.0, 1e-9));
    });

    test('power is derived correctly from intensity', () {
      const light = Fiber3DPointLight(intensity: 1.0);

      expect(light.power, closeTo(4 * pi, 1e-9));
    });

    test('position is stored correctly', () {
      const light = Fiber3DPointLight(position: Fiber3DVector3(2, 3, 2));

      expect(light.position.x, 2.0);
      expect(light.position.y, 3.0);
      expect(light.position.z, 2.0);
    });

    test('respects custom distance and decay', () {
      const light = Fiber3DPointLight(distance: 50, decay: 1.5);

      expect(light.distance, 50.0);
      expect(light.decay, 1.5);
    });
  });
}