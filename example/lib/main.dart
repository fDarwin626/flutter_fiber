import 'package:flutter/material.dart';
import 'package:flutter_fiber/src/core/fiber3d_canvas.dart';
import 'package:flutter_fiber/src/core/fiber3d_mesh.dart';
import 'package:flutter_fiber/src/core/fiber3d_vector3.dart';
import 'package:flutter_fiber/src/material/fiber3d_standard_material.dart';
import 'package:flutter_fiber/src/light/fiber3d_ambient_light.dart';
import 'package:flutter_fiber/src/light/fiber3d_point_light.dart';
import 'package:flutter_fiber/src/camera/fiber3d_camera.dart';
import 'package:flutter_fiber/src/geometry/fiber3d_capsule.dart';

void main() {
  runApp(const FiberFullSceneTest());
}

class FiberFullSceneTest extends StatelessWidget {
  const FiberFullSceneTest({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF828282),
        appBar: AppBar(
          title: const Text('flutter_fiber Section 7 full scene test'),
        ),
        body: Fiber3DCanvas(
          camera: Fiber3DCamera(
            position: const Fiber3DVector3(0, 0, 5),
            target: const Fiber3DVector3.zero(),
          ),
          orbitEnabled: true,
          lights: [
            const Fiber3DAmbientLight(color: 0x606060, intensity: 1.2),
            Fiber3DPointLight(
              color: 0xffffff,
              intensity: 8.0,
              position: const Fiber3DVector3(3, 3, 3),
            ),
          ],
          children: const [SpinningCapsule()],
        ),
      ),
    );
  }
}

class SpinningCapsule extends StatelessWidget {
  const SpinningCapsule({super.key});

  @override
  Widget build(BuildContext context) {
    return Fiber3DMesh(
      geometry: Fiber3DCapsule(
        radius: 0.6,
        height: 1.2,
        capSegments: 8,
        radialSegments: 16,
      ),
      material: const Fiber3DStandardMaterial(
        color: 0x3366ff,
        roughness: 0.35,
        metalness: 0.6,
      ),
      hitRadius: 1.0,
      onFrame: (elapsed, delta, transform) {
        final t = delta.inMicroseconds / 1e6;
        transform.rotation.y += t;
        transform.rotation.x += t * 0.6;
      },
    );
  }
}