import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_fiber/flutter_fiber.dart';
import 'package:flutter_fiber/src/renderer/fiber3d_canvas.dart';
import 'package:flutter_fiber/src/core/fiber3d_mesh.dart';
import 'package:flutter_fiber/src/core/fiber3d_vector3.dart';
import 'package:flutter_fiber/src/material/fiber3d_standard_material.dart';
import 'package:flutter_fiber/src/material/fiber3d_texture.dart';
import 'package:flutter_fiber/src/material/fiber3d_widget_texture.dart';
import 'package:flutter_fiber/src/light/fiber3d_ambient_light.dart';
import 'package:flutter_fiber/src/light/fiber3d_point_light.dart';
import 'package:flutter_fiber/src/camera/fiber3d_camera.dart';
import 'package:flutter_fiber/src/geometry/fiber3d_plane.dart';
import 'package:lottie/lottie.dart';

void main() {
  runApp(const LottieShapeDemo());
}

/// Lottie-in-shape: a Lottie animation applied as a live texture on a
/// plane's UV face, via the package's own Fiber3DWidgetTexture (captures
/// ANY widget off-screen -- flutter_fiber has no dependency on the
/// `lottie` package itself, only this app does).
///
/// Drop your own Lottie JSON at assets/lottie/test.json before running
/// this -- no Lottie file ships with flutter_fiber itself.
class LottieShapeDemo extends StatefulWidget {
  const LottieShapeDemo({super.key});

  @override
  State<LottieShapeDemo> createState() => _LottieShapeDemoState();
}

class _LottieShapeDemoState extends State<LottieShapeDemo> {
  // 1x1 opaque white placeholder shown until the first captured frame
  // lands.
  final Fiber3DTexture _texture = Fiber3DTexture.raw(
    Uint8List.fromList([255, 255, 255, 255]),
    1,
    1,
  );
  Uint8List? _lottieBytes;

  @override
  void initState() {
    super.initState();
    rootBundle.load('assets/lottie/test.json').then((data) {
      if (!mounted) return;
      setState(() => _lottieBytes = data.buffer.asUint8List());
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('flutter_fiber: Lottie-in-shape'),
          backgroundColor: const Color.fromARGB(255, 56, 55, 55),
        ),
        body: Stack(
          children: [
            Fiber3DCanvas(
              backgroundColor: 0x303130,
              camera: Fiber3DCamera(
                position: const Fiber3DVector3(0, 0, 4),
                target: const Fiber3DVector3.zero(),
              ),
              orbitEnabled: true,
              lights: const [
                Fiber3DAmbientLight(color: 0xffffff, intensity: 0.8),
                Fiber3DPointLight(
                  color: 0xffffff,
                  intensity: 1.5,
                  position: Fiber3DVector3(3, 4, 5),
                ),
              ],
              children: [
                Fiber3DMesh(
                  geometry: Fiber3DPlane(width: 2, height: 2),
                  material: Fiber3DStandardMaterial(
                    map: _texture,
                    roughness: 1.0,
                    metalness: 0.0,
                  ),
                  hitRadius: 1.5,
                  // Keeps Fiber3DCanvas's own render ticker alive --
                  // without a registered onFrame it stops after one
                  // frame and never re-reads the texture again.
                  onFrame: (elapsed, delta, transform) {},
                ),
              ],
            ),
            if (_lottieBytes != null)
              Fiber3DWidgetTexture(
                texture: _texture,
                child: Lottie.memory(_lottieBytes!),
              ),
          ],
        ),
      ),
    );
  }
}