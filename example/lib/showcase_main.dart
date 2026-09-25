import 'package:flutter/material.dart';
import 'package:flutter_fiber/flutter_fiber.dart';
import 'package:flutter_fiber/src/renderer/fiber3d_canvas.dart';
import 'package:flutter_fiber/src/renderer/fiber3d_tone_mapping.dart';
import 'package:flutter_fiber/src/core/fiber3d_mesh.dart';
import 'package:flutter_fiber/src/core/fiber3d_vector3.dart';
import 'package:flutter_fiber/src/material/fiber3d_standard_material.dart';
import 'package:flutter_fiber/src/material/fiber3d_lambert_material.dart';
import 'package:flutter_fiber/src/material/fiber3d_phong_material.dart';
import 'package:flutter_fiber/src/light/fiber3d_ambient_light.dart';
import 'package:flutter_fiber/src/light/fiber3d_point_light.dart';
import 'package:flutter_fiber/src/camera/fiber3d_camera.dart';
import 'package:flutter_fiber/src/geometry/fiber3d_torus_knot.dart';
import 'package:flutter_fiber/src/geometry/fiber3d_icosahedron.dart';
import 'package:flutter_fiber/src/geometry/fiber3d_sphere.dart';

void main() {
  runApp(const FiberShowcase());
}

/// Section 4b showcase: every material flutter_fiber currently has
/// (Physical/Standard, Lambert, Phong) drawn simultaneously, in the same
/// frame, with real ACES Filmic tone mapping deliberately the opposite
/// of the shape-gallery's one-at-a-time toggle test. This is both the
/// best-looking scene currently reachable and the real test of
/// same-frame material interleaving (three compiled programs drawing
/// back to back every frame, not sequential frames with a rebuild
/// between them).
class FiberShowcase extends StatelessWidget {
  const FiberShowcase({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF0A0A12),
        body: Fiber3DCanvas(
          backgroundColor: 0x0A0A12,
          colorManagement: true,
          toneMapping: Fiber3DToneMapping.acesFilmic,
          toneMappingExposure: 1.1,
          camera: Fiber3DCamera(
            position: const Fiber3DVector3(0, 1.2, 8),
            target: const Fiber3DVector3.zero(),
          ),
          orbitEnabled: true,
          lights: [
            // Low ambient so the point lights do the real work a flat
            // scene doesn't show off Phong's specular or PBR's GGX.
            const Fiber3DAmbientLight(color: 0xffffff, intensity: 0.25),
            // Key light warm, bright, off to one side.
            Fiber3DPointLight(
              color: 0xfff2e0,
              intensity: 6.0,
              position: const Fiber3DVector3(4, 5, 4),
            ),
            // Fill light cool, dimmer, opposite side, keeps shadows
            // from going fully black without washing out the highlights.
            Fiber3DPointLight(
              color: 0x88aaff,
              intensity: 2.0,
              position: const Fiber3DVector3(-5, 2, 2),
            ),
            // Rim/back light  picks out silhouettes from behind.
            Fiber3DPointLight(
              color: 0xffffff,
              intensity: 2.5,
              position: const Fiber3DVector3(0, 3, -5),
            ),
          ],
          children: const [
            _PhongTorusKnot(),
            _LambertIcosahedron(),
            _PbrHeroSphere(),
            _PbrGradientRow(),
          ],
        ),
      ),
    );
  }
}

/// Center: Blinn-Phong torus knot the specular highlight is the
/// clearest way to see Phong's shading model at a glance.
class _PhongTorusKnot extends StatelessWidget {
  const _PhongTorusKnot();

  @override
  Widget build(BuildContext context) {
    return Fiber3DMesh(
      geometry: Fiber3DTorusKnot(radius: 1.1, tube: 0.35),
      material: Fiber3DPhongMaterial(
        color: 0xcc4433,
        specular: 0xffffff,
        shininess: 80.0,
      ),
      onFrame: (elapsed, delta, transform) {
        transform.position.set(0, 0.6, 0);
        final t = elapsed.inMicroseconds / 1e6;
        transform.rotation.y = t * 0.6;
        transform.rotation.x = t * 0.25;
      },
    );
  }
}

/// Left: Lambert icosahedron pure diffuse, no specular at all, the
/// clearest possible contrast against the Phong piece next to it.
class _LambertIcosahedron extends StatelessWidget {
  const _LambertIcosahedron();

  @override
  Widget build(BuildContext context) {
    return Fiber3DMesh(
      geometry: Fiber3DIcosahedron(radius: 1.0),
      material: Fiber3DLambertMaterial(
        color: 0x33aa77,
        flatShading: true,
      ),
      onFrame: (elapsed, delta, transform) {
        transform.position.set(-3.2, 0.6, -0.5);
        final t = elapsed.inMicroseconds / 1e6;
        transform.rotation.y = t * 0.4;
      },
    );
  }
}

/// Right: a single, larger PBR sphere at low roughness/high specular
/// response the GGX highlight this material is actually capable of,
/// front and center rather than buried in a small reference grid.
class _PbrHeroSphere extends StatelessWidget {
  const _PbrHeroSphere();

  @override
  Widget build(BuildContext context) {
    return Fiber3DMesh(
      geometry: Fiber3DSphere(radius: 1.0, widthSegments: 64, heightSegments: 48),
      material: Fiber3DStandardMaterial(
        color: 0x2255cc,
        roughness: 0.15,
        metalness: 0.6,
      ),
      onFrame: (elapsed, delta, transform) {
        transform.position.set(3.2, 0.6, -0.5);
        final t = elapsed.inMicroseconds / 1e6;
        transform.rotation.y = t * 0.5;
      },
    );
  }
}

/// A small roughness x metalness gradient of PBR spheres along the
/// bottom the same idea as reference_main.dart's comparison grid, but
/// as part of a real lit scene rather than an isolated test page.
class _PbrGradientRow extends StatelessWidget {
  const _PbrGradientRow();

  static const List<double> _roughness = [0.05, 0.3, 0.6, 1.0];
  static const double _spacing = 0.85;

  @override
  Widget build(BuildContext context) {
    return Fiber3DGroup(
      onFrame: (elapsed, delta, transform) {
        transform.position.set(0, -1.6, 1.5);
      },
      children: [
        for (var i = 0; i < _roughness.length; i++)
          Fiber3DMesh(
            geometry: Fiber3DSphere(radius: 0.32, widthSegments: 32, heightSegments: 24),
            material: Fiber3DStandardMaterial(
              color: 0xdddddd,
              roughness: _roughness[i],
              metalness: 1.0,
            ),
            onFrame: (elapsed, delta, transform) {
              final x = (i - (_roughness.length - 1) / 2) * _spacing;
              transform.position.set(x, 0, 0);
            },
          ),
      ],
    );
  }
}