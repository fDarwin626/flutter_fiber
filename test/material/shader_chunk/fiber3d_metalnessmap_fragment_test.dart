import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_fiber/src/material/shader_chunk/fiber3d_lights_physical_fragment.dart';
import 'package:flutter_fiber/src/material/shader_chunk/fiber3d_metalnessmap_fragment.dart';

void main() {
  const chunk = fiber3dMetalnessmapFragment;

  group('fiber3dMetalnessmapFragment', () {
    test('starts from the metalness uniform', () {
      expect(chunk, contains('float metalnessFactor = metalness;'));
    });

    test('the map multiplies the B channel, only when enabled', () {
      expect(chunk, contains('#ifdef USE_METALNESSMAP'));
      expect(chunk, contains('texture2D( metalnessMap, vMetalnessMapUv )'));
      expect(chunk, contains('metalnessFactor *= texelMetalness.b;'));
    });

    test('the physical material reads the factor it defines', () {
      expect(fiber3dLightsPhysicalFragment, contains('metalnessFactor'));
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