import 'dart:math';
import 'fiber3d_polyhedron.dart';

/// A geometry class for representing an icosahedron.
///
/// Ported from three.js's `IcosahedronGeometry`
/// (src/geometries/IcosahedronGeometry.js), a thin subclass of
/// `Fiber3DPolyhedron` supplying the icosahedron's raw vertex/face data.
class Fiber3DIcosahedron extends Fiber3DPolyhedron {
  Fiber3DIcosahedron({double radius = 1, int detail = 0})
      : super(_vertices(), _indices, radius: radius, detail: detail);

  static List<double> _vertices() {
    final t = (1 + sqrt(5)) / 2;
    return [
      -1, t, 0, 1, t, 0, -1, -t, 0, 1, -t, 0,
      0, -1, t, 0, 1, t, 0, -1, -t, 0, 1, -t,
      t, 0, -1, t, 0, 1, -t, 0, -1, -t, 0, 1,
    ];
  }

  static const List<int> _indices = [
    0, 11, 5, 0, 5, 1, 0, 1, 7, 0, 7, 10, 0, 10, 11,
    1, 5, 9, 5, 11, 4, 11, 10, 2, 10, 7, 6, 7, 1, 8,
    3, 9, 4, 3, 4, 2, 3, 2, 6, 3, 6, 8, 3, 8, 9,
    4, 9, 5, 2, 4, 11, 6, 2, 10, 8, 6, 7, 9, 8, 1,
  ];
}