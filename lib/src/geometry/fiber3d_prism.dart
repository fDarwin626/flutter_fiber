import 'dart:math';

/// A true N-sided prism: [sides] flat rectangular side faces around a
/// regular N-gon cross-section, capped top and bottom.
///
/// Distinct from Fiber3DCylinder with a low [sides] count: Cylinder's
/// side normals are smoothly interpolated (normalize(sinTheta, slope,
/// cosTheta)), so it always reads as a faceted approximation of a
/// smooth curved surface, even at low radialSegments. A prism's side
/// faces are flat by construction — each face gets its own 4 unique
/// vertices sharing one outward-facing normal (the face's own midpoint
/// direction), baked into the geometry itself, not a
/// material.flatShading duplicate-vertex hack applied at render time.
///
/// Caps reuse Fiber3DCylinder's own N-gon fan approach exactly (one
/// duplicated center vertex per segment, for correct per-slice UVs) —
/// that part of Cylinder's cap generation is already the right shape
/// for a flat polygon and needs no change.
class Fiber3DPrism {
  final double radius;
  final double height;
  final int sides;
  final double thetaStart;

  final List<double> positions = [];
  final List<double> normals = [];
  final List<double> uvs = [];
  List<double>? colors;
  final List<int> indices = [];

  int _index = 0;
  late final double _halfHeight;
  late final int _sides;

  Fiber3DPrism({
    this.radius = 1,
    this.height = 1,
    int sides = 6,
    this.thetaStart = 0,
  }) : sides = sides {
    // A prism needs at least 3 sides to enclose a volume.
    _sides = sides < 3 ? 3 : sides;
    _halfHeight = height / 2;
    _generateSides();
    _generateCap(true);
    _generateCap(false);
  }

  void _generateSides() {
    final segmentAngle = 2 * pi / _sides;

    for (var i = 0; i < _sides; i++) {
      final theta0 = thetaStart + i * segmentAngle;
      final theta1 = thetaStart + (i + 1) * segmentAngle;
      final mid = (theta0 + theta1) / 2;

      final sinT0 = sin(theta0), cosT0 = cos(theta0);
      final sinT1 = sin(theta1), cosT1 = cos(theta1);

      // One flat normal for the whole face, pointing straight out
      // through the face's angular midpoint.
      final nx = sin(mid), nz = cos(mid);

      // Same a/b/c/d -> [a,b,d],[b,c,d] winding Cylinder's torso uses:
      // a=top-left, b=bottom-left, c=bottom-right, d=top-right.
      positions.addAll([radius * sinT0, _halfHeight, radius * cosT0]); // a
      positions.addAll([radius * sinT0, -_halfHeight, radius * cosT0]); // b
      positions.addAll([radius * sinT1, -_halfHeight, radius * cosT1]); // c
      positions.addAll([radius * sinT1, _halfHeight, radius * cosT1]); // d

      for (var k = 0; k < 4; k++) {
        normals.addAll([nx, 0, nz]);
      }

      // u sweeps 0..1 across this one face; v: top=1, bottom=0.
      uvs.addAll([0, 1, 0, 0, 1, 0, 1, 1]);

      final a = _index, b = _index + 1, c = _index + 2, d = _index + 3;
      indices.addAll([a, b, d, b, c, d]);
      _index += 4;
    }
  }

  /// Ported unchanged (aside from radialSegments -> _sides, and a single
  /// shared [radius] instead of separate top/bottom radii) from
  /// Fiber3DCylinder's own _generateCap — an N-gon fan is already the
  /// correct shape for a flat polygon cap.
  void _generateCap(bool top) {
    final centerIndexStart = _index;
    final sign = top ? 1.0 : -1.0;

    for (var x = 1; x <= _sides; x++) {
      positions.addAll([0, _halfHeight * sign, 0]);
      normals.addAll([0, sign, 0]);
      uvs.addAll([0.5, 0.5]);
      _index++;
    }

    final centerIndexEnd = _index;

    for (var x = 0; x <= _sides; x++) {
      final theta = thetaStart + x * (2 * pi / _sides);
      final cosTheta = cos(theta);
      final sinTheta = sin(theta);

      positions.addAll([
        radius * sinTheta,
        _halfHeight * sign,
        radius * cosTheta,
      ]);
      normals.addAll([0, sign, 0]);

      final uvX = (cosTheta * 0.5) + 0.5;
      final uvY = (sinTheta * 0.5 * sign) + 0.5;
      uvs.addAll([uvX, uvY]);

      _index++;
    }

    for (var x = 0; x < _sides; x++) {
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