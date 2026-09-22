/// A ramp/doorstop shape: a right-triangular-prism, essentially a box
/// where one edge collapses to a line instead of staying a full face
/// full height at the back, tapering down to flat at the front.
///
/// Original to flutter_fiber no three.js equivalent. Built the same
/// way as a flat-shaded box: each of the 5 faces gets its own
/// duplicated vertices and a single constant per-face normal, so it
/// renders with crisp, well-defined edges by default (flatShading has
/// no additional effect on this shape, since every face is already flat
/// by construction).
class Fiber3DWedge {
  final double width;
  final double height;
  final double depth;

  final List<double> positions = [];
  final List<double> normals = [];
  final List<double> uvs = [];
  final List<int> indices = [];

  Fiber3DWedge({
    this.width = 1,
    this.height = 1,
    this.depth = 1,
  }) {
    _build();
  }

  void _build() {
    final w = width / 2;
    final h = height;
    final d = depth / 2;

    // Six corners of the wedge. "Back" = full height (z = -d),
    // "front" = collapsed to the ground (z = +d).
    final a = [-w, 0.0, -d]; // back-bottom-left
    final b = [w, 0.0, -d]; // back-bottom-right
    final c = [-w, h, -d]; // back-top-left
    final d_ = [w, h, -d]; // back-top-right
    final e = [-w, 0.0, d]; // front-bottom-left
    final f = [w, 0.0, d]; // front-bottom-right

    // Bottom face.
    _addQuad(a, b, f, e, [0, -1, 0]);

    // Back (vertical) face.
    _addQuad(a, c, d_, b, [0, 0, -1]);

    // Sloped ramp surface normal computed from the actual slope
    // geometry rather than assumed axis-aligned, since it's tilted.
    final slopeNormal = _normalize([0, depth, height]);
    _addQuad(c, e, f, d_, slopeNormal);

    // Left and right triangular end caps.
    _addTriangle(a, e, c, [-1, 0, 0]);
    _addTriangle(b, d_, f, [1, 0, 0]);
  }

  List<double> _normalize(List<double> v) {
    final len = _len(v);
    if (len == 0) return [0, 0, 0];
    return [v[0] / len, v[1] / len, v[2] / len];
  }

  double _len(List<double> v) =>
      (v[0] * v[0] + v[1] * v[1] + v[2] * v[2]) == 0
          ? 0
          : _sqrt(v[0] * v[0] + v[1] * v[1] + v[2] * v[2]);

  double _sqrt(double x) {
    if (x <= 0) return 0;
    double guess = x / 2;
    for (var i = 0; i < 20; i++) {
      guess = 0.5 * (guess + x / guess);
    }
    return guess;
  }

  void _addQuad(
    List<double> p0,
    List<double> p1,
    List<double> p2,
    List<double> p3,
    List<double> normal,
  ) {
    final base = positions.length ~/ 3;

    positions.addAll([...p0, ...p1, ...p2, ...p3]);
    for (var i = 0; i < 4; i++) {
      normals.addAll(normal);
    }
    uvs.addAll([0, 0, 1, 0, 1, 1, 0, 1]);

    indices.addAll([base, base + 1, base + 2]);
    indices.addAll([base, base + 2, base + 3]);
  }

  void _addTriangle(
    List<double> p0,
    List<double> p1,
    List<double> p2,
    List<double> normal,
  ) {
    final base = positions.length ~/ 3;

    positions.addAll([...p0, ...p1, ...p2]);
    for (var i = 0; i < 3; i++) {
      normals.addAll(normal);
    }
    uvs.addAll([0, 0, 1, 0, 0.5, 1]);

    indices.addAll([base, base + 1, base + 2]);
  }
}