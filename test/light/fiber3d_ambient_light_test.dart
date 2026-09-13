import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_fiber/src/light/fiber3d_ambient_light.dart';

void main() {
  group('Fiber3DAmbientLight', () {
    test('defaults to white, intensity 1', () {
      const light = Fiber3DAmbientLight();

      expect(light.color, 0xffffff);
      expect(light.intensity, 1.0);
      expect(light.r, closeTo(1.0, 1e-9));
      expect(light.g, closeTo(1.0, 1e-9));
      expect(light.b, closeTo(1.0, 1e-9));
    });

    test('decodes a custom color correctly', () {
      const light = Fiber3DAmbientLight(color: 0x404040);

      expect(light.r, closeTo(0x40 / 255.0, 1e-9));
      expect(light.g, closeTo(0x40 / 255.0, 1e-9));
      expect(light.b, closeTo(0x40 / 255.0, 1e-9));
    });

    test('respects custom intensity', () {
      const light = Fiber3DAmbientLight(intensity: 0.3);

      expect(light.intensity, 0.3);
    });
  });
}