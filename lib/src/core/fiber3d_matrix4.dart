import 'dart:math';
import 'fiber3d_vector3.dart';
import 'fiber3d_mutable_vector3.dart';
import 'fiber3d_quaternion.dart';

/// A 4x4 matrix, stored in column-major order matching three.js's Matrix4
/// internal layout exactly this makes porting its matrix math a direct,
/// index-for-index translation, and column-major is also the layout
/// OpenGL's uniformMatrix4fv expects natively.
class Fiber3DMatrix4 {
  final List<double> elements;

  Fiber3DMatrix4() : elements = _identityList();

  Fiber3DMatrix4.fromList(List<double> values)
      : elements = List<double>.from(values);

  static List<double> _identityList() => [
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1,
      ];

  void identity() => elements.setAll(0, _identityList());

  Fiber3DMatrix4 clone() => Fiber3DMatrix4.fromList(elements);

  void setPosition(double x, double y, double z) {
    elements[12] = x;
    elements[13] = y;
    elements[14] = z;
  }

  /// Post-multiplies this matrix by [m] (this = this * m).
  void multiply(Fiber3DMatrix4 m) {
    multiplyMatrices(clone(), m);
  }

  /// Pre-multiplies this matrix by [m] (this = m * this).
  void premultiply(Fiber3DMatrix4 m) {
    multiplyMatrices(m, clone());
  }

  /// Ported from three.js's Matrix4.multiplyMatrices.
  void multiplyMatrices(Fiber3DMatrix4 a, Fiber3DMatrix4 b) {
    final ae = a.elements;
    final be = b.elements;
    final te = elements;

    final a11 = ae[0], a12 = ae[4], a13 = ae[8], a14 = ae[12];
    final a21 = ae[1], a22 = ae[5], a23 = ae[9], a24 = ae[13];
    final a31 = ae[2], a32 = ae[6], a33 = ae[10], a34 = ae[14];
    final a41 = ae[3], a42 = ae[7], a43 = ae[11], a44 = ae[15];

    final b11 = be[0], b12 = be[4], b13 = be[8], b14 = be[12];
    final b21 = be[1], b22 = be[5], b23 = be[9], b24 = be[13];
    final b31 = be[2], b32 = be[6], b33 = be[10], b34 = be[14];
    final b41 = be[3], b42 = be[7], b43 = be[11], b44 = be[15];

    te[0] = a11 * b11 + a12 * b21 + a13 * b31 + a14 * b41;
    te[4] = a11 * b12 + a12 * b22 + a13 * b32 + a14 * b42;
    te[8] = a11 * b13 + a12 * b23 + a13 * b33 + a14 * b43;
    te[12] = a11 * b14 + a12 * b24 + a13 * b34 + a14 * b44;

    te[1] = a21 * b11 + a22 * b21 + a23 * b31 + a24 * b41;
    te[5] = a21 * b12 + a22 * b22 + a23 * b32 + a24 * b42;
    te[9] = a21 * b13 + a22 * b23 + a23 * b33 + a24 * b43;
    te[13] = a21 * b14 + a22 * b24 + a23 * b34 + a24 * b44;

    te[2] = a31 * b11 + a32 * b21 + a33 * b31 + a34 * b41;
    te[6] = a31 * b12 + a32 * b22 + a33 * b32 + a34 * b42;
    te[10] = a31 * b13 + a32 * b23 + a33 * b33 + a34 * b43;
    te[14] = a31 * b14 + a32 * b24 + a33 * b34 + a34 * b44;

    te[3] = a41 * b11 + a42 * b21 + a43 * b31 + a44 * b41;
    te[7] = a41 * b12 + a42 * b22 + a43 * b32 + a44 * b42;
    te[11] = a41 * b13 + a42 * b23 + a43 * b33 + a44 * b43;
    te[15] = a41 * b14 + a42 * b24 + a43 * b34 + a44 * b44;
  }

  /// Analytic inverse. Ported directly from three.js's Matrix4.invert.
  void invert() {
    final te = elements;

    final n11 = te[0], n21 = te[1], n31 = te[2], n41 = te[3];
    final n12 = te[4], n22 = te[5], n32 = te[6], n42 = te[7];
    final n13 = te[8], n23 = te[9], n33 = te[10], n43 = te[11];
    final n14 = te[12], n24 = te[13], n34 = te[14], n44 = te[15];

    final t1 = n11 * n22 - n21 * n12;
    final t2 = n11 * n32 - n31 * n12;
    final t3 = n11 * n42 - n41 * n12;
    final t4 = n21 * n32 - n31 * n22;
    final t5 = n21 * n42 - n41 * n22;
    final t6 = n31 * n42 - n41 * n32;
    final t7 = n13 * n24 - n23 * n14;
    final t8 = n13 * n34 - n33 * n14;
    final t9 = n13 * n44 - n43 * n14;
    final t10 = n23 * n34 - n33 * n24;
    final t11 = n23 * n44 - n43 * n24;
    final t12 = n33 * n44 - n43 * n34;

    final det = t1 * t12 - t2 * t11 + t3 * t10 + t4 * t9 - t5 * t8 + t6 * t7;

    if (det == 0) {
      for (var i = 0; i < 16; i++) {
        te[i] = 0;
      }
      return;
    }

    final detInv = 1 / det;

    te[0] = (n22 * t12 - n32 * t11 + n42 * t10) * detInv;
    te[1] = (n31 * t11 - n21 * t12 - n41 * t10) * detInv;
    te[2] = (n24 * t6 - n34 * t5 + n44 * t4) * detInv;
    te[3] = (n33 * t5 - n23 * t6 - n43 * t4) * detInv;

    te[4] = (n32 * t9 - n12 * t12 - n42 * t8) * detInv;
    te[5] = (n11 * t12 - n31 * t9 + n41 * t8) * detInv;
    te[6] = (n34 * t3 - n14 * t6 - n44 * t2) * detInv;
    te[7] = (n13 * t6 - n33 * t3 + n43 * t2) * detInv;

    te[8] = (n12 * t11 - n22 * t9 + n42 * t7) * detInv;
    te[9] = (n21 * t9 - n11 * t11 - n41 * t7) * detInv;
    te[10] = (n14 * t5 - n24 * t3 + n44 * t1) * detInv;
    te[11] = (n23 * t3 - n13 * t5 - n43 * t1) * detInv;

    te[12] = (n22 * t8 - n12 * t10 - n32 * t7) * detInv;
    te[13] = (n11 * t10 - n21 * t8 + n31 * t7) * detInv;
    te[14] = (n24 * t2 - n14 * t4 - n34 * t1) * detInv;
    te[15] = (n13 * t4 - n23 * t2 + n33 * t1) * detInv;
  }

  /// Ported from three.js's Matrix4.makePerspective — WebGL coordinate
  /// system only, reversedDepth branch dropped (flutter_fiber only
  /// targets OpenGL ES).
  void makePerspective(
    double left,
    double right,
    double top,
    double bottom,
    double near,
    double far,
  ) {
    final te = elements;

    final x = 2 * near / (right - left);
    final y = 2 * near / (top - bottom);

    final a = (right + left) / (right - left);
    final b = (top + bottom) / (top - bottom);

    final c = -(far + near) / (far - near);
    final d = (-2 * far * near) / (far - near);

    te[0] = x;
    te[4] = 0;
    te[8] = a;
    te[12] = 0;
    te[1] = 0;
    te[5] = y;
    te[9] = b;
    te[13] = 0;
    te[2] = 0;
    te[6] = 0;
    te[10] = c;
    te[14] = d;
    te[3] = 0;
    te[7] = 0;
    te[11] = -1;
    te[15] = 0;
  }

  /// Sets the rotation component of this matrix, looking from [eye]
  /// towards [target], oriented by [up]. Ported from three.js's
  /// Matrix4.lookAt — only the rotation is set here, matching three.js
  /// exactly; translation is applied separately via [setPosition].
  void lookAt(Fiber3DVector3 eye, Fiber3DVector3 target, Fiber3DVector3 up) {
    final te = elements;

    var zx = eye.x - target.x;
    var zy = eye.y - target.y;
    var zz = eye.z - target.z;

    if (zx * zx + zy * zy + zz * zz == 0) {
      zz = 1;
    }

    var zLen = sqrt(zx * zx + zy * zy + zz * zz);
    zx /= zLen;
    zy /= zLen;
    zz /= zLen;

    var xx = up.y * zz - up.z * zy;
    var xy = up.z * zx - up.x * zz;
    var xz = up.x * zy - up.y * zx;

    if (xx * xx + xy * xy + xz * xz == 0) {
      if (up.z.abs() == 1) {
        zx += 0.0001;
      } else {
        zz += 0.0001;
      }
      zLen = sqrt(zx * zx + zy * zy + zz * zz);
      zx /= zLen;
      zy /= zLen;
      zz /= zLen;

      xx = up.y * zz - up.z * zy;
      xy = up.z * zx - up.x * zz;
      xz = up.x * zy - up.y * zx;
    }

    final xLen = sqrt(xx * xx + xy * xy + xz * xz);
    xx /= xLen;
    xy /= xLen;
    xz /= xLen;

    final yx = zy * xz - zz * xy;
    final yy = zz * xx - zx * xz;
    final yz = zx * xy - zy * xx;

    te[0] = xx;
    te[4] = yx;
    te[8] = zx;
    te[1] = xy;
    te[5] = yy;
    te[9] = zy;
    te[2] = xz;
    te[6] = yz;
    te[10] = zz;
  }
  /// Sets this matrix to the transformation composed of the given
  /// position, rotation (quaternion), and scale. Ported from three.js's
  /// Matrix4.compose.
  void compose(
    Fiber3DMutableVector3 position,
    Fiber3DQuaternion quaternion,
    Fiber3DMutableVector3 scale,
  ) {
    final te = elements;

    final x = quaternion.x, y = quaternion.y, z = quaternion.z, w = quaternion.w;
    final x2 = x + x, y2 = y + y, z2 = z + z;
    final xx = x * x2, xy = x * y2, xz = x * z2;
    final yy = y * y2, yz = y * z2, zz = z * z2;
    final wx = w * x2, wy = w * y2, wz = w * z2;

    final sx = scale.x, sy = scale.y, sz = scale.z;

    te[0] = (1 - (yy + zz)) * sx;
    te[1] = (xy + wz) * sx;
    te[2] = (xz - wy) * sx;
    te[3] = 0;

    te[4] = (xy - wz) * sy;
    te[5] = (1 - (xx + zz)) * sy;
    te[6] = (yz + wx) * sy;
    te[7] = 0;

    te[8] = (xz + wy) * sz;
    te[9] = (yz - wx) * sz;
    te[10] = (1 - (xx + yy)) * sz;
    te[11] = 0;

    te[12] = position.x;
    te[13] = position.y;
    te[14] = position.z;
    te[15] = 1;
  }

  /// The determinant of the upper 3x3, assuming an affine matrix (bottom
  /// row [0,0,0,1]) — cheaper than a full 4x4 determinant. Ported from
  /// three.js's Matrix4.determinantAffine.
  double determinantAffine() {
    final te = elements;
    final n11 = te[0], n12 = te[4], n13 = te[8];
    final n21 = te[1], n22 = te[5], n23 = te[9];
    final n31 = te[2], n32 = te[6], n33 = te[10];

    return n11 * (n22 * n33 - n23 * n32) -
        n12 * (n21 * n33 - n23 * n31) +
        n13 * (n21 * n32 - n22 * n31);
  }

  /// Decomposes this matrix into position, rotation (quaternion), and
  /// scale, writing the results into the given out-parameters. Ported
  /// from three.js's Matrix4.decompose.
  void decompose(
    Fiber3DMutableVector3 position,
    Fiber3DQuaternion quaternion,
    Fiber3DMutableVector3 scale,
  ) {
    final te = elements;

    position.x = te[12];
    position.y = te[13];
    position.z = te[14];

    final det = determinantAffine();

    if (det == 0) {
      scale.set(1, 1, 1);
      quaternion.identityReset();
      return;
    }

    var sx = sqrt(te[0] * te[0] + te[1] * te[1] + te[2] * te[2]);
    final sy = sqrt(te[4] * te[4] + te[5] * te[5] + te[6] * te[6]);
    final sz = sqrt(te[8] * te[8] + te[9] * te[9] + te[10] * te[10]);

    if (det < 0) sx = -sx;

    final rotationOnly = Fiber3DMatrix4.fromList(elements);
    final invSX = 1 / sx, invSY = 1 / sy, invSZ = 1 / sz;

    rotationOnly.elements[0] *= invSX;
    rotationOnly.elements[1] *= invSX;
    rotationOnly.elements[2] *= invSX;

    rotationOnly.elements[4] *= invSY;
    rotationOnly.elements[5] *= invSY;
    rotationOnly.elements[6] *= invSY;

    rotationOnly.elements[8] *= invSZ;
    rotationOnly.elements[9] *= invSZ;
    rotationOnly.elements[10] *= invSZ;

    quaternion.setFromRotationMatrix(rotationOnly);

    scale.x = sx;
    scale.y = sy;
    scale.z = sz;
  }

  /// Transforms a point by this matrix (with perspective divide),

  List<double> transformPoint(double x, double y, double z) {
    final te = elements;
    final w = te[3] * x + te[7] * y + te[11] * z + te[15];
    final rx = (te[0] * x + te[4] * y + te[8] * z + te[12]) / w;
    final ry = (te[1] * x + te[5] * y + te[9] * z + te[13]) / w;
    final rz = (te[2] * x + te[6] * y + te[10] * z + te[14]) / w;
    return [rx, ry, rz];
  }
}