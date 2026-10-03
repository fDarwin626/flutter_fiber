import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_fiber/flutter_fiber.dart';
import 'package:flutter_fiber/src/renderer/fiber3d_canvas.dart';
import 'package:flutter_fiber/src/core/fiber3d_vector3.dart';
import 'package:flutter_fiber/src/light/fiber3d_ambient_light.dart';
import 'package:flutter_fiber/src/light/fiber3d_point_light.dart';
import 'package:flutter_fiber/src/camera/fiber3d_camera.dart';

void main() {
  runApp(const GltfModelDemo());
}

/// Section 9 end-to-end test: loads example/assets/images/car.glb through
/// the real pipeline (Fiber3DGltfLoader -> Fiber3DGltfScene ->
/// Fiber3DGltfModel) and displays it. This is the actual proof the
/// loader, material mapping, and node-hierarchy wiring all work together
/// on a real file -- not just that the code compiles.
///
/// Camera distance/position is a guess -- car.glb's own scale and
/// origin are unknown until it's actually seen on-device. orbitEnabled
/// lets you pan/zoom to find it if it's off-frame; tell me what you see
/// (nothing, something tiny/huge, something in the wrong place) and
/// I'll adjust rather than guess twice.
class GltfModelDemo extends StatefulWidget {
  const GltfModelDemo({super.key});

  @override
  State<GltfModelDemo> createState() => _GltfModelDemoState();
}

class _GltfModelDemoState extends State<GltfModelDemo> {
  Fiber3DGltfScene? _scene;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await rootBundle.load('assets/images/motor.glb');
      final bytes = data.buffer.asUint8List();
      final scene = await Fiber3DGltfLoader.loadGlb(bytes);
      if (!mounted) return;
      setState(() => _scene = scene);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('flutter_fiber: GLTF model (car.glb)'),
          backgroundColor: const Color.fromARGB(255, 56, 55, 55),
        ),
        body: _error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Failed to load car.glb:\n$_error',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              )
            : _scene == null
                ? const Center(child: CircularProgressIndicator())
                : Fiber3DCanvas(
                    backgroundColor: 0x303130,
                    camera: Fiber3DCamera(
                      position: const Fiber3DVector3(0, 2, 8),
                      target: const Fiber3DVector3.zero(),
                    ),
                    orbitEnabled: true,
                    lights: const [
                      Fiber3DAmbientLight(color: 0xffffff, intensity: 0.6),
                      Fiber3DPointLight(
                        color: 0xffffff,
                        intensity: 3.0,
                        position: Fiber3DVector3(4, 5, 5),
                      ),
                      Fiber3DPointLight(
                        color: 0xffffff,
                        intensity: 1.5,
                        position: Fiber3DVector3(-4, 2, -2),
                      ),
                    ],

                    // First guess at the scale mismatch -- bump this up
                    // or down based on what you actually see.
                    children: [Fiber3DGltfModel(scene: _scene!, scale: 1.3)],                  ),
      ),
    );
  }
}