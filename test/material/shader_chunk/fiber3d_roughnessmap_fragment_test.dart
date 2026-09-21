import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_fiber/src/material/shader_chunk/fiber3d_lights_physical_fragment.dart';
import 'package:flutter_fiber/src/material/shader_chunk/fiber3d_roughnessmap_fragment.dart';

void main() {
  const chunk = fiber3dRoughnessmapFragment;

  group('fiber3dRoughnessmapFragment', () {
    test('starts from the roughness uniform', () {
      expect(chunk, contains('float roughnessFactor = roughness;'));
    });

    test('the map multiplies the G channel, only when enabled', () {
      expect(chunk, contains('#ifdef USE_ROUGHNESSMAP'));
      expect(chunk, contains('texture2D( roughnessMap, vRoughnessMapUv )'));
      expect(chunk, contains('roughnessFactor *= texelRoughness.g;'));
    });

    test('the physical material reads the factor it defines', () {
      expect(fiber3dLightsPhysicalFragment, contains('roughnessFactor'));
    });

    test('is balanced, plain ASCII, with no #include', () {
      expect(
        RegExp(r'^\s*#if', multiLine: true).allMatches(chunk).length,
        RegExp(r'^\s*#endif', multiLine: true).allMatches(chunk).length,
      );
      expect(chunk.codeUnits.every((c) => c < 128), isTrue);
      expect(chunk, isNot(contains('#include')));
    });
  });
}