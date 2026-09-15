import 'dart:math';

/// A geometry class for representing a torus.
///
/// Ported from three.js's `TorusGeometry` (src/geometries/TorusGeometry.js).
class Fiber3DTorus {
  final double radius;
  final double tube;
  final int radialSegments;
  final int tubularSegments;
  final double arc;
  final double thetaStart;
  final double thetaLength;

  final List<double> positions = [];
  final List<double> normals = [];
  final List<double> uvs = [];
  final List<int> indices = [];

  Fiber3DTorus({
    this.radius = 1,
    this.tube = 0.4,
    int radialSegments = 12,
    int tubularSegments = 48,
    this.arc = pi * 2,
    this.thetaStart = 0,
    this.thetaLength = pi * 2,
  })  : radialSegments = radialSegments.floor(),
        tubularSegments = tubularSegments.floor() {
    _build();
  }

  void _build() {
    for (var j = 0; j <= radialSegments; j++) {
      final v = thetaStart + (j / radialSegments) * thetaLength;

      for (var i = 0; i <= tubularSegments; i++) {
        final u = i / tubularSegments * arc;

        // vertex
        final vx = (radius + tube * cos(v)) * cos(u);
        final vy = (radius + tube * cos(v)) * sin(u);
        final vz = tube * sin(v);

        positions.addAll([vx, vy, vz]);

        // normal — direction from the tube's center circle to the vertex
        final centerX = radius * cos(u);
        final centerY = radius * sin(u);

        var nx = vx - centerX;
        var ny = vy - centerY;
        var nz = vz - 0.0;

        final len = sqrt(nx * nx + ny * ny + nz * nz);
        if (len > 0) {
          nx /= len;
          ny /= len;
          nz /= len;
        }

        normals.addAll([nx, ny, nz]);

        // uv
        uvs.add(i / tubularSegments);
        uvs.add(j / radialSegments);
      }
    }

    // generate indices
    for (var j = 1; j <= radialSegments; j++) {
      for (var i = 1; i <= tubularSegments; i++) {
        final a = (tubularSegments + 1) * j + i - 1;
        final b = (tubularSegments + 1) * (j - 1) + i - 1;
        final c = (tubularSegments + 1) * (j - 1) + i;
        final d = (tubularSegments + 1) * j + i;

        indices.addAll([a, b, d]);
        indices.addAll([b, c, d]);
      }
    }
  }
}