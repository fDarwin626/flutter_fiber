import 'dart:math';
import 'fiber3d_matrix4.dart';
import 'fiber3d_vector3.dart';

/// A quaternion, used to represent rotations for [Fiber3DObject] and
/// [Fiber3DCamera].
///
/// Ported from three.js's `Quaternion`, scoped to what a mutable scene
/// graph actually needs: construction/conversion, composition, and
/// normalization. Slerp/rotateTowards/angleTo (animation-blending only)
/// and array/JSON serialization are dropped — no animation system or
/// save/load format exists yet.

class Fiber3DQuaternion {
  double x;
  double y;
  double z;
  double w;

  /// Fired on most mutations — same cross-sync mechanism as
  /// [Fiber3DMutableVector3.onChange], used by Fiber3DObject to keep
  /// rotation (Euler) in sync when the quaternion is changed directly
  /// (e.g. via rotateOnAxis/applyQuaternion), not just the other way
  /// around.
  void Function()? onChange;

  Fiber3DQuaternion([this.x = 0, this.y = 0, this.z = 0, this.w = 1]);

  Fiber3DQuaternion.identity() : x = 0, y = 0, z = 0, w = 1;

  void set(double x, double y, double z, double w) {
    this.x = x;
    this.y = y;
    this.z = z;
    this.w = w;
    onChange?.call();
  }

  void copy(Fiber3DQuaternion q) {
    x = q.x;
    y = q.y;
    z = q.z;
    w = q.w;
    onChange?.call();
  }

  Fiber3DQuaternion clone() => Fiber3DQuaternion(x, y, z, w);

  void identityReset() {
    x = 0;
    y = 0;
    z = 0;
    w = 1;
  }

  /// Sets this quaternion from Euler angles (radians), XYZ order the
  /// only order flutter_fiber v1 supports (three.js supports 6; a
  /// configurable rotation order isn't in the PRD's surface).
  ///
  /// [notify] defaults to true; Fiber3DObject passes false when this is
  /// called from its own rotation-changed handler, to avoid an infinite
  /// notify loop between rotation and quaternion.
  void setFromEuler(double ex, double ey, double ez, {bool notify = true}) {
    final c1 = cos(ex / 2), c2 = cos(ey / 2), c3 = cos(ez / 2);
    final s1 = sin(ex / 2), s2 = sin(ey / 2), s3 = sin(ez / 2);

    x = s1 * c2 * c3 + c1 * s2 * s3;
    y = c1 * s2 * c3 - s1 * c2 * s3;
    z = c1 * c2 * s3 + s1 * s2 * c3;
    w = c1 * c2 * c3 - s1 * s2 * s3;

    if (notify) onChange?.call();
  }
  void setFromAxisAngle(Fiber3DVector3 axis, double angle) {
    final halfAngle = angle / 2;
    final s = sin(halfAngle);

    x = axis.x * s;
    y = axis.y * s;
    z = axis.z * s;
    w = cos(halfAngle);

    onChange?.call();
  }
  /// Sets this quaternion from a rotation matrix. Assumes the upper 3x3
  /// of [m] is a pure (unscaled) rotation.
  void setFromRotationMatrix(Fiber3DMatrix4 m) {
    final te = m.elements;

    final m11 = te[0], m12 = te[4], m13 = te[8];
    final m21 = te[1], m22 = te[5], m23 = te[9];
    final m31 = te[2], m32 = te[6], m33 = te[10];

    final trace = m11 + m22 + m33;

    if (trace > 0) {
      final s = 0.5 / sqrt(trace + 1.0);
      w = 0.25 / s;
      x = (m32 - m23) * s;
      y = (m13 - m31) * s;
      z = (m21 - m12) * s;
    } else if (m11 > m22 && m11 > m33) {
      final s = 2.0 * sqrt(1.0 + m11 - m22 - m33);
      w = (m32 - m23) / s;
      x = 0.25 * s;
      y = (m12 + m21) / s;
      z = (m13 + m31) / s;
    } else if (m22 > m33) {
      final s = 2.0 * sqrt(1.0 + m22 - m11 - m33);
      w = (m13 - m31) / s;
      x = (m12 + m21) / s;
      y = 0.25 * s;
      z = (m23 + m32) / s;
    } else {
      final s = 2.0 * sqrt(1.0 + m33 - m11 - m22);
      w = (m21 - m12) / s;
      x = (m13 + m31) / s;
      y = (m23 + m32) / s;
      z = 0.25 * s;
    }
  }

  /// Sets this quaternion to the rotation that rotates unit vector [from]
  /// to unit vector [to]. Used for aligning an object's "up" axis, e.g.
  /// when reconciling Fiber3DCamera with a non-default up vector.
  void setFromUnitVectors(Fiber3DVector3 from, Fiber3DVector3 to) {
    var r = (from.x * to.x + from.y * to.y + from.z * to.z) + 1;

    if (r < 1e-8) {
      r = 0;
      if (from.x.abs() > from.z.abs()) {
        x = -from.y;
        y = from.x;
        z = 0;
        w = r;
      } else {
        x = 0;
        y = -from.z;
        z = from.y;
        w = r;
      }
    } else {
      x = from.y * to.z - from.z * to.y;
      y = from.z * to.x - from.x * to.z;
      z = from.x * to.y - from.y * to.x;
      w = r;
    }

    normalize();
  }

  double dot(Fiber3DQuaternion q) => x * q.x + y * q.y + z * q.z + w * q.w;

  double length() => sqrt(x * x + y * y + z * z + w * w);

  void normalize() {
    var l = length();
    if (l == 0) {
      x = 0;
      y = 0;
      z = 0;
      w = 1;
    } else {
      l = 1 / l;
      x *= l;
      y *= l;
      z *= l;
      w *= l;
    }
    onChange?.call();
  }

  /// Inverts this quaternion in place (assumes unit length conjugate
  void invert() {
    x *= -1;
    y *= -1;
    z *= -1;
    onChange?.call();
  }
  void multiply(Fiber3DQuaternion q) => multiplyQuaternions(clone(), q);

  void premultiply(Fiber3DQuaternion q) => multiplyQuaternions(q, clone());

  void multiplyQuaternions(Fiber3DQuaternion a, Fiber3DQuaternion b) {
    final ax = a.x, ay = a.y, az = a.z, aw = a.w;
    final bx = b.x, by = b.y, bz = b.z, bw = b.w;

    x = ax * bw + aw * bx + ay * bz - az * by;
    y = ay * bw + aw * by + az * bx - ax * bz;
    z = az * bw + aw * bz + ax * by - ay * bx;
    w = aw * bw - ax * bx - ay * by - az * bz;

    onChange?.call();
  }
}