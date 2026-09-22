import 'fiber3d_polyhedron.dart';

class Fiber3DTetrahedron extends Fiber3DPolyhedron {
  Fiber3DTetrahedron({double radius = 1, int detail = 0})
      : super(_vertices, _indices, radius: radius, detail: detail);

  static const List<double> _vertices = [
    1, 1, 1, -1, -1, 1, -1, 1, -1, 1, -1, -1,
  ];

  static const List<int> _indices = [
    2, 1, 0, 0, 3, 2, 1, 3, 0, 2, 3, 1,
  ];
}