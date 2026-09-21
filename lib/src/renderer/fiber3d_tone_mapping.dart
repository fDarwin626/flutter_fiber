enum Fiber3DToneMapping {
  /// No tone mapping (the three.js default).
  none,

  /// Exposure only.
  linear,

  reinhard,

  cineon,

  /// ACES filmic curve, adjusted for a brighter viewing environment.
  acesFilmic,

  /// Placeholder operator that returns the color unchanged.
  custom,

  /// AgX, Blender's default view transform.
  agx,

  neutral,
}