import 'package:flutter/material.dart';
import 'package:flutter_fiber/flutter_fiber.dart';
import 'package:flutter_fiber/src/renderer/fiber3d_canvas.dart';
import 'package:flutter_fiber/src/core/fiber3d_mesh.dart';
import 'package:flutter_fiber/src/core/fiber3d_vector3.dart';
import 'package:flutter_fiber/src/material/fiber3d_standard_material.dart';
import 'package:flutter_fiber/src/light/fiber3d_hemisphere_light.dart';
import 'package:flutter_fiber/src/camera/fiber3d_camera.dart';
import 'package:flutter_fiber/src/geometry/fiber3d_sphere.dart';
import 'package:flutter_fiber/src/geometry/fiber3d_chamfered_box.dart';

void main() {
  runApp(const HemisphereLightDemo());
}

/// Isolated Section 5 test: ONLY a Fiber3DHemisphereLight, nothing else
/// no ambient, no point light, no env-map contribution (envMapIntensity
/// zeroed) so the sky/ground tint is the only thing visible. Strong,
/// clearly different colors (blue sky, orange-brown ground) so a
/// correct result is unmistakable: the top of each shape should read
/// blue, the bottom should read orange-brown, blending through the
/// middle.
///
/// If nothing changes between top and bottom (flat, uniform color,
/// or fully black/unlit), the wiring isn't reaching the shader.
class HemisphereLightDemo extends StatelessWidget {
  const HemisphereLightDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('flutter_fiber: HemisphereLight'),
          backgroundColor: const Color.fromARGB(255, 56, 55, 55),
        ),
        body: Fiber3DCanvas(
          backgroundColor: 0x202020,
          camera: Fiber3DCamera(
            position: const Fiber3DVector3(0, 0, 6),
            target: const Fiber3DVector3.zero(),
          ),
          orbitEnabled: true,
          lights: const [
            Fiber3DHemisphereLight(
              skyColor: 0x4488ff,
              groundColor: 0xaa5522,
              intensity: 1.0,
              direction: Fiber3DVector3(0, 1, 0),
            ),
          ],
          children: [
            Fiber3DMesh(
              geometry: Fiber3DSphere(radius: 1.1),
              material: Fiber3DStandardMaterial(
                color: 0xffffff,
                roughness: 1.0,
                metalness: 0.0,
                envMapIntensity: 0.0,
              ),
              showEdges: false,
              hitRadius: 1.3,
              onFrame: (elapsed, delta, transform) {
                transform.position.set(-1.6, 0, 0);
                transform.rotation.y += (delta.inMicroseconds / 1e6) * 0.4;
              },
            ),
            Fiber3DMesh(
              geometry: Fiber3DChamferedBox(
                width: 1.7,
                height: 1.7,
                depth: 1.7,
                chamferAmount: 0.3,
              ),
              material: Fiber3DStandardMaterial(
                color: 0xffffff,
                roughness: 1.0,
                metalness: 0.0,
                envMapIntensity: 0.0,
              ),
              showEdges: false,
              hitRadius: 1.3,
              onFrame: (elapsed, delta, transform) {
                transform.position.set(1.6, 0, 0);
                transform.rotation.y += (delta.inMicroseconds / 1e6) * 0.4;
              },
            ),
          ],
        ),
      ),
    );
  }
}