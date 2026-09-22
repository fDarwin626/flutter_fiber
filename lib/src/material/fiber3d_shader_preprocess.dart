class Fiber3DShaderPreprocess {
  Fiber3DShaderPreprocess._();

  static String replaceLightNums(String source, {required int numPointLights}) {
    return source
        .replaceAll('NUM_SUN_LIGHTS', '0')
        .replaceAll('NUM_DIR_LIGHTS', '0')
        .replaceAll('NUM_SPOT_LIGHT_MAPS', '0')
        .replaceAll('NUM_SPOT_LIGHT_COORDS', '0')
        .replaceAll('NUM_RECT_AREA_LIGHTS', '0')
        .replaceAll('NUM_POINT_LIGHTS', '$numPointLights')
        .replaceAll('NUM_HEMI_LIGHTS', '0')
        .replaceAll('NUM_SUN_LIGHT_SHADOWS', '0')
        .replaceAll('NUM_DIR_LIGHT_SHADOWS', '0')
        .replaceAll('NUM_SPOT_LIGHT_SHADOWS_WITH_MAPS', '0')
        .replaceAll('NUM_SPOT_LIGHT_SHADOWS', '0')
        .replaceAll('NUM_POINT_LIGHT_SHADOWS', '0')
        .replaceAll('NUM_SPOT_LIGHTS', '0');
  }

  static final RegExp _unrollLoopPattern = RegExp(
    r'#pragma unroll_loop_start\s+for\s*\(\s*int\s+i\s*=\s*(\d+)\s*;\s*i\s*<\s*(\d+)\s*;\s*i\s*\+\+\s*\)\s*\{([\s\S]+?)\}\s+#pragma unroll_loop_end',
  );

  static String unrollLoops(String source) {
    return source.replaceAllMapped(_unrollLoopPattern, (match) {
      final start = int.parse(match.group(1)!);
      final end = int.parse(match.group(2)!);
      final snippet = match.group(3)!;

      final buffer = StringBuffer();
      for (var i = start; i < end; i++) {
        buffer.write(
          snippet
              .replaceAll(RegExp(r'\[\s*i\s*\]'), '[ $i ]')
              .replaceAll('UNROLLED_LOOP_INDEX', '$i'),
        );
      }
      return buffer.toString();
    });
  }
}