import 'dart:math';

/// A box with rounded/chamfered edges and corners, using a superellipsoid
/// blend: start from a normal subdivided box grid, then pull each vertex
/// toward a rounded corner shape based on how close it is to an edge or
/// corner. `chamferAmount` (0 = sharp box, close to 1 = fully rounded,
/// like a sphere-ish blob) controls the strength of the effect.
///
/// Original to flutter_fiber no three.js equivalent. This is a
/// simplified rounding technique, not a true constant-radius edge
/// fillet it gives a convincing chamfered look without the
/// complexity of generating and stitching separate fillet surfaces.
class Fiber3DChamferedBox {
  final double width;
  final double height;
  final double depth;
  final double chamferAmount;
  final int segments;

  final List<double> positions = [];
  final List<double> normals = [];
  final List<double> uvs = [];
  final List<int> indices = [];

  Fiber3DChamferedBox({
    this.width = 1,
    this.height = 1,
    this.depth = 1,
    double chamferAmount = 0.2,
    int segments = 8,
  })  : chamferAmount = chamferAmount.clamp(0.0, 0.95),
        segments = max(2, segments) {
    _build();
  }

  void _build() {
    // Build each of the 6 faces as a subdivided grid, matching
    // Fiber3DBox's own construction pattern (axis-swap + direction
    // arguments per face), then apply the corner-rounding pass to
    // every vertex afterward.
    _buildFace(2, 1, 0, -1, -1, depth, height, width); // px
    _buildFace(2, 1, 0, 1, -1, depth, height, -width); // nx
    _buildFace(0, 2, 1, 1, 1, width, depth, height); // py
    _buildFace(0, 2, 1, 1, -1, width, depth, -height); // ny
    _buildFace(0, 1, 2, 1, -1, width, height, depth); // pz
    _buildFace(0, 1, 2, -1, -1, width, height, -depth); // nz

    _applyRounding();
  }

  void _buildFace(
    int u,
    int v,
    int w,
    double uDir,
    double vDir,
    double planeWidth,
    double planeHeight,
    double planeDepth,
  ) {
    final segmentWidth = planeWidth / segments;
    final segmentHeight = planeHeight / segments;
    final widthHalf = planeWidth / 2;
    final heightHalf = planeHeight / 2;
    final depthHalf = planeDepth / 2;

    final base = positions.length ~/ 3;

    for (var iy = 0; iy <= segments; iy++) {
      final y = iy * segmentHeight - heightHalf;
      for (var ix = 0; ix <= segments; ix++) {
        final x = ix * segmentWidth - widthHalf;

        final vertex = List<double>.filled(3, 0);
        vertex[u] = x * uDir;
        vertex[v] = y * vDir;
        vertex[w] = depthHalf;
        positions.addAll(vertex);

        final normal = List<double>.filled(3, 0);
        normal[w] = planeDepth > 0 ? 1 : -1;
        normals.addAll(normal);

        uvs.add(ix / segments);
        uvs.add(1 - (iy / segments));
      }
    }

    final gridX1 = segments + 1;
    for (var iy = 0; iy < segments; iy++) {
      for (var ix = 0; ix < segments; ix++) {
        final a = base + ix + gridX1 * iy;
        final b = base + ix + gridX1 * (iy + 1);
        final c = base + (ix + 1) + gridX1 * (iy + 1);
        final d = base + (ix + 1) + gridX1 * iy;

        indices.addAll([a, b, d]);
        indices.addAll([b, c, d]);
      }
    }
  }

  void _applyRounding() {
    final halfW = width / 2;
    final halfH = height / 2;
    final halfD = depth / 2;

    // Superellipsoid exponent: lower chamferAmount -> higher exponent
    // -> sharper box; higher chamferAmount -> lower exponent -> rounder.
    final exponent = 2.0 + (1.0 - chamferAmount) * 6.0;

    for (var i = 0; i < positions.length; i += 3) {
      final nx = positions[i] / halfW;
      final ny = positions[i + 1] / halfH;
      final nz = positions[i + 2] / halfD;

      final denom = pow(nx.abs(), exponent) +
          pow(ny.abs(), exponent) +
          pow(nz.abs(), exponent);
      final scale =
          denom > 0 ? 1.0 / pow(denom, 1.0 / exponent) : 1.0;

      positions[i] = nx * scale * halfW;
      positions[i + 1] = ny * scale * halfH;
      positions[i + 2] = nz * scale * halfD;
    }

    // Recompute per-vertex normals from scratch after rounding, since
    // the original flat face normals no longer match the now-curved
    // surface. Averages face normals into shared vertices for smooth
    // shading across the rounded regions sharper exponents still
    // read as mostly-flat faces since the math approaches a true box
    // as chamferAmount -> 0.
    final accum = List<double>.filled(normals.length, 0.0);
    for (var i = 0; i + 2 < indices.length; i += 3) {
      final ia = indices[i], ib = indices[i + 1], ic = indices[i + 2];

      final ax = positions[ia * 3], ay = positions[ia * 3 + 1], az = positions[ia * 3 + 2];
      final bx = positions[ib * 3], by = positions[ib * 3 + 1], bz = positions[ib * 3 + 2];
      final cx = positions[ic * 3], cy = positions[ic * 3 + 1], cz = positions[ic * 3 + 2];

      final e1x = bx - ax, e1y = by - ay, e1z = bz - az;
      final e2x = cx - ax, e2y = cy - ay, e2z = cz - az;

      final fnx = e1y * e2z - e1z * e2y;
      final fny = e1z * e2x - e1x * e2z;
      final fnz = e1x * e2y - e1y * e2x;

      for (final idx in [ia, ib, ic]) {
        accum[idx * 3] += fnx;
        accum[idx * 3 + 1] += fny;
        accum[idx * 3 + 2] += fnz;
      }
    }

    for (var i = 0; i < normals.length; i += 3) {
      final len = sqrt(accum[i] * accum[i] +
          accum[i + 1] * accum[i + 1] +
          accum[i + 2] * accum[i + 2]);
      if (len > 0) {
        normals[i] = accum[i] / len;
        normals[i + 1] = accum[i + 1] / len;
        normals[i + 2] = accum[i + 2] / len;
      }
    }
  }
}