import 'dart:math';

class Fiber3DVector3 {
  final double x;
  final double y;
  final double z;

  const Fiber3DVector3(this.x, this.y, this.z);

  const Fiber3DVector3.zero() : x = 0, y = 0, z = 0;

  Fiber3DVector3.all(double value) : x = value, y = value, z = value;

  double get length => sqrt(x * x + y * y + z * z);
}