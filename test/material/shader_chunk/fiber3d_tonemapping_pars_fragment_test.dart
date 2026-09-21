import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_fiber/src/material/shader_chunk/fiber3d_tonemapping_pars_fragment.dart';

void main() {
  group('fiber3dTonemappingParsFragment', () {
    test('declares the exposure uniform', () {
      expect(
        fiber3dTonemappingParsFragment,
        contains('uniform float toneMappingExposure;'),
      );
    });

    test('defines every tone-mapping operator', () {
      for (final name in [
        'vec3 LinearToneMapping( vec3 color )',
        'vec3 ReinhardToneMapping( vec3 color )',
        'vec3 CineonToneMapping( vec3 color )',
        'vec3 RRTAndODTFit( vec3 v )',
        'vec3 ACESFilmicToneMapping( vec3 color )',
        'vec3 agxDefaultContrastApprox( vec3 x )',
        'vec3 AgXToneMapping( vec3 color )',
        'vec3 NeutralToneMapping( vec3 color )',
        'vec3 CustomToneMapping( vec3 color )',
      ]) {
        expect(fiber3dTonemappingParsFragment, contains(name));
      }
    });

    test('keeps the ACES matrices and RRT/ODT constants', () {
      for (final c in [
        '0.59719',
        '1.60475',
        '0.0245786',
        '0.983729',
        'toneMappingExposure / 0.6',
      ]) {
        expect(fiber3dTonemappingParsFragment, contains(c));
      }
    });

    test('keeps the AgX matrices, EV range and sigmoid coefficients', () {
      for (final c in [
        '0.856627153315983',
        '1.1271005818144368',
        '12.47393',
        '4.026069',
        '15.5',
        '40.14',
        '31.96',
        '6.868',
        '0.4298',
        '0.1191',
        '0.00232',
      ]) {
        expect(fiber3dTonemappingParsFragment, contains(c));
      }
    });

    test('keeps the Neutral compression constants', () {
      expect(
        fiber3dTonemappingParsFragment,
        contains('const float StartCompression = 0.8 - 0.04;'),
      );
      expect(
        fiber3dTonemappingParsFragment,
        contains('const float Desaturation = 0.15;'),
      );
    });
  });
}