import '../core/fiber3d_color_management.dart';
import '../renderer/fiber3d_tone_mapping.dart';

/// Generators for the small GLSL functions three.js injects into every
/// fragment shader prefix.
///
/// Ported from `getTexelEncodingFunction`, `getToneMappingFunction` and
/// `getLuminanceFunction` in three.js's WebGLProgram.js
/// (src/renderers/webgl/). The prefix assembly itself is ported separately.
class Fiber3DProgramFunctions {
  Fiber3DProgramFunctions._();

  /// GLSL function [functionName] that encodes a linear color for output in
  /// [colorSpace].
  ///
  /// three.js multiplies by a working to output gamut matrix first. Every
  /// color space flutter_fiber supports shares Rec.709 primaries, so that
  /// matrix is the identity and the multiply is omitted.
  static String texelEncodingFunction(
    String functionName,
    Fiber3DColorSpace colorSpace,
  ) {
    final transferFunction = switch (Fiber3DColorManagement.getTransfer(
      colorSpace,
    )) {
      Fiber3DColorTransfer.linear => 'LinearTransferOETF',
      Fiber3DColorTransfer.srgb => 'sRGBTransferOETF',
    };

    return [
      'vec4 $functionName( vec4 value ) {',
      '\treturn $transferFunction( value );',
      '}',
    ].join('\n');
  }

  /// GLSL function [functionName] that applies [toneMapping]. `none` falls
  /// back to Linear, as three.js does for an unsupported mode (minus its
  /// warning); callers only ask for a function when a mode is active.
  static String toneMappingFunction(
    String functionName,
    Fiber3DToneMapping toneMapping,
  ) {
    final name = switch (toneMapping) {
      Fiber3DToneMapping.none || Fiber3DToneMapping.linear => 'Linear',
      Fiber3DToneMapping.reinhard => 'Reinhard',
      Fiber3DToneMapping.cineon => 'Cineon',
      Fiber3DToneMapping.acesFilmic => 'ACESFilmic',
      Fiber3DToneMapping.custom => 'Custom',
      Fiber3DToneMapping.agx => 'AgX',
      Fiber3DToneMapping.neutral => 'Neutral',
    };

    return 'vec3 $functionName( vec3 color ) { return ${name}ToneMapping( color ); }';
  }

  /// GLSL `luminance()` function using the working color space's weights.
  static String luminanceFunction() {
    final w = Fiber3DColorManagement.getLuminanceCoefficients();
    final r = w[0].toStringAsFixed(4);
    final g = w[1].toStringAsFixed(4);
    final b = w[2].toStringAsFixed(4);

    return [
      'float luminance( const in vec3 rgb ) {',
      '\tconst vec3 weights = vec3( $r, $g, $b );',
      '\treturn dot( weights, rgb );',
      '}',
    ].join('\n');
  }
}