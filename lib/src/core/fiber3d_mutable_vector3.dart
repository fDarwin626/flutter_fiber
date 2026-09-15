import 'dart:math';
import 'fiber3d_vector3.dart';

class Fiber3DMutableVector3 {
  double _x;
  double _y;
  double _z;

  /// Called whenever x, y, or z changes via a setter (including `+=`,
  /// which Dart desugars to a getter-then-setter call) or via [set].
  /// Used by Fiber3DObject to keep rotation (Euler) and its internal
  /// quaternion in sync, mirroring three.js's Vector3/Euler `_onChange`
  /// pattern — same mechanism, same reason.
  void Function()? onChange;

  Fiber3DMutableVector3([double x = 0, double y = 0, double z = 0])
      : _x = x, _y = y, _z = z;

  Fiber3DMutableVector3.zero() : _x = 0, _y = 0, _z = 0;

  Fiber3DMutableVector3.all(double value) : _x = value, _y = value, _z = value;

  double get x => _x;
  set x(double value) {
    _x = value;
    onChange?.call();
  }

  double get y => _y;
  set y(double value) {
    _y = value;
    onChange?.call();
  }

  double get z => _z;
  set z(double value) {
    _z = value;
    onChange?.call();
  }

  void set(double x, double y, double z) {
    _x = x;
    _y = y;
    _z = z;
    onChange?.call();
  }
  void copy(Fiber3DMutableVector3 v) {
    _x = v.x;
    _y = v.y;
    _z = v.z;
  }

  void add(Fiber3DMutableVector3 v) {
    x += v.x;
    y += v.y;
    z += v.z;
  }

  void subtract(Fiber3DMutableVector3 v) {
    x -= v.x;
    y -= v.y;
    z -= v.z;
  }

  void multiplyScalar(double scalar) {
    x *= scalar;
    y *= scalar;
    z *= scalar;
  }

  double get length => sqrt(x * x + y * y + z * z);

  void normalize(){
    final l = length;
    if (l == 0) return;
    x /= l;
    y /= l;
    z /= l;
  }

    /// Converts to the immutable [Fiber3DVector3] used elsewhere (e.g.
  /// passing a Fiber3DObject's world position into a ray or camera call).
    Fiber3DVector3 toImmutable() => Fiber3DVector3(x, y, z);
      Fiber3DMutableVector3 clone() => Fiber3DMutableVector3(x, y, z);

}
