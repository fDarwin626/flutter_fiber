import '../../core/fiber3d_color_management.dart';
import '../../material/fiber3d_standard_material.dart';
import '../../material/fiber3d_texture.dart';

/// Maps a glTF material (metallic-roughness model — the only one the
/// spec itself defines; `KHR_materials_*` extensions are not supported)
/// onto Fiber3DStandardMaterial.
///
/// `normalTexture` and `emissiveTexture` are not applied — flutter_fiber
/// has no normal-mapping or emissive-map path yet. `alphaMode: "MASK"`
/// (alpha-cutout) is treated as opaque there's no discard/cutout
/// support in the shader, so rendering it as BLEND would be wrong in a
/// different way (no sharp edge) and OPAQUE is the closer approximation
/// for most cutout content (mostly-opaque foliage/fences, not
/// translucent glass).
class Fiber3DGltfMaterial {
  Fiber3DGltfMaterial._();

  static int _packColor(double r, double g, double b) {
    int c(double v) =>
        (Fiber3DColorManagement.linearToSrgb(v.clamp(0.0, 1.0)) * 255)
            .round()
            .clamp(0, 255);
    return (c(r) << 16) | (c(g) << 8) | c(b);
  }
  /// [textures] is every glTF `textures[]` entry, already resolved to a
  /// decoded Fiber3DTexture, indexed the same way the JSON's own
  /// `textures` array is indexed.
  static Fiber3DStandardMaterial build({
    required Map<String, dynamic>? materialJson,
    required List<Fiber3DTexture> textures,
  }) {
    if (materialJson == null) {
      // glTF's own spec-defined default material: white, fully metallic,
      // fully rough NOT Fiber3DStandardMaterial's own constructor
      // defaults (roughness 1.0 matches, but metalness defaults to 0.0
      // there, not 1.0 as glTF's spec requires for "no material").
      return Fiber3DStandardMaterial(metalness: 1.0, roughness: 1.0);
    }

    final pbr =
        (materialJson['pbrMetallicRoughness'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{};

    final baseColorFactor =
        (pbr['baseColorFactor'] as List?)?.map((e) => (e as num).toDouble()).toList() ??
            const [1.0, 1.0, 1.0, 1.0];
    final metallicFactor = (pbr['metallicFactor'] as num?)?.toDouble() ?? 1.0;
    final roughnessFactor = (pbr['roughnessFactor'] as num?)?.toDouble() ?? 1.0;
    final emissiveFactor =
        (materialJson['emissiveFactor'] as List?)?.map((e) => (e as num).toDouble()).toList() ??
            const [0.0, 0.0, 0.0];
    final alphaMode = materialJson['alphaMode'] as String? ?? 'OPAQUE';

    Fiber3DTexture? resolveTexture(Map<String, dynamic>? texRef) {
      final index = texRef?['index'] as int?;
      if (index == null || index < 0 || index >= textures.length) return null;
      return textures[index];
    }

    final baseColorTexture =
        resolveTexture((pbr['baseColorTexture'] as Map?)?.cast<String, dynamic>());
    final metallicRoughnessTexture = resolveTexture(
      (pbr['metallicRoughnessTexture'] as Map?)?.cast<String, dynamic>(),
    );

    return Fiber3DStandardMaterial(
      color: _packColor(baseColorFactor[0], baseColorFactor[1], baseColorFactor[2]),
      opacity: baseColorFactor.length > 3 ? baseColorFactor[3] : 1.0,
      transparent: alphaMode == 'BLEND',
      metalness: metallicFactor,
      roughness: roughnessFactor,
      emissive: _packColor(
        emissiveFactor[0],
        emissiveFactor[1],
        emissiveFactor.length > 2 ? emissiveFactor[2] : 0.0,
      ),
      map: baseColorTexture,
      // glTF packs roughness in the G channel and metalness in the B
      // channel of ONE combined texture — Fiber3DStandardMaterial's own
      // roughnessMap/metalnessMap docs already describe sampling exactly
      // this way, so pointing both fields at the same decoded texture is
      // the documented, correct usage, not a workaround.
      roughnessMap: metallicRoughnessTexture,
      metalnessMap: metallicRoughnessTexture,
    );
  }
}