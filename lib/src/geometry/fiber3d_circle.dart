import 'dart:math';

/// A flat disc built from triangular segments radiating from a center
/// point, going counter clockwise from a start angle.
///
/// (src/geometries/CircleGeometry.js).
class Fiber3DCircle {
  final double radius;
  final int segments;
  final double thetaStart;
  final double thetaLength;

  final List<double> positions = [];
  final List<double> normals = [];
  final List<double> uvs = [];
  final List<int> indices = [];

  Fiber3DCircle({
    this.radius = 1,
    int segments = 32,
    this.thetaStart = 0,
    this.thetaLength = pi * 2,
  }) : segments = max(3, segments) {
    _build();
  }

  void _build() {
    // Center point.
    positions.addAll([0, 0, 0]);
    normals.addAll([0, 0, 1]);
    uvs.addAll([0.5, 0.5]);

    for (var s = 0; s <= segments; s++) {
      final segment = thetaStart + s / segments * thetaLength;

      final vx = radius * cos(segment);
      final vy = radius * sin(segment);
      const vz = 0.0;

      positions.addAll([vx, vy, vz]);
      normals.addAll([0, 0, 1]);

      final u = (vx / radius + 1) / 2;
      final v = (vy / radius + 1) / 2;
      uvs.addAll([u, v]);
    }

    for (var i = 1; i <= segments; i++) {
      indices.addAll([i, i + 1, 0]);
    }
  }
}