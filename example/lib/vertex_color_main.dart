import 'package:flutter/material.dart';
import 'package:flutter_fiber/flutter_fiber.dart';
import 'package:flutter_fiber/src/renderer/fiber3d_canvas.dart';
import 'package:flutter_fiber/src/core/fiber3d_mesh.dart';
import 'package:flutter_fiber/src/core/fiber3d_vector3.dart';
import 'package:flutter_fiber/src/material/fiber3d_standard_material.dart';
import 'package:flutter_fiber/src/light/fiber3d_ambient_light.dart';
import 'package:flutter_fiber/src/light/fiber3d_point_light.dart';
import 'package:flutter_fiber/src/camera/fiber3d_camera.dart';
import 'package:flutter_fiber/src/geometry/fiber3d_box.dart';

void main() {
  runApp(const FiberVertexColorDemo());
}

/// Section 2 (vertex colors) real on-device test: one box with a real
/// per-face `colors` override sitting next to a plain box with no colors
/// set, same material otherwise proving both the override path and
/// the white-fallback (renders as the material's flat color) side by
/// side in one scene.
class FiberVertexColorDemo extends StatelessWidget {
  const FiberVertexColorDemo({super.key});

  // Fiber3DBox with default segments builds exactly 4 vertices per face,
  // 6 faces, in a fixed order: px, nx, py, ny, pz, nz (confirmed from
  // Fiber3DBox's own source). One distinct color per face, 4 vertices
  // each, gives a clean 6-color "rainbow cube" with no blending across
  // face boundaries (each face's 4 vertices share one color).
  static List<double> _rainbowColors() {
    const faceColors = [
      [1.0, 0.2, 0.2], // px — red
      [0.2, 1.0, 0.2], // nx — green
      [0.2, 0.4, 1.0], // py — blue
      [1.0, 1.0, 0.2], // ny — yellow
      [1.0, 0.2, 1.0], // pz — magenta
      [0.2, 1.0, 1.0], // nz — cyan
    ];
    final colors = <double>[];
    for (final c in faceColors) {
      for (var i = 0; i < 4; i++) {
        colors.addAll(c);
      }
    }
    return colors;
  }

  @override
  Widget build(BuildContext context) {
    final coloredBox = Fiber3DBox(width: 1.4, height: 1.4, depth: 1.4)
      ..colors = _rainbowColors();
    final plainBox = Fiber3DBox(width: 1.4, height: 1.4, depth: 1.4);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF1A1A1A),
        body: Fiber3DCanvas(
          backgroundColor: 0x1A1A1A,
          camera: Fiber3DCamera(
            position: const Fiber3DVector3(0, 0, 6),
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
            // Left: vertex colors override the material's own color —
            // should show 6 distinct flat-colored faces regardless of
            // the material's own color: 0xffffff below.
            Fiber3DMesh(
              geometry: coloredBox,
              material: Fiber3DStandardMaterial(
                color: 0xffffff,
                roughness: 0.6,
              ),
              showEdges: false,
              onFrame: (elapsed, delta, transform) {
                transform.position.set(-1.2, 0, 0);
                final t = elapsed.inMicroseconds / 1e6;
                transform.rotation.y = t * 0.5;
                transform.rotation.x = t * 0.2;
              },
            ),
            // Right: no colors set should render as a plain orange
            // box (the material's own flat color), proving the
            // white-fallback path is a true no-op.
            Fiber3DMesh(
              geometry: plainBox,
              material: Fiber3DStandardMaterial(
                color: 0xff8800,
                roughness: 0.6,
              ),
              showEdges: false,
              onFrame: (elapsed, delta, transform) {
                transform.position.set(1.2, 0, 0);
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