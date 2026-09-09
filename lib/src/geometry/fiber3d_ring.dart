import 'dart:math';

class Fiber3DRing {
  final double innerRadius;
  final double outerRadius;
  final int thetaSegments;
  final int phiSegments;
  final double thetaStart;
  final double thetaLength;

  final List<double> positions = [];
  final List<double> normals = [];
  final List<double> uvs = [];
  final List<int> indices = [];

  Fiber3DRing({
    this.innerRadius = 0.5,
    this.outerRadius = 1,
    int thetaSegments = 32,
    int phiSegments = 1,
    this.thetaStart = 0,
    this.thetaLength = pi * 2,
  })  : thetaSegments = max(3, thetaSegments),
        phiSegments = max(1, phiSegments) {
    _build();
  }

  void _build() {
    var radius = innerRadius;
    final radiusStep = (outerRadius - innerRadius) / phiSegments;

    for (var j = 0; j <= phiSegments; j++) {
      for (var i = 0; i <= thetaSegments; i++) {
        final segment = thetaStart + i / thetaSegments * thetaLength;

        final x = radius * cos(segment);
        final y = radius * sin(segment);

        positions.addAll([x, y, 0]);
        normals.addAll([0, 0, 1]);

        final u = (x / outerRadius + 1) / 2;
        final v = (y / outerRadius + 1) / 2;
        uvs.addAll([u, v]);
      }

      radius += radiusStep;
    }

    for (var j = 0; j < phiSegments; j++) {
      final thetaSegmentLevel = j * (thetaSegments + 1);

      for (var i = 0; i < thetaSegments; i++) {
        final segment = i + thetaSegmentLevel;

        final a = segment;
        final b = segment + thetaSegments + 1;
        final c = segment + thetaSegments + 2;
        final d = segment + 1;

        indices.addAll([a, b, d]);
        indices.addAll([b, c, d]);
      }
    }
  }
}