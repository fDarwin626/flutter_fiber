import 'package:flutter_fiber/src/material/fiber3d_texture.dart';

class Fiber3DStandardMaterial {
  /// Base color of the material, as 0xRRGGBB.
  final int color;

  /// How rough the surface appears. 0.0 = mirror-smooth, 1.0 = fully diffuse.
  final double roughness;

  /// How metallic the surface appears. 0.0 = non-metal (wood, stone),
  /// 1.0 = metal.
  final double metalness;

  /// Emissive (self-lit, glow) color, as 0xRRGGBB. Unaffected by lighting.
  final int emissive;

  /// Intensity multiplier applied to the emissive color.
  final double emissiveIntensity;

  /// Renders the geometry as a wireframe instead of filled triangles.
  final bool wireframe;

  /// Whether the material is rendered with flat (faceted) shading instead
  /// of smooth per-vertex-normal shading.
  final bool flatShading;

  final Fiber3DTexture? map;

  /// Roughness map, sampled from the G channel compatible with a
  /// combined OcclusionRoughnessMetallic (ORM) texture, or its own
  /// dedicated single-channel image, since the shader just reads
  /// whatever's bound. Multiplies into [roughness], same white-fallback
  /// no-op convention as [map].
  final Fiber3DTexture? roughnessMap;

  /// Metalness map, sampled from the B channel same ORM-compatible
  /// convention as [roughnessMap]. Multiplies into [metalness].
  final Fiber3DTexture? metalnessMap;

  /// Intensity multiplier applied to the environment map's contribution
  /// (both getIBLIrradiance and getIBLRadiance), matching three.js's
  /// MeshStandardMaterial.envMapIntensity. 1.0 = unscaled.
  final double envMapIntensity;

  Fiber3DStandardMaterial({
    this.color = 0xffffff,
    this.roughness = 1.0,
    this.metalness = 0.0,
    this.emissive = 0x000000,
    this.emissiveIntensity = 1.0,
    this.wireframe = false,
    this.flatShading = false,
    this.map,
    this.roughnessMap,
    this.metalnessMap,
    this.envMapIntensity = 1.0,
  });

  double get r => ((color >> 16) & 0xff) / 255.0;
  double get g => ((color >> 8) & 0xff) / 255.0;
  double get b => (color & 0xff) / 255.0;

  double get emissiveR => ((emissive >> 16) & 0xff) / 255.0;
  double get emissiveG => ((emissive >> 8) & 0xff) / 255.0;
  double get emissiveB => (emissive & 0xff) / 255.0;
}