import 'dart:math';

/// A coiled helix/spring: a small circular cross-section swept along a
/// helical path. Built with a direct parametric formula rather than a
/// general curve system, since a helix has a simple closed-form
/// equation no curve/path subsystem needed.
///
/// Original to flutter_fiber no three.js equivalent.
class Fiber3DSpring {
  /// Radius of the helix itself (distance from the central axis to the
  /// center of the coil).
  final double radius;

  /// Radius of the tube/wire making up the coil.
  final double tubeRadius;

  /// Number of full turns of the coil.
  final double turns;

  /// Vertical distance covered by one full turn.
  final double pitch;

  /// Segments along the helix's length, per turn.
  final int radialSegments;

  /// Segments around the tube's own circular cross-section.
  final int tubularSegments;

  final List<double> positions = [];
  final List<double> normals = [];
  final List<double> uvs = [];
  final List<int> indices = [];

  Fiber3DSpring({
    this.radius = 1,
    this.tubeRadius = 0.15,
    this.turns = 4,
    this.pitch = 0.5,
    int radialSegments = 16,
    int tubularSegments = 8,
  })  : radialSegments = max(3, radialSegments),
        tubularSegments = max(3, tubularSegments) {
    _build();
  }

  void _build() {
    final totalSegments = (turns * radialSegments).round();
    final totalAngle = turns * pi * 2;

    for (var i = 0; i <= totalSegments; i++) {
      final t = i / totalSegments;
      final theta = t * totalAngle;

      // Center of the helix's path at this point.
      final centerX = radius * cos(theta);
      final centerY = t * turns * pitch;
      final centerZ = radius * sin(theta);

      // Tangent direction along the helix path (derivative of the
      // center curve w.r.t. theta), used to build a local frame for
      // the tube's circular cross-section.
      final tangentX = -sin(theta);
      final tangentY = pitch / (2 * pi);
      final tangentZ = cos(theta);
      final tangentLen =
          sqrt(tangentX * tangentX + tangentY * tangentY + tangentZ * tangentZ);
      final tx = tangentX / tangentLen;
      final ty = tangentY / tangentLen;
      final tz = tangentZ / tangentLen;

      // Build two vectors perpendicular to the tangent to sweep the
      // tube's circular cross-section around. "Radial" points outward
      // from the helix's central axis; "up" is radial × tangent.
      final radialX = cos(theta);
      final radialY = 0.0;
      final radialZ = sin(theta);

      final upX = radialY * tz - radialZ * ty;
      final upY = radialZ * tx - radialX * tz;
      final upZ = radialX * ty - radialY * tx;
      final upLen = sqrt(upX * upX + upY * upY + upZ * upZ);
      final ux = upLen > 0 ? upX / upLen : 0.0;
      final uy = upLen > 0 ? upY / upLen : 0.0;
      final uz = upLen > 0 ? upZ / upLen : 1.0;

      for (var j = 0; j <= tubularSegments; j++) {
        final phi = (j / tubularSegments) * pi * 2;
        final cosPhi = cos(phi);
        final sinPhi = sin(phi);

        // Offset within the tube's circular cross-section, using the
        // (radial, up) frame built above.
        final offsetX = tubeRadius * (cosPhi * radialX + sinPhi * ux);
        final offsetY = tubeRadius * (cosPhi * radialY + sinPhi * uy);
        final offsetZ = tubeRadius * (cosPhi * radialZ + sinPhi * uz);

        final vx = centerX + offsetX;
        final vy = centerY + offsetY;
        final vz = centerZ + offsetZ;
        positions.addAll([vx, vy, vz]);

        // Normal points from the tube's center-line outward through
        // this vertex same direction as the offset, normalized.
        final nLen = sqrt(
            offsetX * offsetX + offsetY * offsetY + offsetZ * offsetZ);
        if (nLen > 0) {
          normals.addAll([offsetX / nLen, offsetY / nLen, offsetZ / nLen]);
        } else {
          normals.addAll([0, 0, 0]);
        }

        uvs.add(t);
        uvs.add(j / tubularSegments);
      }
    }

    // Indices same quad-strip pattern as Cylinder/Torus.
    final rowLength = tubularSegments + 1;
    for (var i = 0; i < totalSegments; i++) {
      for (var j = 0; j < tubularSegments; j++) {
        final a = i * rowLength + j;
        final b = (i + 1) * rowLength + j;
        final c = (i + 1) * rowLength + j + 1;
        final d = i * rowLength + j + 1;

        indices.addAll([a, b, d]);
        indices.addAll([b, c, d]);
      }
    }
  }
}