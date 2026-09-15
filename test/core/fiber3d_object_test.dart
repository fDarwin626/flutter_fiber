import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_fiber/src/core/fiber3d_object.dart';
import 'package:flutter_fiber/src/core/fiber3d_vector3.dart';

void main() {
  group('Fiber3DObject', () {
    test('defaults to identity transform', () {
      final obj = Fiber3DObject();
      expect(obj.position.x, 0);
      expect(obj.rotation.y, 0);
      expect(obj.scale.x, 1);
      expect(obj.quaternion.w, 1);
    });

    test('rotation.y += delta updates the quaternion', () {
      final obj = Fiber3DObject();
      obj.rotation.y += 1.0;

      expect(obj.rotation.y, closeTo(1.0, 1e-9));
      // quaternion should no longer be identity
      expect(obj.quaternion.w, isNot(closeTo(1.0, 1e-6)));
    });

    test('rotateOnAxis updates rotation Euler too (bidirectional sync)', () {
      final obj = Fiber3DObject();
      obj.rotateY(1.0);

      expect(obj.rotation.y, closeTo(1.0, 1e-6));
    });

    test('add/remove maintains parent/child relationship', () {
      final parent = Fiber3DObject();
      final child = Fiber3DObject();

      parent.add(child);
      expect(child.parent, parent);
      expect(parent.children.contains(child), isTrue);

      parent.remove(child);
      expect(child.parent, isNull);
      expect(parent.children.contains(child), isFalse);
    });

    test('adding a child already parented elsewhere reparents it', () {
      final a = Fiber3DObject();
      final b = Fiber3DObject();
      final child = Fiber3DObject();

      a.add(child);
      b.add(child);

      expect(child.parent, b);
      expect(a.children.contains(child), isFalse);
      expect(b.children.contains(child), isTrue);
    });

    test('child world position reflects parent transform', () {
      final parent = Fiber3DObject();
      parent.position.set(10, 0, 0);

      final child = Fiber3DObject();
      child.position.set(0, 5, 0);

      parent.add(child);

      final worldPos = child.getWorldPosition();
      expect(worldPos.x, closeTo(10, 1e-9));
      expect(worldPos.y, closeTo(5, 1e-9));
      expect(worldPos.z, closeTo(0, 1e-9));
    });

    test('traverse visits the object and all descendants', () {
      final root = Fiber3DObject()..name = 'root';
      final childA = Fiber3DObject()..name = 'a';
      final childB = Fiber3DObject()..name = 'b';
      root.add(childA);
      childA.add(childB);

      final visited = <String>[];
      root.traverse((o) => visited.add(o.name));

      expect(visited, ['root', 'a', 'b']);
    });

    test('getObjectByName finds a nested descendant', () {
      final root = Fiber3DObject();
      final child = Fiber3DObject()..name = 'target';
      root.add(child);

      expect(root.getObjectByName('target'), child);
      expect(root.getObjectByName('missing'), isNull);
    });

    test('clone copies position and children', () {
      final original = Fiber3DObject()..name = 'orig';
      original.position.set(1, 2, 3);
      final child = Fiber3DObject()..name = 'child';
      original.add(child);

      final copy = original.clone();

      expect(copy.name, 'orig');
      expect(copy.position.x, 1);
      expect(copy.children.length, 1);
      expect(copy.children.first.name, 'child');
      // must be a distinct object, not the same reference
      expect(identical(copy.children.first, child), isFalse);
    });

    test('lookAt orients the object toward a target', () {
      final obj = Fiber3DObject();
      obj.position.set(0, 0, 5);
      obj.lookAt(const Fiber3DVector3(0, 0, 0));

      // Forward (-Z in local space, rotated by quaternion) should point
      // roughly toward -Z world direction (from (0,0,5) toward origin).
      final dir = obj.getWorldDirection();
      expect(dir.z, lessThan(0));
    });

    test('dispose calls the onDispose callback', () {
      final obj = Fiber3DObject();
      var disposed = false;
      obj.onDispose = () => disposed = true;

      obj.dispose();
      expect(disposed, isTrue);
    });
  });
}