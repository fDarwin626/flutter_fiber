import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_fiber/src/loader/gltf/fiber3d_gltf_material.dart';

void main() {
  group('Fiber3DGltfMaterial.build', () {
    test('no material JSON -> glTF spec default (white, fully metallic, fully rough)', () {
      final m = Fiber3DGltfMaterial.build(materialJson: null, textures: const []);
      expect(m.color, 0xffffff);
      expect(m.metalness, 1.0);
      expect(m.roughness, 1.0);
      expect(m.opacity, 1.0);
      expect(m.transparent, isFalse);
    });

    test('packs baseColorFactor into color and alpha into opacity', () {
      final m = Fiber3DGltfMaterial.build(
        materialJson: {
          'pbrMetallicRoughness': {
            'baseColorFactor': [1.0, 0.0, 0.0, 0.5],
          },
        },
        textures: const [],
      );
      expect(m.color, 0xff0000);
      expect(m.opacity, 0.5);
    });

    test('alphaMode BLEND sets transparent true, OPAQUE/MASK do not', () {
      final blend = Fiber3DGltfMaterial.build(
        materialJson: {'alphaMode': 'BLEND'},
        textures: const [],
      );
      final mask = Fiber3DGltfMaterial.build(
        materialJson: {'alphaMode': 'MASK'},
        textures: const [],
      );
      final opaque = Fiber3DGltfMaterial.build(
        materialJson: {'alphaMode': 'OPAQUE'},
        textures: const [],
      );
      expect(blend.transparent, isTrue);
      expect(mask.transparent, isFalse);
      expect(opaque.transparent, isFalse);
    });

    test('reads metallicFactor and roughnessFactor', () {
      final m = Fiber3DGltfMaterial.build(
        materialJson: {
          'pbrMetallicRoughness': {
            'metallicFactor': 0.2,
            'roughnessFactor': 0.8,
          },
        },
        textures: const [],
      );
      expect(m.metalness, 0.2);
      expect(m.roughness, 0.8);
    });

    test('packs emissiveFactor into emissive', () {
      final m = Fiber3DGltfMaterial.build(
        materialJson: {
          'emissiveFactor': [0.0, 1.0, 0.0],
        },
        textures: const [],
      );
      expect(m.emissive, 0x00ff00);
    });

    test('an out-of-range texture index resolves to null, not a crash', () {
      final m = Fiber3DGltfMaterial.build(
        materialJson: {
          'pbrMetallicRoughness': {
            'baseColorTexture': {'index': 5},
          },
        },
        textures: const [],
      );
      expect(m.map, isNull);
    });

    test('missing pbrMetallicRoughness block falls back to spec defaults', () {
      final m = Fiber3DGltfMaterial.build(
        materialJson: const <String, dynamic>{},
        textures: const [],
      );
      expect(m.color, 0xffffff);
      expect(m.metalness, 1.0);
      expect(m.roughness, 1.0);
    });
  });
}