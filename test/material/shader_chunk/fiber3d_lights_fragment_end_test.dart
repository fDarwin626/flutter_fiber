import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_fiber/src/material/shader_chunk/fiber3d_lights_fragment_end.dart';
import 'package:flutter_fiber/src/material/shader_chunk/fiber3d_lights_physical_pars_fragment.dart';

int _argumentCount(String source, RegExp pattern) {
  return pattern.firstMatch(source)!.group(1)!.split(',').length;
}

void main() {
  const chunk = fiber3dLightsFragmentEnd;

  group('fiber3dLightsFragmentEnd', () {
    test('calls RE_IndirectDiffuse with the accumulated irradiance', () {
      expect(
        chunk,
        contains('RE_IndirectDiffuse( irradiance, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight );'),
      );
    });

    test('calls RE_IndirectSpecular with radiance and iblIrradiance', () {
      expect(
        chunk,
        contains('RE_IndirectSpecular( radiance, iblIrradiance, clearcoatRadiance, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight );'),
      );
    });

    test('only Lambert and Phong fold IBL irradiance into the diffuse pass', () {
      expect(chunk, contains('#if defined( LAMBERT ) || defined( PHONG )'));
      expect(chunk, contains('irradiance += iblIrradiance;'));
    });

    test('each call is guarded by the render equation being defined', () {
      expect(chunk, contains('#if defined( RE_IndirectDiffuse )'));
      expect(chunk, contains('#if defined( RE_IndirectSpecular )'));
    });

    test('the RE_IndirectDiffuse call matches the physical entry point', () {
      final callArgs = _argumentCount(
        chunk,
        RegExp(r'RE_IndirectDiffuse\(([^;]*)\);'),
      );
      final signatureParams = _argumentCount(
        fiber3dLightsPhysicalParsFragment,
        RegExp(r'void RE_IndirectDiffuse_Physical\(([^)]*)\)'),
      );

      expect(callArgs, 7);
      expect(callArgs, signatureParams);
    });

    test('the RE_IndirectSpecular call matches the physical entry point', () {
      final callArgs = _argumentCount(
        chunk,
        RegExp(r'RE_IndirectSpecular\(([^;]*)\);'),
      );
      final signatureParams = _argumentCount(
        fiber3dLightsPhysicalParsFragment,
        RegExp(r'void RE_IndirectSpecular_Physical\(([^)]*)\)'),
      );

      expect(callArgs, 9);
      expect(callArgs, signatureParams);
    });

    test('the RE_* names it calls are aliased by the physical chunk', () {
      expect(
        fiber3dLightsPhysicalParsFragment,
        matches(RegExp(r'#define RE_IndirectDiffuse\s+RE_IndirectDiffuse_Physical')),
      );
      expect(
        fiber3dLightsPhysicalParsFragment,
        matches(RegExp(r'#define RE_IndirectSpecular\s+RE_IndirectSpecular_Physical')),
      );
    });

    test('preprocessor conditionals are balanced', () {
      final opens = RegExp(r'^\s*#if', multiLine: true).allMatches(chunk).length;
      final closes = RegExp(r'^\s*#endif', multiLine: true).allMatches(chunk).length;

      expect(opens, greaterThan(0));
      expect(closes, opens);
    });

    test('is plain ASCII', () {
      expect(chunk.codeUnits.every((c) => c < 128), isTrue);
    });

    test('has no #include left to resolve', () {
      expect(chunk, isNot(contains('#include')));
    });
  });
}