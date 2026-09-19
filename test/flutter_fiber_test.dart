import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_fiber/flutter_fiber.dart';

void main() {
  test('public entry point exports the core API', () {
    const v = Fiber3DVector3(1, 2, 3);
    expect(v.x, 1);
    expect(v.y, 2);
    expect(v.z, 3);
  });
}
