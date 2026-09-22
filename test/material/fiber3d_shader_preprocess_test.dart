import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_fiber/src/material/fiber3d_shader_preprocess.dart';

void main() {
  group('Fiber3DShaderPreprocess.replaceLightNums', () {
    test('sets NUM_POINT_LIGHTS to the given count', () {
      final result = Fiber3DShaderPreprocess.replaceLightNums(
        'uniform PointLight pointLights[ NUM_POINT_LIGHTS ];',
        numPointLights: 4,
      );
      expect(result, 'uniform PointLight pointLights[ 4 ];');
    });

    test('zeroes every other light and shadow count', () {
      const source = 'NUM_SUN_LIGHTS NUM_DIR_LIGHTS NUM_SPOT_LIGHTS '
          'NUM_SPOT_LIGHT_MAPS NUM_SPOT_LIGHT_COORDS NUM_RECT_AREA_LIGHTS '
          'NUM_HEMI_LIGHTS NUM_SUN_LIGHT_SHADOWS NUM_DIR_LIGHT_SHADOWS '
          'NUM_SPOT_LIGHT_SHADOWS NUM_POINT_LIGHT_SHADOWS';

      final result = Fiber3DShaderPreprocess.replaceLightNums(
        source,
        numPointLights: 4,
      );

      expect(result, List.filled(11, '0').join(' '));
    });

    test('does not corrupt NUM_SPOT_LIGHT_SHADOWS_WITH_MAPS into two zeroes', () {
      final result = Fiber3DShaderPreprocess.replaceLightNums(
        'if ( UNROLLED_LOOP_INDEX < NUM_SPOT_LIGHT_SHADOWS_WITH_MAPS )',
        numPointLights: 4,
      );
      expect(result, 'if ( UNROLLED_LOOP_INDEX < 0 )');
    });

    test('the #if guards in lights_pars_begin become literal comparisons', () {
      final result = Fiber3DShaderPreprocess.replaceLightNums(
        '#if NUM_POINT_LIGHTS > 0\nfoo\n#endif',
        numPointLights: 4,
      );
      expect(result, '#if 4 > 0\nfoo\n#endif');
    });
  });

  group('Fiber3DShaderPreprocess.unrollLoops', () {
    test('expands a loop into one copy per index, with [i] substituted', () {
      const source = '#pragma unroll_loop_start\n'
          'for ( int i = 0; i < 3; i ++ ) {\n'
          'x += arr[ i ];\n'
          '}\n'
          '#pragma unroll_loop_end';

      final result = Fiber3DShaderPreprocess.unrollLoops(source);

      expect(result, contains('x += arr[ 0 ];'));
      expect(result, contains('x += arr[ 1 ];'));
      expect(result, contains('x += arr[ 2 ];'));
      expect(result, isNot(contains('for (')));
    });

    test('substitutes UNROLLED_LOOP_INDEX with the literal index', () {
      const source = '#pragma unroll_loop_start\n'
          'for ( int i = 0; i < 2; i ++ ) {\n'
          '#if UNROLLED_LOOP_INDEX < 1\nA\n#endif\n'
          '}\n'
          '#pragma unroll_loop_end';

      final result = Fiber3DShaderPreprocess.unrollLoops(source);

      expect(result, contains('#if 0 < 1'));
      expect(result, contains('#if 1 < 1'));
    });

    test('produces zero copies for an empty range', () {
      const source = '#pragma unroll_loop_start\n'
          'for ( int i = 0; i < 0; i ++ ) {\n'
          'x += arr[ i ];\n'
          '}\n'
          '#pragma unroll_loop_end';

      expect(Fiber3DShaderPreprocess.unrollLoops(source).trim(), '');
    });

    test('leaves text with no unroll pragma untouched', () {
      const source = 'void main() { gl_Position = vec4(0.0); }';
      expect(Fiber3DShaderPreprocess.unrollLoops(source), source);
    });

    test('replaceLightNums then unrollLoops handles a real point-light loop', () {
      const source = '#pragma unroll_loop_start\n'
          'for ( int i = 0; i < NUM_POINT_LIGHTS; i ++ ) {\n'
          'pointLight = pointLights[ i ];\n'
          '}\n'
          '#pragma unroll_loop_end';

      final withNums =
          Fiber3DShaderPreprocess.replaceLightNums(source, numPointLights: 2);
      final result = Fiber3DShaderPreprocess.unrollLoops(withNums);

      expect(result, contains('pointLight = pointLights[ 0 ];'));
      expect(result, contains('pointLight = pointLights[ 1 ];'));
      expect(result, isNot(contains('pointLight = pointLights[ 2 ];')));
    });
  });
}