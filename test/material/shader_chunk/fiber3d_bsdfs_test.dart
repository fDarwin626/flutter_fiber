import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_fiber/src/material/shader_chunk/fiber3d_bsdfs.dart';
import 'package:flutter_fiber/src/material/shader_chunk/fiber3d_common.dart';

void main() {
  group('fiber3dBsdfs', () {
    test('defines the three Blinn-Phong functions', () {
      expect(fiber3dBsdfs, contains('float G_BlinnPhong_Implicit('));
      expect(
        fiber3dBsdfs,
        contains('float D_BlinnPhong( const in float shininess, const in float dotNH )'),
      );
      expect(fiber3dBsdfs, contains('vec3 BRDF_BlinnPhong('));
    });

    test('the implicit geometry term is a constant 0.25', () {
      expect(fiber3dBsdfs, contains('return 0.25;'));
    });

    test('the distribution normalizes by 1/pi and scales with shininess', () {
      expect(
        fiber3dBsdfs,
        contains('RECIPROCAL_PI * ( shininess * 0.5 + 1.0 ) * pow( dotNH, shininess )'),
      );
    });

    test('the BRDF combines fresnel, geometry and distribution', () {
      expect(fiber3dBsdfs, contains('F_Schlick( specularColor, 1.0, dotVH )'));
      expect(fiber3dBsdfs, contains('return F * ( G * D );'));
    });

    test('everything it relies on is defined by the common chunk', () {
      expect(fiber3dCommon, contains('#define RECIPROCAL_PI '));
      expect(fiber3dCommon, contains('#define saturate( a )'));
      expect(
        fiber3dCommon,
        contains('vec3 F_Schlick( const in vec3 f0, const in float f90, const in float dotVH )'),
      );
    });
  });
}