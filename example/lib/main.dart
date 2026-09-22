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
import 'package:flutter_fiber/src/geometry/fiber3d_capsule.dart';
import 'package:flutter_fiber/src/geometry/fiber3d_circle.dart';
import 'package:flutter_fiber/src/geometry/fiber3d_cone.dart';
import 'package:flutter_fiber/src/geometry/fiber3d_cylinder.dart';
import 'package:flutter_fiber/src/geometry/fiber3d_dodecahedron.dart';
import 'package:flutter_fiber/src/geometry/fiber3d_icosahedron.dart';
import 'package:flutter_fiber/src/geometry/fiber3d_lathe.dart';
import 'package:flutter_fiber/src/geometry/fiber3d_plane.dart';
import 'package:flutter_fiber/src/geometry/fiber3d_ring.dart';
import 'package:flutter_fiber/src/geometry/fiber3d_sphere.dart';
import 'package:flutter_fiber/src/geometry/fiber3d_torus.dart';
import 'package:flutter_fiber/src/geometry/fiber3d_torus_knot.dart';
import 'package:flutter_fiber/src/geometry/fiber3d_octahedron.dart';
import 'package:flutter_fiber/src/geometry/fiber3d_tetrahedron.dart';
import 'package:flutter_fiber/src/geometry/fiber3d_star.dart';
import 'package:flutter_fiber/src/geometry/fiber3d_wedge.dart';
import 'package:flutter_fiber/src/geometry/fiber3d_spring.dart';
import 'package:flutter_fiber/src/geometry/fiber3d_chamfered_box.dart';
import 'package:flutter_fiber/src/geometry/fiber3d_arrow.dart';

void main() {
  runApp(const FiberShapeGallery());
}

/// One entry in the gallery: a name to display and a factory that builds
/// the geometry fresh each time it's selected (so switching shapes never
/// reuses stale geometry data).
class _ShapeEntry {
  final String name;
  final dynamic Function() build;
  const _ShapeEntry(this.name, this.build);
}

final List<_ShapeEntry> _shapes = [
  _ShapeEntry('Box', () => Fiber3DBox(width: 1.4, height: 1.4, depth: 1.4)),
  _ShapeEntry('Capsule', () => Fiber3DCapsule(radius: 0.6, height: 1.2)), 
  _ShapeEntry('Circle', () => Fiber3DCircle(radius: 1.2, segments: 32)),
  _ShapeEntry('Cone', () => Fiber3DCone(radius: 1.0, height: 1.8, radialSegments: 32)),
  _ShapeEntry('Cylinder', () => Fiber3DCylinder(radiusTop: 0.8, radiusBottom: 0.8, height: 1.8)),
  _ShapeEntry('Dodecahedron', () => Fiber3DDodecahedron(radius: 1.1)),
  _ShapeEntry('Icosahedron', () => Fiber3DIcosahedron(radius: 1.2)),
  _ShapeEntry(
    'Lathe (basket)',
    () => Fiber3DLathe(
      points: const [
        [0.0, -0.9],
        [0.5, -0.85],
        [0.85, -0.5],
        [0.95, 0.0],
        [0.85, 0.5],
        [0.5, 0.85],
      ],
      segments: 24,
    ),
  ),
  _ShapeEntry('Plane', () => Fiber3DPlane(width: 2, height: 2)),
  _ShapeEntry('Ring', () => Fiber3DRing(innerRadius: 0.5, outerRadius: 1.2)),
  _ShapeEntry('Sphere', () => Fiber3DSphere(radius: 1.2)),
  _ShapeEntry('Torus (donut)', () => Fiber3DTorus(radius: 1.0, tube: 0.4)),
  _ShapeEntry('TorusKnot', () => Fiber3DTorusKnot(radius: 1.0, tube: 0.3)),
  _ShapeEntry('Octahedron', () => Fiber3DOctahedron(radius: 1.2)),
  _ShapeEntry('Tetrahedron', () => Fiber3DTetrahedron(radius: 1.2)),
  _ShapeEntry('Star', () => Fiber3DStar(outerRadius: 1.2, innerRadius: 0.5, points: 5, depth: 0.3)),
  _ShapeEntry('Wedge (ramp)', () => Fiber3DWedge(width: 1.5, height: 1.0, depth: 1.5)),
  _ShapeEntry('Spring', () => Fiber3DSpring(radius: 0.8, tubeRadius: 0.15, turns: 4, pitch: 0.5)),
  _ShapeEntry('Chamfered Box', () => Fiber3DChamferedBox(width: 1.4, height: 1.4, depth: 1.4, chamferAmount: 0.4)),
  _ShapeEntry('Arrow', () => null),

];

class FiberShapeGallery extends StatefulWidget {
  const FiberShapeGallery({super.key});

  @override
  State<FiberShapeGallery> createState() => _FiberShapeGalleryState();
}

class _FiberShapeGalleryState extends State<FiberShapeGallery> {
  int _index = 0;
  bool _showWires = false;
  bool _flatShading = true;

  void _next() => setState(() => _index = (_index + 1) % _shapes.length);
  void _prev() =>
      setState(() => _index = (_index - 1 + _shapes.length) % _shapes.length);
  void _toggleWires() => setState(() => _showWires = !_showWires);
  void _toggleFlatShading() => setState(() => _flatShading = !_flatShading);
  @override
  Widget build(BuildContext context) {
    final entry = _shapes[_index];

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: Text('flutter_fiber gallery: ${entry.name} '
              '(${_index + 1}/${_shapes.length})'),
          backgroundColor: const Color(0xFF828282),
        ),
        body: Fiber3DCanvas(
          backgroundColor: 0x828282,
          camera: Fiber3DCamera(
            position: const Fiber3DVector3(0, 0, 5),
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
          // Keying by index forces a fresh Fiber3DMesh (and fresh
          // geometry) each time the shape changes, rather than reusing
          // the old mesh's registered buffers.

          children: [
               _GalleryShape(
              key: ValueKey(_index),
              entry: entry,
              showWires: _showWires,
              flatShading: _flatShading,
            ),
          ],
          ),
                  bottomNavigationBar: BottomAppBar(
          color: const Color(0xFF828282),
          padding: EdgeInsets.zero,
          height: 140,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
               Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _prev,
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Prev'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _next,
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('Next'),
                      ),
                    ),
                  ],
                ),
               const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _toggleWires,
                        icon: Icon(_showWires ? Icons.grid_off : Icons.grid_on),
                        label: Text(_showWires ? 'Wires: On' : 'Wires: Off'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _toggleFlatShading,
                        icon: Icon(_flatShading ? Icons.diamond : Icons.circle),
                        label: Text(_flatShading ? 'Flat' : 'Smooth'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

      ),
    );
  }
}

class _GalleryShape extends StatelessWidget {
  final _ShapeEntry entry;
  final bool showWires;
  final bool flatShading;
  const _GalleryShape({
    super.key,
    required this.entry,
    required this.showWires,
    required this.flatShading,
  });

  @override
  Widget build(BuildContext context) {
if (entry.name == 'Arrow') {
  final pinkMaterial = Fiber3DStandardMaterial(
    color: 0xCC2952,
    roughness: 0.5,
    metalness: 0.2,
    flatShading: flatShading,
  );
  return Fiber3DGroup(
    onFrame: (elapsed, delta, transform) {
      final t = delta.inMicroseconds / 1e6;
      transform.rotation.y += t;
      transform.rotation.x += t * 0.4;
    },
    children: [
      Fiber3DArrow(
        length: 2.0,
        shaftMaterial: pinkMaterial,
        headMaterial: pinkMaterial,
      ).build(context),
    ],
  );
}
    return Fiber3DMesh(
      geometry: entry.build(),
      material: Fiber3DStandardMaterial(
        color: 0xCC2952,
        roughness: 0.5,
        metalness: 0.2,
        flatShading: flatShading,
        wireframe: false,
      ),
      showEdges: showWires,
      hitRadius: 1.5,
      onFrame: (elapsed, delta, transform) {
        final t = delta.inMicroseconds / 1e6;
        transform.rotation.y += t;
        transform.rotation.x += t * 0.4;
      },
    );
  }
}