import 'package:flutter/material.dart';
import 'package:flutter_fiber/flutter_fiber.dart';
import 'package:flutter_fiber/src/renderer/fiber3d_canvas.dart';
import 'package:flutter_fiber/src/core/fiber3d_group.dart';
import 'package:flutter_fiber/src/core/fiber3d_mesh.dart';
import 'package:flutter_fiber/src/core/fiber3d_vector3.dart';
import 'package:flutter_fiber/src/material/fiber3d_standard_material.dart';
import 'package:flutter_fiber/src/material/fiber3d_procedural_sky.dart';
import 'package:flutter_fiber/src/light/fiber3d_ambient_light.dart';
import 'package:flutter_fiber/src/light/fiber3d_point_light.dart';
import 'package:flutter_fiber/src/camera/fiber3d_camera.dart';
import 'package:flutter_fiber/src/geometry/fiber3d_sphere.dart';
import 'package:flutter_fiber/src/geometry/fiber3d_chamfered_box.dart';

void main() {
  runApp(const QualityShowcase());
}

/// Full-potential comparison: Sphere and ChamferedBox, each shown matte
/// (high roughness, no metal), glossy (low roughness, full metal +
/// clearcoat), and glass (transparent, low roughness, clearcoat) -- a
/// 2x3 grid, ACES Filmic tone mapping, boosted PMREM quality
/// (envMapSize/envMapSamples on Fiber3DCanvas).
///
/// Glass is a single, non-overlapping transparent surface -- there is
/// no depth-sorted transparent draw pass in the canvas yet, so multiple
/// OVERLAPPING transparent meshes could show sorting artifacts; that
/// case isn't tested here.
class QualityShowcase extends StatelessWidget {
  const QualityShowcase({super.key});

  static const _colX = [-1.8, 0.0, 1.8]; // matte, glossy, glass
  static const _rowY = [1.1, -1.1]; // sphere, chamfered box

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('flutter_fiber: quality showcase'),
          backgroundColor: const Color.fromARGB(255, 56, 55, 55),
        ),
        body: Fiber3DCanvas(
          backgroundColor: 0x1a1a1a,
          toneMapping: Fiber3DToneMapping.acesFilmic,
          toneMappingExposure: 1.1,
          // Bumped from the 128/32 default -- real generation-time cost,
          // see the field docs on Fiber3DCanvas.
          envMapSize: 256,
          envMapSamples: 64,
          envMapRadiance: Fiber3DProceduralSky(
            skyColor: const [0.55, 0.7, 0.95],
            horizonColor: const [0.85, 0.85, 0.88],
            groundColor: const [0.25, 0.24, 0.26],
            sunDirection: const [0.4, 0.7, 0.4],
            sunColor: const [6.0, 5.6, 5.0],
          ).radiance,
          camera: Fiber3DCamera(
            position: const Fiber3DVector3(0, 0, 9),
            target: const Fiber3DVector3.zero(),
          ),
          orbitEnabled: true,
          lights: const [
            Fiber3DAmbientLight(color: 0xffffff, intensity: 0.3),
            Fiber3DPointLight(
              color: 0xfff4e8,
              intensity: 3.0,
              position: Fiber3DVector3(4, 5, 6),
            ),
          ],
          children: [
            Fiber3DGroup(
              onFrame: (elapsed, delta, transform) {
                final t = delta.inMicroseconds / 1e6;
                transform.rotation.y += t * 0.3;
              },
              children: [
                for (var row = 0; row < 2; row++)
                  for (var col = 0; col < 3; col++)
                    _Piece(
                      x: _colX[col],
                      y: _rowY[row],
                      geometry: row == 0
                          ? Fiber3DSphere(radius: 0.75)
                          : Fiber3DChamferedBox(
                              width: 1.2,
                              height: 1.2,
                              depth: 1.2,
                              chamferAmount: 0.28,
                            ),
                      material: _materialFor(col),
                    ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Fiber3DStandardMaterial _materialFor(int col) {
    switch (col) {
      case 0:
        return _matte;
      case 1:
        return _glossy;
      default:
        return _glass;
    }
  }

  static Fiber3DStandardMaterial get _matte => Fiber3DStandardMaterial(
        color: 0xd8d8d8,
        roughness: 0.9,
        metalness: 0.0,
      );

  static Fiber3DStandardMaterial get _glossy => Fiber3DStandardMaterial(
        color: 0xffffff,
        roughness: 0.06,
        metalness: 1.0,
        clearcoat: 1.0,
        clearcoatRoughness: 0.03,
      );

  static Fiber3DStandardMaterial get _glass => Fiber3DStandardMaterial(
        color: 0xffffff,
        roughness: 0.05,
        metalness: 0.0,
        opacity: 0.35,
        transparent: true,
        clearcoat: 1.0,
        clearcoatRoughness: 0.02,
      );
}

/// One positioned, self-spinning piece inside the group. Position is set
/// (not animated) via onFrame -- the only confirmed write path to a
/// mesh's transform.
class _Piece extends StatelessWidget {
  final double x;
  final double y;
  final dynamic geometry;
  final Fiber3DStandardMaterial material;

  const _Piece({
    required this.x,
    required this.y,
    required this.geometry,
    required this.material,
  });

  @override
  Widget build(BuildContext context) {
    return Fiber3DMesh(
      geometry: geometry,
      material: material,
      showEdges: false,
      hitRadius: 1.0,
      onFrame: (elapsed, delta, transform) {
        transform.position.set(x, y, 0);
        transform.rotation.y += (delta.inMicroseconds / 1e6) * 0.6;
      },
    );
  }
}