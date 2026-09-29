import 'package:flutter/material.dart';
import 'package:flutter_fiber/flutter_fiber.dart';
import 'package:flutter_fiber/src/renderer/fiber3d_canvas.dart';
import 'package:flutter_fiber/src/core/fiber3d_mesh.dart';
import 'package:flutter_fiber/src/core/fiber3d_vector3.dart';
import 'package:flutter_fiber/src/material/fiber3d_standard_material.dart';
import 'package:flutter_fiber/src/light/fiber3d_ambient_light.dart';
import 'package:flutter_fiber/src/light/fiber3d_point_light.dart';
import 'package:flutter_fiber/src/camera/fiber3d_camera.dart';
import 'package:flutter_fiber/src/geometry/fiber3d_sphere.dart';
import 'package:flutter_fiber/src/material/fiber3d_checkerboard_sky.dart';
void main() {
  runApp(const ReflectionsDemo());
}

/// Five identical spheres (metalness 1.0), roughness stepped 0.0 -> 1.0
/// left to right. Exists to make Section 6's environment reflections
/// visually unmistakable: sphere 1 should show a sharp sky reflection,
/// sphere 5 a soft gradient with no distinct reflection at all, and each
/// step in between visibly blurrier than the last (roughnessToMip
/// picking a blurrier Fiber3DPrefilteredCube level as roughness rises).
///
/// Deliberately minimal lighting -- a dim ambient plus one modest point
/// light -- so the visible highlight on each sphere is the environment
/// reflection, not the direct point light's own specular.
///
/// Position has no constructor param on Fiber3DMesh (confirmed against
/// fiber3d_mesh.dart / fiber3d_object.dart) -- each sphere sets its fixed
/// x via transform.position.set(...) inside onFrame, the only exposed
/// write path, same pattern main.dart/earth_main.dart use for rotation.
class ReflectionsDemo extends StatelessWidget {
  const ReflectionsDemo({super.key});

  static const _roughnessSteps = [0.0, 0.25, 0.5, 0.75, 1.0];
  static const _spacing = 1.6;

  @override
  Widget build(BuildContext context) {
    final n = _roughnessSteps.length;
    final startX = -_spacing * (n - 1) / 2;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text(
            'flutter_fiber: env reflections (roughness 0.0 -> 1.0)',
          ),
          backgroundColor: const Color.fromARGB(255, 56, 55, 55),
        ),
        body: Fiber3DCanvas(
          backgroundColor: 0x303130,
          envMapRadiance: const Fiber3DCheckerboardSky().radiance,
          camera: Fiber3DCamera(
            position: const Fiber3DVector3(0, 0, 7),
            target: const Fiber3DVector3.zero(),
          ),
          orbitEnabled: true,
          lights: const [
            Fiber3DAmbientLight(color: 0xffffff, intensity: 0.15),
            Fiber3DPointLight(
              color: 0xffffff,
              intensity: 1.0,
              position: Fiber3DVector3(3, 4, 5),
            ),
          ],
          children: [
            for (var i = 0; i < n; i++)
              Fiber3DMesh(
                geometry: Fiber3DSphere(radius: 0.65),

                material: Fiber3DStandardMaterial(
                  color: 0xffffff,
                  metalness: 1.0,
                  roughness: _roughnessSteps[i],
                  // Clearcoat only on the last (roughest, blurriest) sphere
                  // the other four stay clearcoat: 0.0 as the control.
                  clearcoat: i == n - 1 ? 1.0 : 0.0,
                  clearcoatRoughness: 0.05,
                ),
                showEdges:false,
                hitRadius: 0.8,
                onFrame: (elapsed, delta, transform) {
                  transform.position.set(startX + i * _spacing, 0, 0);
                },
              ),
          ],
        ),
      ),
    );
  }
}