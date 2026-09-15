import 'dart:math';
import 'fiber3d_vector3.dart';
import 'fiber3d_mutable_vector3.dart';
import 'fiber3d_quaternion.dart';
import 'fiber3d_matrix4.dart';

class Fiber3DObject {
  String name = '';

  final Fiber3DMutableVector3 position = Fiber3DMutableVector3.zero();

  /// Local rotation as Euler angles (radians), XYZ order — the only
  /// order flutter_fiber v1 supports.
  final Fiber3DMutableVector3 rotation = Fiber3DMutableVector3.zero();

  final Fiber3DQuaternion quaternion = Fiber3DQuaternion.identity();
  final Fiber3DMutableVector3 scale = Fiber3DMutableVector3.all(1);

  /// The "up" direction, used by [lookAt].
  final Fiber3DMutableVector3 up = Fiber3DMutableVector3(0, 1, 0);

  /// Pivot point for rotation/scale — when set, rotation and scale are
  /// applied around this point instead of the object's origin.
  Fiber3DMutableVector3? pivot;

  bool visible = true;

  final Map<String, dynamic> userData = {};

  Fiber3DObject? parent;
  final List<Fiber3DObject> children = [];

  final Fiber3DMatrix4 matrix = Fiber3DMatrix4();
  final Fiber3DMatrix4 matrixWorld = Fiber3DMatrix4();

  bool matrixAutoUpdate = true;
  bool matrixWorldNeedsUpdate = false;

  void Function()? onDispose;

  bool _syncingRotation = false;

  Fiber3DObject() {
    // Cross-sync rotation <--> quaternion, mirroring three.js's
    // Vector3/Quaternion _onChange` pattern. The shared guard prevents
    // either handler from re-triggering the other in an infinite loop —
    // only one sync direction is ever "in flight" at a time.
    rotation.onChange = () {
      if (_syncingRotation) return;
      _syncingRotation = true;
      quaternion.setFromEuler(rotation.x, rotation.y, rotation.z, notify: false);
      _syncingRotation = false;
    };

    quaternion.onChange = () {
      if (_syncingRotation) return;
      _syncingRotation = true;
      _updateRotationFromQuaternion();
      _syncingRotation = false;
    };
  }

  /// Extracts XYZ-order Euler angles from the current quaternion by
  /// composing it into a rotation matrix (reusing the already-tested
  /// Matrix4.compose) and applying the standard XYZ extraction formula.
  void _updateRotationFromQuaternion() {
    final m = Fiber3DMatrix4();
    m.compose(Fiber3DMutableVector3.zero(), quaternion, Fiber3DMutableVector3.all(1));
    final te = m.elements;

    final m11 = te[0], m13 = te[8];
    final m22 = te[5], m23 = te[9];
    final m32 = te[6], m33 = te[10];
    final m12 = te[4];

    double ex, ey, ez;
    ey = asin(m13.clamp(-1.0, 1.0));

    if (m13.abs() < 0.9999999) {
      ex = atan2(-m23, m33);
      ez = atan2(-m12, m11);
    } else {
      ex = atan2(m32, m22);
      ez = 0;
    }

    rotation.set(ex, ey, ez);
  }

  // --- Scene graph ---

  void add(Fiber3DObject child) {
    if (identical(child, this)) return;
    child.removeFromParent();
    child.parent = this;
    children.add(child);
  }

  void remove(Fiber3DObject child) {
    final index = children.indexOf(child);
    if (index != -1) {
      child.parent = null;
      children.removeAt(index);
    }
  }

  void removeFromParent() {
    parent?.remove(this);
  }

  void clear() {
    for (final child in List<Fiber3DObject>.from(children)) {
      remove(child);
    }
  }

  // --- Matrix updates ---

  void updateMatrix() {
    matrix.compose(position, quaternion, scale);

    final p = pivot;
    if (p != null) {
      final px = p.x, py = p.y, pz = p.z;
      final te = matrix.elements;
      te[12] += px - te[0] * px - te[4] * py - te[8] * pz;
      te[13] += py - te[1] * px - te[5] * py - te[9] * pz;
      te[14] += pz - te[2] * px - te[6] * py - te[10] * pz;
    }

    matrixWorldNeedsUpdate = true;
  }

  void updateMatrixWorld([bool force = false]) {
    if (matrixAutoUpdate) updateMatrix();

    if (matrixWorldNeedsUpdate || force) {
      if (parent == null) {
        matrixWorld.elements.setAll(0, matrix.elements);
      } else {
        matrixWorld.multiplyMatrices(parent!.matrixWorld, matrix);
      }
      matrixWorldNeedsUpdate = false;
      force = true;
    }

    for (final child in children) {
      child.updateMatrixWorld(force);
    }
  }

  void updateWorldMatrix({
    bool updateParents = false,
    bool updateChildren = false,
    bool force = false,
  }) {
    final p = parent;
    if (updateParents && p != null) {
      p.updateWorldMatrix(updateParents: true);
    }

    if (matrixAutoUpdate) updateMatrix();

    if (matrixWorldNeedsUpdate || force) {
      if (parent == null) {
        matrixWorld.elements.setAll(0, matrix.elements);
      } else {
        matrixWorld.multiplyMatrices(parent!.matrixWorld, matrix);
      }
      matrixWorldNeedsUpdate = false;
      force = true;
    }

    if (updateChildren) {
      for (final child in children) {
        child.updateWorldMatrix(updateChildren: true, force: force);
      }
    }
  }

  // --- Transform utilities ---

  void applyMatrix4(Fiber3DMatrix4 m) {
    if (matrixAutoUpdate) updateMatrix();
    matrix.premultiply(m);
    matrix.decompose(position, quaternion, scale);
  }

  void applyQuaternion(Fiber3DQuaternion q) {
    quaternion.premultiply(q);
  }

  void rotateOnAxis(Fiber3DVector3 axis, double angle) {
    final q = Fiber3DQuaternion();
    q.setFromAxisAngle(axis, angle);
    quaternion.multiply(q);
  }

  void rotateOnWorldAxis(Fiber3DVector3 axis, double angle) {
    final q = Fiber3DQuaternion();
    q.setFromAxisAngle(axis, angle);
    quaternion.premultiply(q);
  }

  void rotateX(double angle) => rotateOnAxis(const Fiber3DVector3(1, 0, 0), angle);
  void rotateY(double angle) => rotateOnAxis(const Fiber3DVector3(0, 1, 0), angle);
  void rotateZ(double angle) => rotateOnAxis(const Fiber3DVector3(0, 0, 1), angle);

  /// Translates along [axis] (in local/object space) by [distance] —
  /// rotates the axis by this object's current orientation first.
  void translateOnAxis(Fiber3DVector3 axis, double distance) {
    final vx = axis.x, vy = axis.y, vz = axis.z;
    final qx = quaternion.x, qy = quaternion.y, qz = quaternion.z, qw = quaternion.w;

    final tx = 2 * (qy * vz - qz * vy);
    final ty = 2 * (qz * vx - qx * vz);
    final tz = 2 * (qx * vy - qy * vx);

    final rx = vx + qw * tx + (qy * tz - qz * ty);
    final ry = vy + qw * ty + (qz * tx - qx * tz);
    final rz = vz + qw * tz + (qx * ty - qy * tx);

    position.x += rx * distance;
    position.y += ry * distance;
    position.z += rz * distance;
  }

  void translateX(double distance) => translateOnAxis(const Fiber3DVector3(1, 0, 0), distance);
  void translateY(double distance) => translateOnAxis(const Fiber3DVector3(0, 1, 0), distance);
  void translateZ(double distance) => translateOnAxis(const Fiber3DVector3(0, 0, 1), distance);

  // --- World-space queries ---

  Fiber3DVector3 getWorldPosition() {
    updateWorldMatrix(updateParents: true);
    final te = matrixWorld.elements;
    return Fiber3DVector3(te[12], te[13], te[14]);
  }

  Fiber3DQuaternion getWorldQuaternion() {
    updateWorldMatrix(updateParents: true);
    final pos = Fiber3DMutableVector3.zero();
    final q = Fiber3DQuaternion();
    final scl = Fiber3DMutableVector3.all(1);
    matrixWorld.decompose(pos, q, scl);
    return q;
  }

  Fiber3DVector3 getWorldScale() {
    updateWorldMatrix(updateParents: true);
    final pos = Fiber3DMutableVector3.zero();
    final q = Fiber3DQuaternion();
    final scl = Fiber3DMutableVector3.all(1);
    matrixWorld.decompose(pos, q, scl);
    return Fiber3DVector3(scl.x, scl.y, scl.z);
  }

  Fiber3DVector3 getWorldDirection() {
    updateWorldMatrix(updateParents: true);
    final e = matrixWorld.elements;
    final x = e[8], y = e[9], z = e[10];
    final len = sqrt(x * x + y * y + z * z);
    if (len == 0) return const Fiber3DVector3(0, 0, 1);
    return Fiber3DVector3(x / len, y / len, z / len);
  }

  Fiber3DVector3 localToWorld(Fiber3DVector3 v) {
    updateWorldMatrix(updateParents: true);
    final r = matrixWorld.transformPoint(v.x, v.y, v.z);
    return Fiber3DVector3(r[0], r[1], r[2]);
  }

  Fiber3DVector3 worldToLocal(Fiber3DVector3 v) {
    updateWorldMatrix(updateParents: true);
    final inv = matrixWorld.clone();
    inv.invert();
    final r = inv.transformPoint(v.x, v.y, v.z);
    return Fiber3DVector3(r[0], r[1], r[2]);
  }

  /// Rotates the object to face [target] in world space. Does not
  /// support objects with non-uniformly-scaled parents (same limitation
  /// three.js's own lookAt documents).
  void lookAt(Fiber3DVector3 target) {
    updateWorldMatrix(updateParents: true);
    final worldPos = getWorldPosition();

    final m = Fiber3DMatrix4();
    final upVec = Fiber3DVector3(up.x, up.y, up.z);
    m.lookAt(target, worldPos, upVec);
    quaternion.setFromRotationMatrix(m);

    final p = parent;
    if (p != null) {
      final parentRot = p.matrixWorld.clone();
      final dummyPos = Fiber3DMutableVector3.zero();
      final parentQuat = Fiber3DQuaternion();
      final dummyScale = Fiber3DMutableVector3.all(1);
      parentRot.decompose(dummyPos, parentQuat, dummyScale);
      parentQuat.invert();
      quaternion.premultiply(parentQuat);
    }
  }

  // --- Traversal & lookup ---

  void traverse(void Function(Fiber3DObject) callback) {
    callback(this);
    for (final child in List<Fiber3DObject>.from(children)) {
      child.traverse(callback);
    }
  }

  void traverseVisible(void Function(Fiber3DObject) callback) {
    if (!visible) return;
    callback(this);
    for (final child in List<Fiber3DObject>.from(children)) {
      child.traverseVisible(callback);
    }
  }

  void traverseAncestors(void Function(Fiber3DObject) callback) {
    final p = parent;
    if (p != null) {
      callback(p);
      p.traverseAncestors(callback);
    }
  }

  Fiber3DObject? getObjectByName(String targetName) {
    if (name == targetName) return this;
    for (final child in children) {
      final found = child.getObjectByName(targetName);
      if (found != null) return found;
    }
    return null;
  }

  List<Fiber3DObject> getObjectsByName(String targetName, [List<Fiber3DObject>? result]) {
    result ??= [];
    if (name == targetName) result.add(this);
    for (final child in children) {
      child.getObjectsByName(targetName, result);
    }
    return result;
  }

  // --- Clone / copy ---

  Fiber3DObject clone({bool recursive = true}) {
    final c = Fiber3DObject();
    c.copy(this, recursive: recursive);
    return c;
  }

  void copy(Fiber3DObject source, {bool recursive = true}) {
    name = source.name;
    up.copy(source.up);
    position.copy(source.position);
    quaternion.copy(source.quaternion);
    scale.copy(source.scale);
    pivot = source.pivot?.clone();
    matrix.elements.setAll(0, source.matrix.elements);
    matrixWorld.elements.setAll(0, source.matrixWorld.elements);
    matrixAutoUpdate = source.matrixAutoUpdate;
    visible = source.visible;
    userData.clear();
    userData.addAll(source.userData);

    if (recursive) {
      for (final child in source.children) {
        add(child.clone());
      }
    }
  }

  // --- Lifecycle ---

  void dispose() {
    onDispose?.call();
  }
}