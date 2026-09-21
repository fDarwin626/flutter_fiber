import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_fiber/src/material/shader_chunk/fiber3d_lights_fragment_begin.dart';
import 'package:flutter_fiber/src/material/shader_chunk/fiber3d_lights_physical_fragment.dart';
import 'package:flutter_fiber/src/material/shader_chunk/fiber3d_normal_fragment_begin.dart';
import 'package:flutter_fiber/src/material/shader_chunk/fiber3d_normal_pars_fragment.dart';

void main() {
  const chunk = fiber3dNormalFragmentBegin;

  group('fiber3dNormalFragmentBegin', () {
    test('computes the face direction from gl_FrontFacing', () {
      expect(chunk, contains('float faceDirection = gl_FrontFacing ? 1.0 : - 1.0;'));
    });

    test('flat shading derives the normal from view-position derivatives', () {
      expect(chunk, contains('#ifdef FLAT_SHADED'));
      expect(chunk, contains('vec3 fdx = dFdx( vViewPosition );'));
      expect(chunk, contains('vec3 fdy = dFdy( vViewPosition );'));
      expect(chunk, contains('vec3 normal = normalize( cross( fdx, fdy ) );'));
    });

    test('smooth shading normalizes the interpolated varying', () {
      expect(chunk, contains('vec3 normal = normalize( vNormal );'));
    });

    test('double-sided surfaces flip the normal for back faces', () {
      expect(chunk, contains('#ifdef DOUBLE_SIDED'));
      expect(chunk, contains('normal *= faceDirection;'));
    });

    test('tangent frames are built only for normal-mapped or anisotropic materials', () {
      expect(
        chunk,
        contains('#if defined( USE_NORMALMAP_TANGENTSPACE ) || defined( USE_CLEARCOAT_NORMALMAP ) || defined( USE_ANISOTROPY )'),
      );
      expect(
        chunk,
        contains('mat3 tbn = mat3( normalize( vTangent ), normalize( vBitangent ), normal );'),
      );
      expect(chunk, contains('getTangentFrame( - vViewPosition, normal,'));
      expect(chunk, contains('#ifdef USE_CLEARCOAT_NORMALMAP'));
      expect(chunk, contains('mat3 tbn2 ='));
    });

    test('keeps the unperturbed normal', () {
      expect(chunk, contains('vec3 nonPerturbedNormal = normal;'));
    });

    test('the varyings it reads are declared by normal_pars_fragment', () {
      expect(fiber3dNormalParsFragment, contains('varying vec3 vNormal;'));
      expect(fiber3dNormalParsFragment, contains('varying vec3 vTangent;'));
      expect(fiber3dNormalParsFragment, contains('varying vec3 vBitangent;'));
    });

    test('supplies the variables the lighting chunks read', () {
      expect(fiber3dLightsFragmentBegin, contains('vec3 geometryNormal = normal;'));
      expect(fiber3dLightsPhysicalFragment, contains('dFdx( nonPerturbedNormal )'));
    });

    test('preprocessor conditionals are balanced', () {
      final opens = RegExp(r'^\s*#if', multiLine: true).allMatches(chunk).length;
      final closes = RegExp(r'^\s*#endif', multiLine: true).allMatches(chunk).length;

      expect(opens, greaterThan(0));
      expect(closes, opens);
    });

    test('is plain ASCII with no #include', () {
      expect(chunk.codeUnits.every((c) => c < 128), isTrue);
      expect(chunk, isNot(contains('#include')));
    });
  });
}