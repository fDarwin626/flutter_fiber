import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_fiber/flutter_fiber.dart';
import 'package:flutter_fiber/src/renderer/fiber3d_canvas.dart';
import 'package:flutter_fiber/src/core/fiber3d_group.dart';
import 'package:flutter_fiber/src/core/fiber3d_mesh.dart';
import 'package:flutter_fiber/src/core/fiber3d_vector3.dart';
import 'package:flutter_fiber/src/material/fiber3d_standard_material.dart';
import 'package:flutter_fiber/src/material/fiber3d_text_texture.dart';
import 'package:flutter_fiber/src/material/fiber3d_texture.dart';
import 'package:flutter_fiber/src/light/fiber3d_ambient_light.dart';
import 'package:flutter_fiber/src/light/fiber3d_point_light.dart';
import 'package:flutter_fiber/src/camera/fiber3d_camera.dart';
import 'package:flutter_fiber/src/geometry/fiber3d_plane.dart';

void main() {
  runApp(const DiceShapeDemo());
}

/// text-in-shape: a die built from six Fiber3DPlane faces assembled
/// into a cube shell, each showing a different digit (1-6) rendered via
/// Fiber3DTextTexture. A single Fiber3DBox can't show a different
/// texture per face -- confirmed: Fiber3DMesh takes exactly one
/// material, and there is no per-face/multi-material support -- so six
/// independently textured planes, positioned and rotated to form a
/// cube, is the correct way to build this with what actually exists.
class DiceShapeDemo extends StatefulWidget {
  const DiceShapeDemo({super.key});

  @override
  State<DiceShapeDemo> createState() => _DiceShapeDemoState();
}

/// One cube face: position (half-extent already applied) and a single-
/// axis rotation, matching the exact rotation.x / rotation.y field-
/// assignment pattern already confirmed on-device (earth_main.dart's
/// _SaturnRing, main.dart's rotating group) -- deliberately not using a
/// rotation.set(...) method, which was never confirmed to exist.
class _FaceSpec {
  final double x, y, z;
  final double rotX, rotY;
  final String label;
  const _FaceSpec(this.x, this.y, this.z, this.rotX, this.rotY, this.label);
}

class _DiceShapeDemoState extends State<DiceShapeDemo> {
  static const _half = 0.9; // half of a 1.8-unit cube

  static final List<_FaceSpec> _faces = [
    _FaceSpec(0, 0, _half, 0, 0, '1'), // +Z (Fiber3DPlane's default facing)
    _FaceSpec(_half, 0, 0, 0, pi / 2, '2'), // +X
    _FaceSpec(0, _half, 0, -pi / 2, 0, '3'), // +Y
    _FaceSpec(0, -_half, 0, pi / 2, 0, '4'), // -Y
    _FaceSpec(-_half, 0, 0, 0, -pi / 2, '5'), // -X
    _FaceSpec(0, 0, -_half, 0, pi, '6'), // -Z
  ];

  List<Fiber3DTexture>? _textures;

  @override
  void initState() {
    super.initState();
    Future.wait(
      _faces.map(
        (f) => Fiber3DTextTexture.render(
          text: f.label,
          fontSize: 140,
          color: const Color(0xFF1A1A1A),
          backgroundColor: const Color(0xFFF5F5F5),
        ),
      ),
    ).then((textures) {
      if (!mounted) return;
      setState(() => _textures = textures);
    });
  }

  @override
  Widget build(BuildContext context) {
    final textures = _textures;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('flutter_fiber: text-in-shape (dice)'),
          backgroundColor: const Color.fromARGB(255, 56, 55, 55),
        ),
        body: Fiber3DCanvas(
          backgroundColor: 0x303130,
          camera: Fiber3DCamera(
            position: const Fiber3DVector3(0, 0, 5),
            target: const Fiber3DVector3.zero(),
          ),
          orbitEnabled: true,
          lights: const [
            Fiber3DAmbientLight(color: 0xffffff, intensity: 0.6),
            Fiber3DPointLight(
              color: 0xffffff,
              intensity: 3.0,
              position: Fiber3DVector3(3, 4, 5),
            ),
          ],
          children: textures == null
              ? const []
              : [
                  Fiber3DGroup(
                    onFrame: (elapsed, delta, transform) {
                      final t = delta.inMicroseconds / 1e6;
                      transform.rotation.y += t;
                      transform.rotation.x += t * 0.4;
                    },
                    children: [
                      for (var i = 0; i < _faces.length; i++)
                        Fiber3DMesh(
                          geometry:
                              Fiber3DPlane(width: 1.8, height: 1.8),
                          material: Fiber3DStandardMaterial(
                            map: textures[i],
                            roughness: 0.6,
                            metalness: 0.0,
                          ),
                          showEdges: false,
                          hitRadius: 1.0,
                          onFrame: (elapsed, delta, transform) {
                            final f = _faces[i];
                            transform.position.set(f.x, f.y, f.z);
                            transform.rotation.x = f.rotX;
                            transform.rotation.y = f.rotY;
                            transform.rotation.z = 0.0;
                          },
                        ),
                    ],
                  ),
                ],
        ),
      ),
    );
  }
}