import 'dart:math';

/// Creates a torus knot, the particular shape of which is defined by a
/// pair of coprime integers, p and q. If p and q are not coprime, the
/// result will be a torus link.
///
/// Ported from three.js's `TorusKnotGeometry`
/// (src/geometries/TorusKnotGeometry.js).
class Fiber3DTorusKnot {
  final double radius;
  final double tube;
  final int tubularSegments;
  final int radialSegments;
  final double p;
  final double q;

  final List<double> positions = [];
  final List<double> normals = [];
  final List<double> uvs = [];
  final List<int> indices = [];

  Fiber3DTorusKnot({
    this.radius = 1,
    this.tube = 0.4,
    int tubularSegments = 64,
    int radialSegments = 8,
    this.p = 2,
    this.q = 3,
  })  : tubularSegments = tubularSegments.floor(),
        radialSegments = radialSegments.floor() {
    _build();
  }

  // Calculates the current position on the torus curve for parameter u.
  List<double> _calculatePositionOnCurve(double u) {
    final cu = cos(u);
    final su = sin(u);
    final quOverP = q / p * u;
    final cs = cos(quOverP);

    final x = radius * (2 + cs) * 0.5 * cu;
    final y = radius * (2 + cs) * su * 0.5;
    final z = radius * sin(quOverP) * 0.5;

    return [x, y, z];
  }

  void _build() {
    for (var i = 0; i <= tubularSegments; i++) {
      // The radian "u" gives the position on the torus curve for this
      // tubular segment.
      final u = i / tubularSegments * p * pi * 2;

      // P1 is the current position on the curve, P2 is a little farther
      // ahead — used to build an orthonormal basis (B, N) at this point.
      final p1 = _calculatePositionOnCurve(u);
      final p2 = _calculatePositionOnCurve(u + 0.01);

      final p1x = p1[0], p1y = p1[1], p1z = p1[2];
      final p2x = p2[0], p2y = p2[1], p2z = p2[2];

      // T = P2 - P1, N = P2 + P1 (temporary, before orthogonalizing)
      final tx = p2x - p1x, ty = p2y - p1y, tz = p2z - p1z;
      var nx = p2x + p1x, ny = p2y + p1y, nz = p2z + p1z;

      // B = T x N
      var bx = ty * nz - tz * ny;
      var by = tz * nx - tx * nz;
      var bz = tx * ny - ty * nx;

      // N = B x T (re-orthogonalize N against T)
      nx = by * tz - bz * ty;
      ny = bz * tx - bx * tz;
      nz = bx * ty - by * tx;

      // Normalize B and N. T can be ignored — it's not used further.
      final bLen = sqrt(bx * bx + by * by + bz * bz);
      if (bLen > 0) {
        bx /= bLen;
        by /= bLen;
        bz /= bLen;
      }
      final nLen = sqrt(nx * nx + ny * ny + nz * nz);
      if (nLen > 0) {
        nx /= nLen;
        ny /= nLen;
        nz /= nLen;
      }

      for (var j = 0; j <= radialSegments; j++) {
        // The vertices are an extrusion of the torus curve. Since the
        // extrusion shape lies in the xy-plane, no z-value is needed here.
        final v = j / radialSegments * pi * 2;
        final cx = -tube * cos(v);
        final cy = tube * sin(v);

        // Orient the extrusion with the (N, B) basis, then offset from
        // the current curve position P1.
        final vx = p1x + (cx * nx + cy * bx);
        final vy = p1y + (cx * ny + cy * by);
        final vz = p1z + (cx * nz + cy * bz);

        positions.addAll([vx, vy, vz]);

        // Normal: P1 is always the center of the extrusion at this
        // point, so vertex - P1, normalized, is the surface normal.
        var normX = vx - p1x, normY = vy - p1y, normZ = vz - p1z;
        final normLen = sqrt(normX * normX + normY * normY + normZ * normZ);
        if (normLen > 0) {
          normX /= normLen;
          normY /= normLen;
          normZ /= normLen;
        }
        normals.addAll([normX, normY, normZ]);

        uvs.add(i / tubularSegments);
        uvs.add(j / radialSegments);
      }
    }

    // generate indices
    for (var j = 1; j <= tubularSegments; j++) {
      for (var i = 1; i <= radialSegments; i++) {
        final a = (radialSegments + 1) * (j - 1) + (i - 1);
        final b = (radialSegments + 1) * j + (i - 1);
        final c = (radialSegments + 1) * j + i;
        final d = (radialSegments + 1) * (j - 1) + i;

        indices.addAll([a, b, d]);
        indices.addAll([b, c, d]);
      }
    }
  }
}