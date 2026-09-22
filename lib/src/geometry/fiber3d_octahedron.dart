import 'fiber3d_polyhedron.dart';

/// A geometry class for representing an octahedron.
///
/// Ported from three.js's `OctahedronGeometry`
/// (src/geometries/OctahedronGeometry.js), a thin subclass of
/// `Fiber3DPolyhedron` supplying the octahedron's raw vertex/face data.
class Fiber3DOctahedron extends Fiber3DPolyhedron {
  Fiber3DOctahedron({double radius = 1, int detail = 0})
      : super(_vertices, _indices, radius: radius, detail: detail);

  static const List<double> _vertices = [
    1, 0, 0, -1, 0, 0, 0, 1, 0,
    0, -1, 0, 0, 0, 1, 0, 0, -1,
  ];

  static const List<int> _indices = [
    0, 2, 4, 0, 4, 3, 0, 3, 5,
    0, 5, 2, 1, 2, 5, 1, 5, 3,
    1, 3, 4, 1, 4, 2,
  ];
}