## 0.2.0

A large feature release. It contains breaking changes, listed first.

### Breaking changes

* `Fiber3DCanvas` no longer has `skyColor` / `groundColor`. Use the new `Fiber3DHemisphereLight` in `lights` instead.
* `Fiber3DStandardMaterial`'s constructor is no longer `const` (it now holds texture references). Remove `const` in front of it.
* The standard material's shader was rewritten as a faithful port of three.js's physical material. Lighting is now physically based and uses an environment map, so existing scenes will look different. Re-tune light intensities and roughness/metalness values.

### Added

* **Materials:** `Fiber3DLambertMaterial`, `Fiber3DPhongMaterial`, `Fiber3DToonMaterial`, `Fiber3DMatcapMaterial`, and `Fiber3DBasicMaterial` alongside `Fiber3DStandardMaterial`.
* **Standard material features:** `map`, `roughnessMap`, `metalnessMap`, `emissive` / `emissiveIntensity`, `envMapIntensity`, `clearcoat` / `clearcoatRoughness`, and real alpha blending through `opacity` + `transparent`.
* **Textures:** `Fiber3DTexture` (image bytes or raw pixels), `Fiber3DTextTexture.render` (text-in-shape), and `Fiber3DWidgetTexture` (any live Flutter widget, such as a Lottie animation, captured to a texture).
* **Vertex colors:** a settable `colors` list on every geometry.
* **Environment reflections:** a prefiltered environment cube map generated from a radiance function; built-in `Fiber3DProceduralSky` and `Fiber3DCheckerboardSky`; `envMapRadiance`, `envMapSize` and `envMapSamples` on `Fiber3DCanvas`.
* **Rendering controls:** `toneMapping` (`Fiber3DToneMapping`: none, linear, reinhard, cineon, acesFilmic, agx, neutral, custom) and `toneMappingExposure`; sRGB `colorManagement`.
* **Lights:** `Fiber3DHemisphereLight`.
* **Geometry:** `Fiber3DPrism`, `Fiber3DChamferedBox`, `Fiber3DWedge`, `Fiber3DSpring`, `Fiber3DStar` (with optional `depth` for a solid star), `Fiber3DOctahedron`, `Fiber3DTetrahedron`, and the `Fiber3DArrow` widget.
* **glTF / GLB loading:** `Fiber3DGltfLoader.loadGlb`, `Fiber3DGltfLoader.loadEmbeddedGltf`, and the `Fiber3DGltfModel` widget, with node hierarchy, PBR metallic-roughness materials, textures and vertex colors.
* A much more detailed README covering every class, parameter and default.

### Fixed

* GPU resources (UV, color and texture buffers, fallback and environment textures) are now all released on dispose.
* glTF texture indices stay aligned when a texture entry has no image source.

### Known limitations

* One material per mesh; no per-face materials.
* Geometry and glTF primitives are limited to 65,535 vertices.
* No depth-sorted transparency; overlapping transparent meshes can show sorting artifacts.
* Textures use UV set 0, clamp-to-edge wrapping and no mipmaps; only the standard material accepts textures.
* No normal, emissive or occlusion maps; no directional or spot lights; no shadows.
* glTF: external buffers/images, animations and skinning are not supported. Only the clearcoat and emissive-strength `KHR_materials_*` extensions are read; the rest are ignored.

## 0.1.2

* Procedural geometry: box, capsule, circle, cone, cylinder, dodecahedron, icosahedron, lathe, plane, polyhedron, ring, sphere, torus, torus knot.
* PBR (Cook-Torrance/GGX) lighting with ambient and point lights, plus a fake-environment (sky/ground) light for softer, non-pure-black shadow sides.
* `Fiber3DGroup`: parent/child transform hierarchy for composing multiple meshes into one rigid or independently animated object.
* Flat and smooth shading, wireframe, and a shaded-fill-plus-edge-overlay mode (`showEdges`).
* Per-frame animation hooks (`onFrame`) on both meshes and groups.
* Orbit camera controls (drag to orbit, pinch to zoom) and opt-in per-mesh pinch-to-scale with configurable min/max clamping.
* Full lifecycle management: pauses rendering when off-screen or backgrounded, stops the render loop when idle, and releases all GPU resources on dispose.