import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_fiber/src/material/shader_chunk/fiber3d_lights_physical_fragment.dart';

void main() {
  const chunk = fiber3dLightsPhysicalFragment;

  group('fiber3dLightsPhysicalFragment', () {
    test('builds the PhysicalMaterial from the diffuse color and metalness', () {
      expect(chunk, contains('PhysicalMaterial material;'));
      expect(chunk, contains('material.diffuseColor = diffuseColor.rgb;'));
      expect(
        chunk,
        contains('material.diffuseContribution = diffuseColor.rgb * ( 1.0 - metalnessFactor );'),
      );
      expect(chunk, contains('material.metalness = metalnessFactor;'));
    });

    test('floors roughness from the normal derivatives (specular anti-aliasing)', () {
      expect(chunk, contains('dFdx( nonPerturbedNormal )'));
      expect(chunk, contains('dFdy( nonPerturbedNormal )'));
      expect(
        chunk,
        contains('float roughnessFloor = max( 0.4 * sqrt( geometryRoughness ), geometryRoughness );'),
      );
      expect(
        chunk,
        contains('material.roughness = min( max( roughnessFactor, roughnessFloor ), 1.0 );'),
      );
    });

    test('without IOR, dielectrics get a 4% F0 and metals tint it', () {
      expect(chunk, contains('material.specularColor = vec3( 0.04 );'));
      expect(
        chunk,
        contains('material.specularColorBlended = mix( material.specularColor, diffuseColor.rgb, metalnessFactor );'),
      );
      expect(chunk, contains('material.specularF90 = 1.0;'));
    });

    test('with IOR, the default 1.5 gives the same 4% F0', () {
      expect(
        chunk,
        contains('pow2( ( material.ior - 1.0 ) / ( material.ior + 1.0 ) )'),
      );

      const ior = 1.5;
      final f0 = ((ior - 1) / (ior + 1)) * ((ior - 1) / (ior + 1));

      expect(f0, closeTo(0.04, 1e-12));
    });

    test('clearcoat roughness is floored like the base roughness', () {
      expect(
        chunk,
        contains('material.clearcoatRoughness = min( max( material.clearcoatRoughness, roughnessFloor ), 1.0 );'),
      );
    });

    test('optional features sit behind their #ifdef guards', () {
      for (final guard in [
        '#ifdef USE_DIFFUSE_ROUGHNESS',
        '#ifdef IOR',
        '#ifdef USE_SPECULAR',
        '#ifdef USE_CLEARCOAT',
        '#ifdef USE_DISPERSION',
        '#ifdef USE_RETROREFLECTION',
        '#ifdef USE_IRIDESCENCE',
        '#ifdef USE_SHEEN',
        '#ifdef USE_ANISOTROPY',
      ]) {
        expect(chunk, contains(guard));
      }
    });

    test('does not fill dfg or the multiscattering compensation', () {
      expect(chunk, isNot(contains('material.dfg')));
      expect(chunk, isNot(contains('multiScatteringCompensation')));
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