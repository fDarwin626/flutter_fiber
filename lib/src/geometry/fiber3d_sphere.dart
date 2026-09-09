import 'dart:math';

class Fiber3DSphere {
  final double radius;
  final int widthSegments;
  final int heightSegments;
  final double phiStart;
  final double phiLength;
  final double thetaStart;
  final double thetaLength;

  final List<double> positions = [];
  final List<double> normals = [];
  final List<double> uvs = [];
  final List<int> indices = [];

  Fiber3DSphere({
    this.radius = 1,
    int widthSegments = 32,
    int heightSegments = 16,
    this.phiStart = 0,
    this.phiLength = pi * 2,
    this.thetaStart = 0,
    this.thetaLength = pi,
  })  : widthSegments = max(3, widthSegments),
        heightSegments = max(2, heightSegments) {
    _build();
  }

  void _build() {
    final thetaEnd = min(thetaStart + thetaLength, pi);

    var index = 0;
    final grid = <List<int>>[];

    for (var iy = 0; iy <= heightSegments; iy++) {
      final verticesRow = <int>[];

      final v = iy / heightSegments;
      final theta = thetaStart + v * thetaLength;

      final y = radius * cos(theta);
      final ringRadius = sqrt(radius * radius - y * y);

      var uOffset = 0.0;

      if (iy == 0 && thetaStart == 0) {
        uOffset = 0.5 / widthSegments;
      } else if (iy == heightSegments && thetaEnd == pi) {
        uOffset = -0.5 / widthSegments;
      }

      for (var ix = 0; ix <= widthSegments; ix++) {
        final u = ix / widthSegments;
        final phi = phiStart + u * phiLength;

        final x = -ringRadius * cos(phi);
        final z = ringRadius * sin(phi);

        positions.addAll([x, y, z]);

        // Normal = normalized vertex position (sphere is origin-centered).
        final len = sqrt(x * x + y * y + z * z);
        if (len > 0) {
          normals.addAll([x / len, y / len, z / len]);
        } else {
          normals.addAll([0, 0, 0]);
        }

        uvs.add(u + uOffset);
        uvs.add(1 - v);

        verticesRow.add(index++);
      }

      grid.add(verticesRow);
    }

    for (var iy = 0; iy < heightSegments; iy++) {
      for (var ix = 0; ix < widthSegments; ix++) {
        final a = grid[iy][ix + 1];
        final b = grid[iy][ix];
        final c = grid[iy + 1][ix];
        final d = grid[iy + 1][ix + 1];

        if (iy != 0 || thetaStart > 0) {
          indices.addAll([a, b, d]);
        }
        if (iy != heightSegments - 1 || thetaEnd < pi) {
          indices.addAll([b, c, d]);
        }
      }
    }
  }
}