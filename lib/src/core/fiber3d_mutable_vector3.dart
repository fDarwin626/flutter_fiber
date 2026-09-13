import 'dart:math';
import 'fiber3d_vector3.dart';

class Fiber3DMutableVector3 {
  double x;
  double y;
  double z;


  Fiber3DMutableVector3([this.x = 0, this.y = 0, this.z = 0]);

  Fiber3DMutableVector3.zero() : x = 0, y = 0, z = 0;
  
  Fiber3DMutableVector3.all(double value) : x = value, y = value, z = value;

  void set(double x, double y, double z) {
    this.x = x;
    this.y = y;
    this.z = z;
  }
  void copy(Fiber3DMutableVector3 v) {
    x = v.x;
    y = v.y;
    z = v.z;
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
