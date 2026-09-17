import 'package:flutter/material.dart';
import 'package:flutter_fiber/src/core/fiber3d_canvas.dart';
import 'package:flutter_fiber/src/core/fiber3d_mesh.dart';
import 'package:flutter_fiber/src/core/fiber3d_vector3.dart';
import 'package:flutter_fiber/src/material/fiber3d_standard_material.dart';
import 'package:flutter_fiber/src/light/fiber3d_ambient_light.dart';
import 'package:flutter_fiber/src/light/fiber3d_point_light.dart';
import 'package:flutter_fiber/src/camera/fiber3d_camera.dart';
import 'package:flutter_fiber/src/geometry/fiber3d_cone.dart';
import 'package:flutter_fiber/src/geometry/fiber3d_icosahedron.dart';
import 'package:flutter_fiber/src/geometry/fiber3d_dodecahedron.dart';
import 'package:flutter_fiber/src/geometry/fiber3d_circle.dart';
import 'package:flutter_fiber/src/geometry/fiber3d_lathe.dart';

// ----- TOGGLE THIS to flip every shape between "see the structure" and
// "the real deal" ------------------------------------------------------
const bool kShowWires = false;
// -----------------------------------------------------------------------

void main() {
  runApp(const FiberNewShapesTest());
}

class FiberNewShapesTest extends StatelessWidget {
  const FiberNewShapesTest({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('flutter_fiber new shapes batch test'),
          backgroundColor: const Color(0xFF828282),
        ),
        body: Fiber3DCanvas(
          backgroundColor: 0x828282,
          camera: Fiber3DCamera(
            position: const Fiber3DVector3(0, 0, 10),
            target: const Fiber3DVector3.zero(),
          ),
          orbitEnabled: true,
          lights: [
            const Fiber3DAmbientLight(color: 0xffffff, intensity: 0.6),
            Fiber3DPointLight(
              color: 0xffffff,
              intensity: 3.0,
              position: const Fiber3DVector3(3, 4, 5),
            ),
            Fiber3DPointLight(
              color: 0xffffff,
              intensity: 1.5,
              position: const Fiber3DVector3(-3, 2, -2),
            ),
          ],
          children: const [
            _PositionedSpinner(
              offsetX: -4,
              child: _ConeShape(),
            ),
            _PositionedSpinner(
              offsetX: -2,
              child: _IcosahedronShape(),
            ),
            _PositionedSpinner(
              offsetX: 0,
              child: _DodecahedronShape(),
            ),
            _PositionedSpinner(
              offsetX: 2,
              child: _CircleShape(),
            ),
            _PositionedSpinner(
              offsetX: 4.5,
              child: _LatheShape(),
            ),
          ],
        ),
      ),
    );
  }
}

// Shared spin behavior + one-time positioning along X, reused for every
// shape in this test row.
class _PositionedSpinner extends StatefulWidget {
  final double offsetX;
  final Widget child;
  const _PositionedSpinner({required this.offsetX, required this.child});

  @override
  State<_PositionedSpinner> createState() => _PositionedSpinnerState();
}

class _PositionedSpinnerState extends State<_PositionedSpinner> {
  @override
  Widget build(BuildContext context) => widget.child;
}

class _ConeShape extends StatelessWidget {
  const _ConeShape();
  @override
  Widget build(BuildContext context) {
    return Fiber3DMesh(
      geometry: Fiber3DCone(radius: 0.8, height: 1.5, radialSegments: 32),
      material: const Fiber3DStandardMaterial(
        color: 0xff6633,
        roughness: 0.5,
        metalness: 0.2,
        flatShading: true,
        wireframe: false,
      ),
      showEdges: kShowWires,
      hitRadius: 1.0,
      onFrame: (elapsed, delta, transform) {
        transform.position.set(-4, 0, 0);
        final t = delta.inMicroseconds / 1e6;
        transform.rotation.y += t;
      },
    );
  }
}

class _IcosahedronShape extends StatelessWidget {
  const _IcosahedronShape();
  @override
  Widget build(BuildContext context) {
    return Fiber3DMesh(
      geometry: Fiber3DIcosahedron(radius: 1.0, detail: 0),
      material: const Fiber3DStandardMaterial(
        color: 0x33cc66,
        roughness: 0.5,
        metalness: 0.2,
        flatShading: true,
        wireframe: false,
      ),
      showEdges: kShowWires,
      hitRadius: 1.0,
      onFrame: (elapsed, delta, transform) {
        transform.position.set(-2, 0, 0);
        final t = delta.inMicroseconds / 1e6;
        transform.rotation.y += t;
      },
    );
  }
}

class _DodecahedronShape extends StatelessWidget {
  const _DodecahedronShape();
  @override
  Widget build(BuildContext context) {
    return Fiber3DMesh(
      geometry: Fiber3DDodecahedron(radius: 1.0, detail: 0),
      material: const Fiber3DStandardMaterial(
        color: 0xcc33aa,
        roughness: 0.5,
        metalness: 0.2,
        flatShading: true,
        wireframe: false,
      ),
      showEdges: kShowWires,
      hitRadius: 1.0,
      onFrame: (elapsed, delta, transform) {
        transform.position.set(0, 0, 0);
        final t = delta.inMicroseconds / 1e6;
        transform.rotation.y += t;
      },
    );
  }
}

class _CircleShape extends StatelessWidget {
  const _CircleShape();
  @override
  Widget build(BuildContext context) {
    return Fiber3DMesh(
      geometry: Fiber3DCircle(radius: 1.0, segments: 32),
      material: const Fiber3DStandardMaterial(
        color: 0x3399ff,
        roughness: 0.5,
        metalness: 0.2,
        flatShading: true,
        wireframe: false,
      ),
      showEdges: kShowWires,
      hitRadius: 1.0,
      onFrame: (elapsed, delta, transform) {
        transform.position.set(2, 0, 0);
        final t = delta.inMicroseconds / 1e6;
        transform.rotation.y += t;
      },
    );
  }
}

class _LatheShape extends StatelessWidget {
  const _LatheShape();
  @override
  Widget build(BuildContext context) {
    return Fiber3DMesh(
      geometry: Fiber3DLathe(
        points: const [
          [0.0, -0.9],
          [0.6, -0.6],
          [0.75, 0.0],
          [0.55, 0.6],
          [0.0, 0.9],
        ],
        segments: 24,
      ),
      material: const Fiber3DStandardMaterial(
        color: 0xffcc33,
        roughness: 0.5,
        metalness: 0.2,
        flatShading: true,
        wireframe: false,
      ),
      showEdges: kShowWires,
      hitRadius: 1.2,
      onFrame: (elapsed, delta, transform) {
        transform.position.set(4.5, 0, 0);
        final t = delta.inMicroseconds / 1e6;
        transform.rotation.y += t;
      },
    );
  }
}