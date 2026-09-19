## 0.1.2

Initial release.

* Procedural geometry: box, capsule, circle, cone, cylinder, dodecahedron, icosahedron, lathe, plane, polyhedron, ring, sphere, torus, torus knot.
* PBR (Cook-Torrance/GGX) lighting with ambient and point lights, plus a Tier 1 fake-environment (sky/ground) light for softer, non-pure-black shadow sides.
* `Fiber3DGroup` — parent/child transform hierarchy for composing multiple meshes into one rigid or independently-animated object.
* Flat and smooth shading, wireframe, and a shaded-fill-plus-edge-overlay mode (`showEdges`).
* Per-frame animation hooks (`onFrame`) on both meshes and groups.
* Orbit camera controls (drag to orbit, pinch to zoom) and opt-in per-mesh pinch-to-scale with configurable min/max clamping.
* Full lifecycle management: pauses rendering when off-screen or backgrounded, stops the render loop when idle, and releases all GPU resources on dispose.