import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_fiber/src/core/fiber3d_matrix4.dart';
import 'package:flutter_fiber/src/core/fiber3d_vector3.dart';

void main() {
  group('Fiber3DMatrix4', () {
    test('defaults to identity', () {
      final m = Fiber3DMatrix4();
      expect(m.elements, [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]);
    });

    test('invert() on a pure translation negates the translation', () {
      final m = Fiber3DMatrix4();
      m.setPosition(3, 4, 5);
      m.invert();

      expect(m.elements[12], closeTo(-3, 1e-9));
      expect(m.elements[13], closeTo(-4, 1e-9));
      expect(m.elements[14], closeTo(-5, 1e-9));
    });

    test('makePerspective sets the correct projective markers', () {
      final m = Fiber3DMatrix4();
      m.makePerspective(-1, 1, 1, -1, 1, 100);

      expect(m.elements[11], -1); // marks this as a perspective matrix
      expect(m.elements[15], 0);
    });

    test('lookAt from (0,0,5) toward origin gives identity rotation', () {
      final m = Fiber3DMatrix4();
      m.lookAt(
        const Fiber3DVector3(0, 0, 5),
        const Fiber3DVector3.zero(),
        const Fiber3DVector3(0, 1, 0),
      );

      expect(m.elements[0], closeTo(1, 1e-9));
      expect(m.elements[5], closeTo(1, 1e-9));
      expect(m.elements[10], closeTo(1, 1e-9));
    });

    test('transformPoint applies translation correctly', () {
      final m = Fiber3DMatrix4();
      m.setPosition(1, 2, 3);

      final result = m.transformPoint(0, 0, 0);
      expect(result[0], closeTo(1, 1e-9));
      expect(result[1], closeTo(2, 1e-9));
      expect(result[2], closeTo(3, 1e-9));
    });
  });
}