import 'package:flutter/widgets.dart';

import '../../core/fiber3d_group.dart';
import '../../core/fiber3d_mesh.dart';
import 'fiber3d_gltf_scene.dart';

class Fiber3DGltfModel extends StatelessWidget {
  final Fiber3DGltfScene scene;

  /// Uniform scale applied to the whole model. glTF exporters disagree
  /// on real-world units (meters vs. centimeters is a common mismatch),
  /// so a loaded model can easily come in 10-100x smaller or larger than
  /// expected relative to your scene/camera -- this is the knob to fix
  /// that without touching the source file.
  final double scale;

  const Fiber3DGltfModel({super.key, required this.scene, this.scale = 1.0});

  @override
  Widget build(BuildContext context) {
    return Fiber3DGroup(
      onFrame: (elapsed, delta, transform) {
        transform.scale.set(scale, scale, scale);
      },
      children: scene.rootNodes.map(_buildNode).toList(),
    );
  }

  static Widget _buildNode(Fiber3DGltfNode node) {
    return Fiber3DGroup(
      onFrame: (elapsed, delta, transform) {
        transform.position.set(node.posX, node.posY, node.posZ);
        transform.rotation.x = node.rotX;
        transform.rotation.y = node.rotY;
        transform.rotation.z = node.rotZ;
        transform.scale.set(node.scaleX, node.scaleY, node.scaleZ);
      },
      children: [
        for (final primitive in node.primitives)
          Fiber3DMesh(
            geometry: primitive,
            material: primitive.material,
            showEdges: false,
            onFrame: (elapsed, delta, transform) {},
          ),
        for (final child in node.children) _buildNode(child),
      ],
    );
  }
}