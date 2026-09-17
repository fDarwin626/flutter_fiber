import 'dart:math';

/// Creates meshes with axial symmetry, like vases or bowls, by revolving
/// a 2D profile (an array of [x, y] points) around the Y axis.
///
/// Ported from three.js's `LatheGeometry`
/// (src/geometries/LatheGeometry.js). Each point's x-coordinate should
/// be greater than zero (it becomes the radius at that height).
class Fiber3DLathe {
  /// Profile points as [x, y] pairs x is distance from the Y axis,
  /// y is height. Matches three.js's default profile if none is given
  /// (a simple lens/almond shape).
  final List<List<double>> points;
  final int segments;
  final double phiStart;
  final double phiLength;

  final List<double> positions = [];
  final List<double> normals = [];
  final List<double> uvs = [];
  final List<int> indices = [];

  Fiber3DLathe({
    List<List<double>>? points,
    int segments = 12,
    this.phiStart = 0,
    double phiLength = pi * 2,
  })  : points = points ?? [
          [0, -0.5],
          [0.5, 0],
          [0, 0.5],
        ],
        segments = segments.floor(),
        phiLength = phiLength.clamp(0, pi * 2) {
    _build();
  }

  void _build() {
    final inverseSegments = 1.0 / segments;

    // Pre-compute normals for the initial "meridian" (the flat 2D
    // profile before revolving), by averaging each edge's perpendicular
    // direction with the previous one — same edge-miter approach the
    // source uses.
    final initNormals = <double>[];
    var prevNx = 0.0, prevNy = 0.0, prevNz = 0.0;

    for (var j = 0; j <= points.length - 1; j++) {
      if (j == 0) {
        // Special handling for the first vertex on the path.
        final dx = points[j + 1][0] - points[j][0];
        final dy = points[j + 1][1] - points[j][1];

        var nx = dy * 1.0;
        var ny = -dx;
        const nz = 0.0;

        prevNx = nx;
        prevNy = ny;
        prevNz = nz;

        final len = sqrt(nx * nx + ny * ny + nz * nz);
        if (len > 0) {
          nx /= len;
          ny /= len;
        }
        initNormals.addAll([nx, ny, 0.0]);
      } else if (j == points.length - 1) {
        // Special handling for the last vertex on the path.
        initNormals.addAll([prevNx, prevNy, prevNz]);
      } else {
        // Default handling for all vertices in between.
        final dx = points[j + 1][0] - points[j][0];
        final dy = points[j + 1][1] - points[j][1];

        final curNx = dy * 1.0;
        final curNy = -dx;
        const curNz = 0.0;

        var nx = curNx + prevNx;
        var ny = curNy + prevNy;
        var nz = curNz + prevNz;

        final len = sqrt(nx * nx + ny * ny + nz * nz);
        if (len > 0) {
          nx /= len;
          ny /= len;
          nz /= len;
        }
        initNormals.addAll([nx, ny, nz]);

        prevNx = curNx;
        prevNy = curNy;
        prevNz = curNz;
      }
    }

    // Generate vertices, UVs, and normals by revolving the profile.
    for (var i = 0; i <= segments; i++) {
      final phi = phiStart + i * inverseSegments * phiLength;

      final sinPhi = sin(phi);
      final cosPhi = cos(phi);

      for (var j = 0; j <= points.length - 1; j++) {
        final px = points[j][0];
        final py = points[j][1];

        final vx = px * sinPhi;
        final vy = py;
        final vz = px * cosPhi;
        positions.addAll([vx, vy, vz]);

        final u = i / segments;
        final v = j / (points.length - 1);
        uvs.addAll([u, v]);

        final nx = initNormals[3 * j] * sinPhi;
        final ny = initNormals[3 * j + 1];
        final nz = initNormals[3 * j] * cosPhi;
        normals.addAll([nx, ny, nz]);
      }
    }

    // Indices.
    for (var i = 0; i < segments; i++) {
      for (var j = 0; j < points.length - 1; j++) {
        final base = j + i * points.length;

        final a = base;
        final b = base + points.length;
        final c = base + points.length + 1;
        final d = base + 1;

        indices.addAll([a, b, d]);
        indices.addAll([c, d, b]);
      }
    }
  }
}