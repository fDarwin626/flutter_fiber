import 'dart:math';

/// A geometry class for representing a capsule.
///
/// Ported from three.js's `CapsuleGeometry` (src/geometries/CapsuleGeometry.js).
class Fiber3DCapsule {
  final double radius;
  final double height;
  final int capSegments;
  final int radialSegments;
  final int heightSegments;

  final List<double> positions = [];
  final List<double> normals = [];
  final List<double> uvs = [];
  final List<int> indices = [];

  Fiber3DCapsule({
    this.radius = 1,
    double height = 1,
    int capSegments = 4,
    int radialSegments = 8,
    int heightSegments = 1,
  })  : height = max(0, height),
        capSegments = max(1, capSegments.floor()),
        radialSegments = max(3, radialSegments.floor()),
        heightSegments = max(1, heightSegments.floor()) {
    _build();
  }

  void _build() {
    final halfHeight = height / 2;
    final capArcLength = (pi / 2) * radius;
    final cylinderPartLength = height;
    final totalArcLength = 2 * capArcLength + cylinderPartLength;

    final numVerticalSegments = capSegments * 2 + heightSegments;
    final verticesPerRow = radialSegments + 1;

    for (var iy = 0; iy <= numVerticalSegments; iy++) {
      double currentArcLength = 0;
      double profileY = 0;
      double profileRadius = 0;
      double normalYComponent = 0;

      if (iy <= capSegments) {
        // bottom cap
        final segmentProgress = iy / capSegments;
        final angle = (segmentProgress * pi) / 2;
        profileY = -halfHeight - radius * cos(angle);
        profileRadius = radius * sin(angle);
        normalYComponent = -radius * cos(angle);
        currentArcLength = segmentProgress * capArcLength;
      } else if (iy <= capSegments + heightSegments) {
        // middle section
        final segmentProgress = (iy - capSegments) / heightSegments;
        profileY = -halfHeight + segmentProgress * height;
        profileRadius = radius;
        normalYComponent = 0;
        currentArcLength = capArcLength + segmentProgress * cylinderPartLength;
      } else {
        // top cap
        final segmentProgress =
            (iy - capSegments - heightSegments) / capSegments;
        final angle = (segmentProgress * pi) / 2;
        profileY = halfHeight + radius * sin(angle);
        profileRadius = radius * cos(angle);
        normalYComponent = radius * sin(angle);
        currentArcLength =
            capArcLength + cylinderPartLength + segmentProgress * capArcLength;
      }

      final v = max(0.0, min(1.0, currentArcLength / totalArcLength));

      // special case for the poles
      var uOffset = 0.0;
      if (iy == 0) {
        uOffset = 0.5 / radialSegments;
      } else if (iy == numVerticalSegments) {
        uOffset = -0.5 / radialSegments;
      }

      for (var ix = 0; ix <= radialSegments; ix++) {
        final u = ix / radialSegments;
        final theta = u * pi * 2;

        final sinTheta = sin(theta);
        final cosTheta = cos(theta);

        // vertex
        final vx = -profileRadius * cosTheta;
        final vy = profileY;
        final vz = profileRadius * sinTheta;
        positions.addAll([vx, vy, vz]);

        // normal
        var nx = -profileRadius * cosTheta;
        var ny = normalYComponent;
        var nz = profileRadius * sinTheta;

        final len = sqrt(nx * nx + ny * ny + nz * nz);
        if (len > 0) {
          nx /= len;
          ny /= len;
          nz /= len;
        }

        normals.addAll([nx, ny, nz]);

        // uv
        uvs.add(u + uOffset);
        uvs.add(v);
      }

      if (iy > 0) {
        final prevIndexRow = (iy - 1) * verticesPerRow;
        for (var ix = 0; ix < radialSegments; ix++) {
          final i1 = prevIndexRow + ix;
          final i2 = prevIndexRow + ix + 1;
          final i3 = iy * verticesPerRow + ix;
          final i4 = iy * verticesPerRow + ix + 1;

          indices.addAll([i1, i2, i3]);
          indices.addAll([i2, i4, i3]);
        }
      }
    }
  }
}