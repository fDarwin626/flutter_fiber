import 'dart:math';

/// A flat, filled N-pointed star (or gear silhouette, when points is
/// high and the two radii are close together) or a solid, extruded
/// version of the same outline when `depth` is greater than 0.
///
/// The outline alternates between `outerRadius` (points) and
/// `innerRadius` (valleys) as it sweeps around, same construction as
/// Fiber3DCircle's triangle fan.
///
/// Original to flutter_fiber no three.js equivalent.
class Fiber3DStar {
  final double outerRadius;
  final double innerRadius;
  final int points;

  /// Thickness of the star along Z. `0` (the default) gives the
  /// original flat, single-sided star same behavior as before this
  /// parameter existed. Any positive value gives a solid star with a
  /// front face, back face, and connecting side walls.
  final double depth;

  final List<double> positions = [];
  final List<double> normals = [];
  final List<double> uvs = [];
  final List<int> indices = [];

  Fiber3DStar({
    this.outerRadius = 1,
    this.innerRadius = 0.5,
    int points = 5,
    this.depth = 0,
  }) : points = max(3, points) {
    if (depth <= 0) {
      _buildFlat();
    } else {
      _buildSolid();
    }
  }

  /// Original flat construction — a center vertex plus a triangle fan,
  /// single-sided (normal points +Z only), unchanged from before.
  void _buildFlat() {
    positions.addAll([0, 0, 0]);
    normals.addAll([0, 0, 1]);
    uvs.addAll([0.5, 0.5]);

    final segments = points * 2;

    for (var s = 0; s <= segments; s++) {
      final angle = (s / segments) * pi * 2;
      final radius = (s % 2 == 0) ? outerRadius : innerRadius;

      final vx = radius * cos(angle);
      final vy = radius * sin(angle);

      positions.addAll([vx, vy, 0]);
      normals.addAll([0, 0, 1]);

      final u = (vx / outerRadius + 1) / 2;
      final v = (vy / outerRadius + 1) / 2;
      uvs.addAll([u, v]);
    }

    for (var i = 1; i <= segments; i++) {
      indices.addAll([i, i + 1, 0]);
    }
  }

  /// Solid construction: the same star outline duplicated as a front
  /// cap (z = +halfDepth) and a back cap (z = -halfDepth), each fan-
  /// triangulated independently, connected around the perimeter by a
  /// ring of quads whose normals point outward radially rather than
  /// along Z.
  void _buildSolid() {
    final halfDepth = depth / 2;
    final segments = points * 2;

    // Precompute the flat 2D outline once (x, y pairs), reused for
    // both caps and the side wall.
    final outlineX = <double>[];
    final outlineY = <double>[];
    for (var s = 0; s <= segments; s++) {
      final angle = (s / segments) * pi * 2;
      final radius = (s % 2 == 0) ? outerRadius : innerRadius;
      outlineX.add(radius * cos(angle));
      outlineY.add(radius * sin(angle));
    }

    // --- Front cap (z = +halfDepth), normal +Z ---
    final frontCenterIndex = positions.length ~/ 3;
    positions.addAll([0, 0, halfDepth]);
    normals.addAll([0, 0, 1]);
    uvs.addAll([0.5, 0.5]);

    final frontRingStart = positions.length ~/ 3;
    for (var s = 0; s <= segments; s++) {
      positions.addAll([outlineX[s], outlineY[s], halfDepth]);
      normals.addAll([0, 0, 1]);
      uvs.addAll([(outlineX[s] / outerRadius + 1) / 2, (outlineY[s] / outerRadius + 1) / 2]);
    }
    for (var i = 0; i < segments; i++) {
      indices.addAll([frontRingStart + i, frontRingStart + i + 1, frontCenterIndex]);
    }

    // --- Back cap (z = -halfDepth), normal -Z, wound oppositely so it
    // faces outward (away from the front cap) rather than inward ---
    final backCenterIndex = positions.length ~/ 3;
    positions.addAll([0, 0, -halfDepth]);
    normals.addAll([0, 0, -1]);
    uvs.addAll([0.5, 0.5]);

    final backRingStart = positions.length ~/ 3;
    for (var s = 0; s <= segments; s++) {
      positions.addAll([outlineX[s], outlineY[s], -halfDepth]);
      normals.addAll([0, 0, -1]);
      uvs.addAll([(outlineX[s] / outerRadius + 1) / 2, (outlineY[s] / outerRadius + 1) / 2]);
    }
    for (var i = 0; i < segments; i++) {
      // Reversed winding order vs. the front cap's fan, since this
      // cap faces the opposite direction.
      indices.addAll([backRingStart + i + 1, backRingStart + i, backCenterIndex]);
    }

    // --- Side walls: one quad per outline edge, connecting the front
    // and back rings, with an outward-pointing radial normal computed
    // per edge (perpendicular to that edge's direction, not just
    // copied from the flat caps) ---
    for (var s = 0; s < segments; s++) {
      final x0 = outlineX[s], y0 = outlineY[s];
      final x1 = outlineX[s + 1], y1 = outlineY[s + 1];

      // Outward normal for this edge: perpendicular to the edge
      // direction (x1-x0, y1-y0), rotated 90°, then normalized.
      var nx = y1 - y0;
      var ny = -(x1 - x0);
      final len = sqrt(nx * nx + ny * ny);
      if (len > 0) {
        nx /= len;
        ny /= len;
      }

      final base = positions.length ~/ 3;

      // Front-top, back-top, back-bottom, front-bottom of this wall
      // segment (quad), duplicated vertices so this edge gets its own
      // flat normal rather than blending with neighboring edges.
      positions.addAll([x0, y0, halfDepth]);
      positions.addAll([x0, y0, -halfDepth]);
      positions.addAll([x1, y1, -halfDepth]);
      positions.addAll([x1, y1, halfDepth]);
      for (var i = 0; i < 4; i++) {
        normals.addAll([nx, ny, 0]);
      }
      uvs.addAll([0, 1, 0, 0, 1, 0, 1, 1]);

      indices.addAll([base, base + 1, base + 2]);
      indices.addAll([base, base + 2, base + 3]);
    }
  }
}