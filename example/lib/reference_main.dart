import 'package:flutter/material.dart';
import 'package:flutter_fiber/src/camera/fiber3d_camera.dart';
import 'package:flutter_fiber/src/core/fiber3d_mesh.dart';
import 'package:flutter_fiber/src/core/fiber3d_vector3.dart';
import 'package:flutter_fiber/src/geometry/fiber3d_sphere.dart';
import 'package:flutter_fiber/src/light/fiber3d_ambient_light.dart';
import 'package:flutter_fiber/src/light/fiber3d_point_light.dart';
import 'package:flutter_fiber/src/material/fiber3d_standard_material.dart';
import 'package:flutter_fiber/src/renderer/fiber3d_canvas.dart';

void main() => runApp(const FiberReferenceScene());

/// Section 0c reference scene: roughness (rows) x metalness (columns).
/// Compare against example/reference/three_reference.html on the same device.
class FiberReferenceScene extends StatelessWidget {
  const FiberReferenceScene({super.key});

  static const List<double> metalness = [0.0, 0.5, 1.0];
  static const List<double> roughness = [0.0, 0.25, 0.5, 0.75, 1.0];
  static const double spacing = 1.0;

  @override
  Widget build(BuildContext context) {
    final spheres = <Widget>[];
    for (var row = 0; row < roughness.length; row++) {
      for (var col = 0; col < metalness.length; col++) {
        final x = (col - (metalness.length - 1) / 2) * spacing;
        final y = ((roughness.length - 1) / 2 - row) * spacing;
        spheres.add(
          Fiber3DMesh(
            geometry: Fiber3DSphere(
              radius: 0.42,
              widthSegments: 64,
              heightSegments: 32,
            ),
            material: Fiber3DStandardMaterial(
              color: 0xCC2952,
              roughness: roughness[row],
              metalness: metalness[col],
            ),
            showEdges: false,
            // Fiber3DMesh has no position prop, so place it via onFrame.
            onFrame: (elapsed, delta, transform) =>
                transform.position.set(x, y, 0),
          ),
        );
      }
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Fiber3DCanvas(
          backgroundColor: 0x828282,
          camera: Fiber3DCamera(position: const Fiber3DVector3(0, 0, 7.5)),
          lights: [
            const Fiber3DAmbientLight(color: 0xffffff, intensity: 0.6),
            Fiber3DPointLight(
              color: 0xffffff,
              intensity: 3.0,
              position: const Fiber3DVector3(3, 4, 5),
            ),
            Fiber3DPointLight(
              color: 0xffffff,
              intensity: 1.5,
              position: const Fiber3DVector3(-3, 2, -2),
            ),
          ],
          children: spheres,
        ),
      ),
    );
  }
}