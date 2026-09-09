import 'dart:math';

class Fiber3DCylinder {
  final double radiusTop;
  final double radiusBottom;
  final double height;
  final int radialSegments;
  final int heightSegments;
  final bool openEnded;
  final double thetaStart;
  final double thetaLength;

  final List<double> positions = [];
  final List<double> normals = [];
  final List<double> uvs = [];
  final List<int> indices = [];

  int _index = 0;
  late final double _halfHeight;

  Fiber3DCylinder({
    this.radiusTop = 1,
    this.radiusBottom = 1,
    this.height = 1,
    this.radialSegments = 32,
    this.heightSegments = 1,
    this.openEnded = false,
    this.thetaStart = 0,
    this.thetaLength = pi * 2,
  }) {
    _halfHeight = height / 2;
    _generateTorso();

    if (!openEnded) {
      if (radiusTop > 0) _generateCap(true);
      if (radiusBottom > 0) _generateCap(false);
    }
  }

  void _generateTorso() {
    final indexArray = <List<int>>[];

    // Used to calculate the normal's slope component.
    final slope = (radiusBottom - radiusTop) / height;

    for (var y = 0; y <= heightSegments; y++) {
      final indexRow = <int>[];

      final v = y / heightSegments;
      final radius = v * (radiusBottom - radiusTop) + radiusTop;

      for (var x = 0; x <= radialSegments; x++) {
        final u = x / radialSegments;
        final theta = u * thetaLength + thetaStart;

        final sinTheta = sin(theta);
        final cosTheta = cos(theta);

        final vx = radius * sinTheta;
        final vy = -v * height + _halfHeight;
        final vz = radius * cosTheta;
        positions.addAll([vx, vy, vz]);

        // Normal = normalize(sinTheta, slope, cosTheta)
        final len = sqrt(sinTheta * sinTheta + slope * slope + cosTheta * cosTheta);
        normals.addAll([sinTheta / len, slope / len, cosTheta / len]);

        uvs.add(u);
        uvs.add(1 - v);

        indexRow.add(_index++);
      }

      indexArray.add(indexRow);
    }

    for (var x = 0; x < radialSegments; x++) {
      for (var y = 0; y < heightSegments; y++) {
        final a = indexArray[y][x];
        final b = indexArray[y + 1][x];
        final c = indexArray[y + 1][x + 1];
        final d = indexArray[y][x + 1];

        if (radiusTop > 0 || y != 0) {
          indices.addAll([a, b, d]);
        }

        if (radiusBottom > 0 || y != heightSegments - 1) {
          indices.addAll([b, c, d]);
        }
      }
    }
  }

  void _generateCap(bool top) {
    final centerIndexStart = _index;

    final radius = top ? radiusTop : radiusBottom;
    final sign = top ? 1.0 : -1.0;

    // One center vertex per segment, so each cap face gets its own UV.
    for (var x = 1; x <= radialSegments; x++) {
      positions.addAll([0, _halfHeight * sign, 0]);
      normals.addAll([0, sign, 0]);
      uvs.addAll([0.5, 0.5]);
      _index++;
    }

    final centerIndexEnd = _index;

    for (var x = 0; x <= radialSegments; x++) {
      final u = x / radialSegments;
      final theta = u * thetaLength + thetaStart;

      final cosTheta = cos(theta);
      final sinTheta = sin(theta);

      final vx = radius * sinTheta;
      final vy = _halfHeight * sign;
      final vz = radius * cosTheta;
      positions.addAll([vx, vy, vz]);

      normals.addAll([0, sign, 0]);

      final uvX = (cosTheta * 0.5) + 0.5;
      final uvY = (sinTheta * 0.5 * sign) + 0.5;
      uvs.addAll([uvX, uvY]);

      _index++;
    }

    for (var x = 0; x < radialSegments; x++) {
      final c = centerIndexStart + x;
      final i = centerIndexEnd + x;

      if (top) {
        indices.addAll([i, i + 1, c]);
      } else {
        indices.addAll([i + 1, i, c]);
      }
    }
  }
}