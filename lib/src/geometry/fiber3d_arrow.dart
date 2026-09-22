import 'package:flutter/widgets.dart';
import '../core/fiber3d_group.dart';
import '../core/fiber3d_mesh.dart';
import '../core/fiber3d_vector3.dart';
import 'fiber3d_cylinder.dart';
import 'fiber3d_cone.dart';
import '../material/fiber3d_standard_material.dart';

/// A pre-composed arrow: a cylindrical shaft with a conical head, packaged
/// as a single reusable widget instead of requiring the caller to
/// manually group a Cylinder + Cone every time (as done ad hoc in the
/// toy train demo). Points along +Y by default, base at the origin,
/// tip at `length`.
///
/// Not a standalone geometry class  it's a thin Fiber3DGroup wrapper,
/// since a shaft+head arrow is two independently-shaped parts, not one
/// continuous surface.
class Fiber3DArrow extends StatelessWidget {
  /// Total length from the shaft's base to the head's tip.
  final double length;

  /// Fraction of `length` occupied by the head (cone). The rest is
  /// the shaft (cylinder).
  final double headLengthRatio;

  /// Shaft radius, as a fraction of the head's base radius controls
  /// how much thinner the shaft looks compared to the arrowhead.
  final double shaftRadiusRatio;

  /// Head base radius, in absolute units.
  final double headRadius;

  final int radialSegments;
  final Fiber3DStandardMaterial? shaftMaterial;
  final Fiber3DStandardMaterial? headMaterial;

  const Fiber3DArrow({
    super.key,
    this.length = 2.0,
    this.headLengthRatio = 0.25,
    this.shaftRadiusRatio = 0.35,
    this.headRadius = 0.2,
    this.radialSegments = 16,
    this.shaftMaterial,
    this.headMaterial,
  });

  @override
  Widget build(BuildContext context) {
    final headLength = length * headLengthRatio;
    final shaftLength = length - headLength;
    final shaftRadius = headRadius * shaftRadiusRatio;

    final defaultMaterial = const Fiber3DStandardMaterial(
      color: 0x999999,
      roughness: 0.5,
      metalness: 0.2,
    );

    return Fiber3DGroup(
      children: [
        _ArrowPart(
          geometry: Fiber3DCylinder(
            radiusTop: shaftRadius,
            radiusBottom: shaftRadius,
            height: shaftLength,
            radialSegments: radialSegments,
          ),
          material: shaftMaterial ?? defaultMaterial,
          // Shaft's own center sits at half its length from the base.
          position: Fiber3DVector3(0, shaftLength / 2, 0),
        ),
        _ArrowPart(
          geometry: Fiber3DCone(
            radius: headRadius,
            height: headLength,
            radialSegments: radialSegments,
          ),
          material: headMaterial ?? defaultMaterial,
          // Head sits on top of the shaft; its own center is half its
          // height above the shaft's top.
          position: Fiber3DVector3(0, shaftLength + headLength / 2, 0),
        ),
      ],
    );
  }
}

/// Internal helper: a mesh that sets its own fixed local position once,
/// same pattern used for the joint spheres in the earlier limb/group
/// demos (Fiber3DMesh has no `position:` constructor param).
class _ArrowPart extends StatefulWidget {
  final dynamic geometry;
  final Fiber3DStandardMaterial material;
  final Fiber3DVector3 position;

  const _ArrowPart({
    required this.geometry,
    required this.material,
    required this.position,
  });

  @override
  State<_ArrowPart> createState() => _ArrowPartState();
}

class _ArrowPartState extends State<_ArrowPart> {
  bool _placed = false;

  @override
  Widget build(BuildContext context) {
    return Fiber3DMesh(
      geometry: widget.geometry,
      material: widget.material,
      onFrame: (elapsed, delta, transform) {
        if (!_placed) {
          transform.position.set(
              widget.position.x, widget.position.y, widget.position.z);
          _placed = true;
        }
      },
    );
  }
}