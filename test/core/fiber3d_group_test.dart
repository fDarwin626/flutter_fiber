import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_fiber/src/renderer/fiber3d_canvas.dart';
import 'package:flutter_fiber/src/core/fiber3d_group.dart';
import 'package:flutter_fiber/src/core/fiber3d_mesh.dart';
import 'package:flutter_fiber/src/geometry/fiber3d_box.dart';
import 'package:flutter_fiber/src/material/fiber3d_standard_material.dart';

void main() {
  group('Fiber3DGroup', () {
    testWidgets('meshes inside a group attach to the group transform',
        (tester) async {
      final meshKeyA = GlobalKey<Fiber3DMeshState>();
      final meshKeyB = GlobalKey<Fiber3DMeshState>();
      final groupKey = GlobalKey<Fiber3DGroupState>();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: 200,
            height: 200,
            child: Fiber3DCanvas(
              children: [
                Fiber3DGroup(
                  key: groupKey,
                  children: [
                    Fiber3DMesh(
                      key: meshKeyA,
                      geometry: Fiber3DBox(),
                      material:  Fiber3DStandardMaterial(),
                    ),
                    Fiber3DMesh(
                      key: meshKeyB,
                      geometry: Fiber3DBox(),
                      material:  Fiber3DStandardMaterial(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      final groupTransform = groupKey.currentState!.transform;
      final meshATransform = meshKeyA.currentState!.transform;
      final meshBTransform = meshKeyB.currentState!.transform;

      expect(meshATransform.parent, groupTransform);
      expect(meshBTransform.parent, groupTransform);
      expect(groupTransform.children, contains(meshATransform));
      expect(groupTransform.children, contains(meshBTransform));
    });

    testWidgets('moving the group moves child mesh world position',
        (tester) async {
      final meshKey = GlobalKey<Fiber3DMeshState>();
      final groupKey = GlobalKey<Fiber3DGroupState>();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: 200,
            height: 200,
            child: Fiber3DCanvas(
              children: [
                Fiber3DGroup(
                  key: groupKey,
                  children: [
                    Fiber3DMesh(
                      key: meshKey,
                      geometry: Fiber3DBox(),
                      material: Fiber3DStandardMaterial(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      groupKey.currentState!.transform.position.set(5, 0, 0);
      meshKey.currentState!.transform.position.set(0, 2, 0);

      final worldPos = meshKey.currentState!.transform.getWorldPosition();
      expect(worldPos.x, closeTo(5, 1e-9));
      expect(worldPos.y, closeTo(2, 1e-9));
    });

    testWidgets('a mesh outside any group has no parent transform',
        (tester) async {
      final meshKey = GlobalKey<Fiber3DMeshState>();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: 200,
            height: 200,
            child: Fiber3DCanvas(
              children: [
                Fiber3DMesh(
                  key: meshKey,
                  geometry: Fiber3DBox(),
                  material:  Fiber3DStandardMaterial(),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      expect(meshKey.currentState!.transform.parent, isNull);
    });

    testWidgets('nested groups compose transforms through both levels',
        (tester) async {
      final outerKey = GlobalKey<Fiber3DGroupState>();
      final innerKey = GlobalKey<Fiber3DGroupState>();
      final meshKey = GlobalKey<Fiber3DMeshState>();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: 200,
            height: 200,
            child: Fiber3DCanvas(
              children: [
                Fiber3DGroup(
                  key: outerKey,
                  children: [
                    Fiber3DGroup(
                      key: innerKey,
                      children: [
                        Fiber3DMesh(
                          key: meshKey,
                          geometry: Fiber3DBox(),
                          material: Fiber3DStandardMaterial(),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      expect(innerKey.currentState!.transform.parent,
          outerKey.currentState!.transform);
      expect(meshKey.currentState!.transform.parent,
          innerKey.currentState!.transform);
    });
  });
}