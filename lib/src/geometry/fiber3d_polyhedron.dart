import 'dart:math';

/// A polyhedron is a solid in three dimensions with flat faces. Takes a
/// set of base vertices/indices, subdivides them for smoothness, then
/// projects everything onto a sphere of the given radius.
///
/// Ported from three.js's `PolyhedronGeometry`
/// (src/geometries/PolyhedronGeometry.js). Produces non-indexed
/// (triangle-soup) geometry, same as the original each triangle owns
/// its own 3 vertices, which is what lets detail=0 (the default) render
/// with sharp flat-shaded faces via one normal per triangle. A
/// sequential index list (0, 1, 2, 3, ...) is generated here so this
/// still fits flutter_fiber's indexed-draw pipeline without changing
/// the vertex layout.
class Fiber3DPolyhedron {
  final List<double> baseVertices;
  final List<int> baseIndices;
  final double radius;
  final int detail;

  final List<double> positions = [];
  final List<double> normals = [];
  final List<double> uvs = [];
  final List<int> indices = [];

  Fiber3DPolyhedron(
    this.baseVertices,
    this.baseIndices, {
    this.radius = 1,
    this.detail = 0,
  }) {
    _build();
  }

  List<double> _getVertexByIndex(int index) {
    final stride = index * 3;
    return [
      baseVertices[stride],
      baseVertices[stride + 1],
      baseVertices[stride + 2],
    ];
  }

  List<double> _lerp3(List<double> a, List<double> b, double t) {
    return [
      a[0] + (b[0] - a[0]) * t,
      a[1] + (b[1] - a[1]) * t,
      a[2] + (b[2] - a[2]) * t,
    ];
  }

  void _pushVertex(List<double> v) {
    positions.addAll([v[0], v[1], v[2]]);
  }

  void _subdivideFace(List<double> a, List<double> b, List<double> c, int detail) {
    final cols = detail + 1;

    // v[i][j] grid used to build the subdivision, matching the source's
    // structure exactly (ragged: row length shrinks as i grows).
    final v = List.generate(cols + 1, (_) => <List<double>>[]);

    for (var i = 0; i <= cols; i++) {
      final aj = _lerp3(a, c, i / cols);
      final bj = _lerp3(b, c, i / cols);

      final rows = cols - i;
      for (var j = 0; j <= rows; j++) {
        if (j == 0 && i == cols) {
          v[i].add(aj);
        } else {
          v[i].add(_lerp3(aj, bj, j / rows));
        }
      }
    }

    for (var i = 0; i < cols; i++) {
      for (var j = 0; j < 2 * (cols - i) - 1; j++) {
        final k = (j / 2).floor();

        if (j % 2 == 0) {
          _pushVertex(v[i][k + 1]);
          _pushVertex(v[i + 1][k]);
          _pushVertex(v[i][k]);
        } else {
          _pushVertex(v[i][k + 1]);
          _pushVertex(v[i + 1][k + 1]);
          _pushVertex(v[i + 1][k]);
        }
      }
    }
  }

  void _subdivide(int detail) {
    for (var i = 0; i < baseIndices.length; i += 3) {
      final a = _getVertexByIndex(baseIndices[i]);
      final b = _getVertexByIndex(baseIndices[i + 1]);
      final c = _getVertexByIndex(baseIndices[i + 2]);
      _subdivideFace(a, b, c, detail);
    }
  }

  void _applyRadius(double radius) {
    for (var i = 0; i < positions.length; i += 3) {
      var x = positions[i], y = positions[i + 1], z = positions[i + 2];
      final len = sqrt(x * x + y * y + z * z);
      if (len > 0) {
        x = x / len * radius;
        y = y / len * radius;
        z = z / len * radius;
      }
      positions[i] = x;
      positions[i + 1] = y;
      positions[i + 2] = z;
    }
  }

  double _azimuth(double x, double y, double z) => atan2(z, -x);
  double _inclination(double x, double y, double z) =>
      atan2(-y, sqrt(x * x + z * z));

  void _generateUVs() {
    for (var i = 0; i < positions.length; i += 3) {
      final x = positions[i], y = positions[i + 1], z = positions[i + 2];
      final u = _azimuth(x, y, z) / 2 / pi + 0.5;
      final vv = _inclination(x, y, z) / pi + 0.5;
      uvs.addAll([u, 1 - vv]);
    }

    _correctUVs();
    _correctSeam();
  }

  void _correctSeam() {
    // Handle a face straddling the UV seam (three.js issue #3269).
    for (var i = 0; i < uvs.length; i += 6) {
      final x0 = uvs[i], x1 = uvs[i + 2], x2 = uvs[i + 4];
      final maxX = [x0, x1, x2].reduce(max);
      final minX = [x0, x1, x2].reduce(min);

      // 0.9/0.1 thresholds are arbitrary, matching the source.
      if (maxX > 0.9 && minX < 0.1) {
        if (x0 < 0.2) uvs[i] += 1;
        if (x1 < 0.2) uvs[i + 2] += 1;
        if (x2 < 0.2) uvs[i + 4] += 1;
      }
    }
  }

  void _correctUV(int stride, double origU, double vx, double vz, double azi) {
    if (azi < 0 && origU == 1) {
      uvs[stride] = origU - 1;
    }
    if (vx == 0 && vz == 0) {
      uvs[stride] = azi / 2 / pi + 0.5;
    }
  }

  void _correctUVs() {
    var i = 0, j = 0;
    while (i < positions.length) {
      final ax = positions[i], ay = positions[i + 1], az = positions[i + 2];
      final bx = positions[i + 3], by = positions[i + 4], bz = positions[i + 5];
      final cx = positions[i + 6], cy = positions[i + 7], cz = positions[i + 8];

      final uvAx = uvs[j], uvBx = uvs[j + 2], uvCx = uvs[j + 4];

      final centroidX = (ax + bx + cx) / 3;
      final centroidY = (ay + by + cy) / 3;
      final centroidZ = (az + bz + cz) / 3;
      final azi = _azimuth(centroidX, centroidY, centroidZ);

      _correctUV(j, uvAx, ax, az, azi);
      _correctUV(j + 2, uvBx, bx, bz, azi);
      _correctUV(j + 4, uvCx, cx, cz, azi);

      i += 9;
      j += 6;
    }
  }

  void _computeFlatNormals() {
    // Non-indexed triangle soup: one face normal per triangle, assigned
    // to all 3 of that triangle's vertices  matches three.js's
    // computeVertexNormals() when there's no index buffer.
    normals
      ..clear()
      ..addAll(List<double>.filled(positions.length, 0.0));

    for (var i = 0; i < positions.length; i += 9) {
      final ax = positions[i], ay = positions[i + 1], az = positions[i + 2];
      final bx = positions[i + 3], by = positions[i + 4], bz = positions[i + 5];
      final cx = positions[i + 6], cy = positions[i + 7], cz = positions[i + 8];

      // cb = C - B, ab = A - B, normal = cross(cb, ab) exact order
      // three.js uses, then normalized.
      final cbx = cx - bx, cby = cy - by, cbz = cz - bz;
      final abx = ax - bx, aby = ay - by, abz = az - bz;

      var nx = cby * abz - cbz * aby;
      var ny = cbz * abx - cbx * abz;
      var nz = cbx * aby - cby * abx;

      final len = sqrt(nx * nx + ny * ny + nz * nz);
      if (len > 0) {
        nx /= len;
        ny /= len;
        nz /= len;
      }

      for (var v = 0; v < 3; v++) {
        normals[i + v * 3] = nx;
        normals[i + v * 3 + 1] = ny;
        normals[i + v * 3 + 2] = nz;
      }
    }
  }

  void _computeSmoothNormals() {
    // detail > 0: normals start as a copy of the (already sphere-radius
    // scaled) positions, then get normalized to unit length in place
    // an approximation of the true sphere normal that improves as
    // subdivision detail increases.
    normals
      ..clear()
      ..addAll(positions);

    for (var i = 0; i < normals.length; i += 3) {
      final x = normals[i], y = normals[i + 1], z = normals[i + 2];
      final len = sqrt(x * x + y * y + z * z);
      if (len > 0) {
        normals[i] = x / len;
        normals[i + 1] = y / len;
        normals[i + 2] = z / len;
      }
    }
  }

  void _build() {
    _subdivide(detail);
    _applyRadius(radius);
    _generateUVs();

    if (detail == 0) {
      _computeFlatNormals();
    } else {
      _computeSmoothNormals();
    }

    // Non-indexed source data sequential index list keeps this
    // compatible with flutter_fiber's indexed-draw pipeline without
    // altering the vertex layout (still no sharing between triangles,
    // same as the original).
    for (var i = 0; i < positions.length ~/ 3; i++) {
      indices.add(i);
    }
  }
}