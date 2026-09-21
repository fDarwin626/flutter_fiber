import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_fiber/src/renderer/fiber3d_tone_mapping.dart';

void main() {
  group('Fiber3DToneMapping', () {
    test('lists the three.js tone-mapping modes in order, none first', () {
      expect(Fiber3DToneMapping.values, [
        Fiber3DToneMapping.none,
        Fiber3DToneMapping.linear,
        Fiber3DToneMapping.reinhard,
        Fiber3DToneMapping.cineon,
        Fiber3DToneMapping.acesFilmic,
        Fiber3DToneMapping.custom,
        Fiber3DToneMapping.agx,
        Fiber3DToneMapping.neutral,
      ]);
    });
  });
}