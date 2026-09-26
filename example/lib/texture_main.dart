import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_fiber/flutter_fiber.dart';
import 'package:flutter_fiber/src/renderer/fiber3d_canvas.dart';
import 'package:flutter_fiber/src/core/fiber3d_mesh.dart';
import 'package:flutter_fiber/src/core/fiber3d_vector3.dart';
import 'package:flutter_fiber/src/material/fiber3d_standard_material.dart';
import 'package:flutter_fiber/src/material/fiber3d_texture.dart';
import 'package:flutter_fiber/src/light/fiber3d_ambient_light.dart';
import 'package:flutter_fiber/src/light/fiber3d_point_light.dart';
import 'package:flutter_fiber/src/camera/fiber3d_camera.dart';
import 'package:flutter_fiber/src/geometry/fiber3d_box.dart';

void main() {
  runApp(const FiberTextureDemo());
}

/// Section 1 (texture pipeline) real on-device test: a Fiber3DStandardMaterial
/// with a real `map` texture, decoded from actual image bytes the true
/// test of the whole pipeline (UV plumbing, Fiber3DTexture decode/upload,
/// USE_MAP sampling), not just flutter test's string checks.
class FiberTextureDemo extends StatefulWidget {
  const FiberTextureDemo({super.key});

  @override
  State<FiberTextureDemo> createState() => _FiberTextureDemoState();
}

class _FiberTextureDemoState extends State<FiberTextureDemo> {
  Fiber3DTexture? _texture;

  @override
  void initState() {
    super.initState();
    _loadTexture();
  }

  Future<void> _loadTexture() async {
    final data = await rootBundle.load('assets/images/iki_logo.png');
    final bytes = data.buffer.asUint8List();
    setState(() {
      _texture = Fiber3DTexture(bytes);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF1A1A1A),
        body: _texture == null
            ? const Center(child: CircularProgressIndicator())
            : Fiber3DCanvas(
                backgroundColor: 0x1A1A1A,
                camera: Fiber3DCamera(
                  position: const Fiber3DVector3(0, 0, 4),
                  target: const Fiber3DVector3.zero(),
                ),
                orbitEnabled: true,
                lights: [
                  const Fiber3DAmbientLight(color: 0xffffff, intensity: 0.7),
                  Fiber3DPointLight(
                    color: 0xffffff,
                    intensity: 2.5,
                    position: const Fiber3DVector3(3, 4, 5),
                  ),
                ],
                children: [
                  Fiber3DMesh(
                    geometry: Fiber3DBox(width: 1.0, height: 1.0, depth: 1.0),
                    material: Fiber3DStandardMaterial(
                      color: 0xffffff,
                      roughness: 0.6,
                      metalness: 0.0,
                      map: _texture,
                    ),
                    showEdges: false,
                    onFrame: (elapsed, delta, transform) {
                      final t = elapsed.inMicroseconds / 1e6;
                      transform.rotation.y = t * 0.5;
                      transform.rotation.x = t * 0.2;
                    },
                  ),
                ],
              ),
      ),
    );
  }
}