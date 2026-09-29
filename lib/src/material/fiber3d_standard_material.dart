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

  final Fiber3DTexture? roughnessMap;

  /// Metalness map, sampled from the B channel same ORM-compatible
  /// convention as [roughnessMap]. Multiplies into [metalness].
  final Fiber3DTexture? metalnessMap;

  /// Intensity multiplier applied to the environment map's contribution
  /// (both getIBLIrradiance and getIBLRadiance), matching three.js's
  /// MeshStandardMaterial.envMapIntensity. 1.0 = unscaled.
  final double envMapIntensity;

  /// Intensity of a clear, thin lacquer layer over the base material,
  /// matching three.js's MeshPhysicalMaterial.clearcoat. 0.0 (default) =
  /// off; 1.0 = full clearcoat.
  final double clearcoat;

  /// Roughness of the clearcoat layer itself, independent of the base
  /// [roughness]. Matches MeshPhysicalMaterial.clearcoatRoughness.
  final double clearcoatRoughness;

  /// Alpha, 0.0 (fully invisible) to 1.0 (fully opaque). Has no visible
  /// effect unless [transparent] is true — matches three.js's real
  /// Material.opacity/transparent relationship.
  final double opacity;

  /// Enables real alpha blending for this mesh. Off by default (every
  /// existing material stays exactly as opaque as before). Correct for
  /// one transparent surface at a time — no depth-sorted transparent
  /// pass exists yet, so multiple overlapping transparent meshes can
  /// show sorting artifacts.
  final bool transparent;

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
    this.clearcoat = 0.0,
    this.clearcoatRoughness = 0.0,
    this.opacity = 1.0,
    this.transparent = false,
  });
    
  double get r => ((color >> 16) & 0xff) / 255.0;
  double get g => ((color >> 8) & 0xff) / 255.0;
  double get b => (color & 0xff) / 255.0;

  double get emissiveR => ((emissive >> 16) & 0xff) / 255.0;
  double get emissiveG => ((emissive >> 8) & 0xff) / 255.0;
  double get emissiveB => (emissive & 0xff) / 255.0;
}