import '../../material/fiber3d_standard_material.dart';

/// One glTF mesh primitive, decoded into exactly the shape
/// Fiber3DCanvas's existing geometry pipeline already expects
/// (positions/normals/uvs/colors/indices) — this can be passed directly
/// as a Fiber3DMesh's `geometry`, no wrapper needed. The "Fiber3D" name
/// prefix matters: the canvas's type check is
/// `geometry.runtimeType.toString().startsWith('Fiber3D')`.
class Fiber3DGltfPrimitive {
  final List<double> positions;
  final List<double> normals;
  final List<double> uvs;
  final List<double>? colors;
  final List<int> indices;
  final Fiber3DStandardMaterial material;

  const Fiber3DGltfPrimitive({
    required this.positions,
    required this.normals,
    required this.uvs,
    this.colors,
    required this.indices,
    required this.material,
  });
}

/// One glTF node: its own local transform (already resolved to
/// position + Euler rotation + scale, regardless of whether the source
/// node used translation/rotation/scale or a single matrix), the mesh
/// primitives it owns (if any), and its children.
class Fiber3DGltfNode {
  final String? name;
  final double posX, posY, posZ;
  final double rotX, rotY, rotZ;
  final double scaleX, scaleY, scaleZ;
  final List<Fiber3DGltfPrimitive> primitives;
  final List<Fiber3DGltfNode> children = [];

  Fiber3DGltfNode({
    this.name,
    this.posX = 0,
    this.posY = 0,
    this.posZ = 0,
    this.rotX = 0,
    this.rotY = 0,
    this.rotZ = 0,
    this.scaleX = 1,
    this.scaleY = 1,
    this.scaleZ = 1,
    this.primitives = const [],
  });
}

/// The fully parsed result of loading a glTF/glb file: its root nodes
/// (per the file's default, or explicitly selected, scene).
class Fiber3DGltfScene {
  final List<Fiber3DGltfNode> rootNodes;
  const Fiber3DGltfScene(this.rootNodes);
}