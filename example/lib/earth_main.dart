import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_fiber/flutter_fiber.dart';
import 'package:flutter_fiber/src/renderer/fiber3d_canvas.dart';
import 'package:flutter_fiber/src/renderer/fiber3d_tone_mapping.dart';
import 'package:flutter_fiber/src/core/fiber3d_mesh.dart';
import 'package:flutter_fiber/src/core/fiber3d_vector3.dart';
import 'package:flutter_fiber/src/material/fiber3d_standard_material.dart';
import 'package:flutter_fiber/src/material/fiber3d_texture.dart';
import 'package:flutter_fiber/src/light/fiber3d_ambient_light.dart';
import 'package:flutter_fiber/src/light/fiber3d_point_light.dart';
import 'package:flutter_fiber/src/camera/fiber3d_camera.dart';
import 'package:flutter_fiber/src/geometry/fiber3d_sphere.dart';

void main() {
  runApp(const FiberEarthDemo());
}

/// Current best-quality visual test: an Earth-textured sphere (real
/// map texture, tuned roughness/metalness, ACES Filmic tone mapping,
/// a 3-point-style light rig) with a tilted ring and small moons
/// orbiting it — this is meant to show flutter_fiber's actual current
/// visual ceiling, not test any one feature in isolation.
class FiberEarthDemo extends StatefulWidget {
  const FiberEarthDemo({super.key});

  @override
  State<FiberEarthDemo> createState() => _FiberEarthDemoState();
}

class _FiberEarthDemoState extends State<FiberEarthDemo> {
  Fiber3DTexture? _earthTexture;

  @override
  void initState() {
    super.initState();
    _loadTexture();
  }

  Future<void> _loadTexture() async {
    final data = await rootBundle.load('assets/images/earth.jpg');
    final bytes = data.buffer.asUint8List();
    setState(() {
      _earthTexture = Fiber3DTexture(bytes);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF05050A),
        body: _earthTexture == null
            ? const Center(child: CircularProgressIndicator())
            : Fiber3DCanvas(
                backgroundColor: 0x05050A,
                colorManagement: true,
                toneMapping: Fiber3DToneMapping.acesFilmic,
                toneMappingExposure: 1.1,
                camera: Fiber3DCamera(
                  position: const Fiber3DVector3(0, 1.5, 7),
                  target: const Fiber3DVector3.zero(),
                ),
                orbitEnabled: true,
                lights: [
                  // Bright, near-white ambient — necessary here since
                  // earth.jpg is a "night lights" texture (dark navy with
                  // gold city-light dots by design), not a daytime
                  // texture; no amount of directional light brightens a
                  // texture whose own pixels are dark. Swap in a daytime
                  // Blue Marble-style texture for a properly lit look.
                  const Fiber3DAmbientLight(color: 0xffffff, intensity: 0.9),
                  Fiber3DPointLight(
                    color: 0xfff4e8,
                    intensity: 12.0,
                    position: const Fiber3DVector3(6, 3, 4),
                  ),
                  Fiber3DPointLight(
                    color: 0x8899cc,
                    intensity: 3.0,
                    position: const Fiber3DVector3(-5, -1, -3),
                  ),
                ],
                children: [
                  _EarthSphere(texture: _earthTexture!),
                  const _Moon(radius: 0.14, orbitRadius: 2.6, speed: 0.8, tiltY: 0.15),
                  const _Moon(radius: 0.09, orbitRadius: 3.3, speed: -0.5, tiltY: -0.25),
                  const _Moon(radius: 0.06, orbitRadius: 4.0, speed: 1.1, tiltY: 0.35),
                ],



              ),
      ),
    );
  }
}

class _EarthSphere extends StatelessWidget {
  final Fiber3DTexture texture;
  const _EarthSphere({required this.texture});

  @override
  Widget build(BuildContext context) {
    return Fiber3DMesh(
      geometry: Fiber3DSphere(radius: 1.8, widthSegments: 64, heightSegments: 48),
      material: Fiber3DStandardMaterial(
        color: 0xffffff,
        map: texture,
        // Real Earth isn't metallic and its surface (land/cloud) is
        // fairly rough — this is the "best tuning available today"
        // without a real roughness/metalness map texture, which needs
        // its own real image asset to wire in as a fast follow.
        roughness: 0.85,
        metalness: 0.0,
      ),
      showEdges: false,
      onFrame: (elapsed, delta, transform) {
        final t = elapsed.inMicroseconds / 1e6;
        // Earth's real axial tilt is ~23.4 degrees.
        transform.rotation.x = 23.4 * pi / 180;
        transform.rotation.y = t * 0.25;
      },
    );
  }
}


/// A small moon orbiting the Earth sphere at its own radius/speed —
/// position computed directly each frame (no parent transform needed
/// for a simple circular orbit).
class _Moon extends StatelessWidget {
  final double radius;
  final double orbitRadius;
  final double speed;
  final double tiltY;

  const _Moon({
    required this.radius,
    required this.orbitRadius,
    required this.speed,
    required this.tiltY,
  });

  @override
  Widget build(BuildContext context) {
    return Fiber3DMesh(
      geometry: Fiber3DSphere(radius: radius, widthSegments: 24, heightSegments: 16),
      material: Fiber3DStandardMaterial(
        color: 0xaaaaaa,
        roughness: 0.95,
        metalness: 0.0,
      ),
      showEdges: false,
      onFrame: (elapsed, delta, transform) {
        final t = elapsed.inMicroseconds / 1e6;
        final angle = t * speed;
        final x = cos(angle) * orbitRadius;
        final z = sin(angle) * orbitRadius;
        final y = sin(angle) * orbitRadius * tiltY;
        transform.position.set(x, y, z);
        transform.rotation.y = t * 1.5;
      },
    );
  }
}