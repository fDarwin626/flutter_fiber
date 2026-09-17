import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_fiber/src/core/fiber3d_matrix4.dart';
import 'dart:io';
import 'package:flutter_gl_flutterflow/flutter_gl.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../camera/fiber3d_camera.dart';
import '../camera/fiber3d_orbit_controls.dart';
import '../material/fiber3d_pbr_shader.dart';
import 'fiber3d_vector3.dart';
import 'dart:math';
import '../material/fiber3d_edge_shader.dart';

/// Signature for a per-frame callback registered with [Fiber3DCanvas].
///
/// [elapsed] is the total time since the canvas's ticker started.
/// [delta] is the time since the previous frame.
typedef Fiber3DFrameCallback = void Function(Duration elapsed, Duration delta);

/// A mesh registered for hit-testing (tap/pan). Coarse bounding-sphere
class _Hittable {
  final Fiber3DVector3 Function() getPosition;
  final double radius;
  final VoidCallback? onTap;
  final void Function(Offset delta)? onPan;
  final VoidCallback? onPinchStart;
  final void Function(double scale)? onPinch;

  _Hittable({
    required this.getPosition,
    required this.radius,
    this.onTap,
    this.onPan,
    this.onPinchStart,
    this.onPinch,
  });
}

class Fiber3DCanvas extends StatefulWidget {
  final List<Widget> children;
  final Fiber3DCamera camera;
  final bool orbitEnabled;

  /// Scene lights (Fiber3DAmbientLight / Fiber3DPointLight instances).
  /// Lights are plain data with no widget lifecycle needs (no gestures,
  /// no per frame registration), so unlike Fiber3DMesh they're passed
  /// directly here rather than nested in [children] see the team
  /// discussion: this was a deliberate deviation from the PRD's literal
  /// nested children example, justified by what lights actually are.
  final List<dynamic> lights;

  /// Background color as a packed 0xRRGGBB hex int, same convention as
  /// your Fiber3D material/light colors (e.g. 0x828282). Defaults to
  /// white to match prior behavior.
  final int backgroundColor;

  /// Tier 1 fake environment lighting (HemisphereLight-style) — sky and
  /// ground colors blended by surface normal.y. Defaults approximate a
  /// neutral daylight room; pass 0x000000/0x000000 to disable entirely.
  final int skyColor;
  final int groundColor;

  Fiber3DCanvas({
    super.key,
    this.children = const [],
    this.lights = const [],
    Fiber3DCamera? camera,
    this.orbitEnabled = false,
    this.backgroundColor = 0xFFFFFF,
    this.skyColor = 0x87A6C4,
    this.groundColor = 0x3B3A35,
  }) : camera = camera ?? Fiber3DCamera();

  double get skyColorR => ((skyColor >> 16) & 0xFF) / 255.0;
  double get skyColorG => ((skyColor >> 8) & 0xFF) / 255.0;
  double get skyColorB => (skyColor & 0xFF) / 255.0;
  double get groundColorR => ((groundColor >> 16) & 0xFF) / 255.0;
  double get groundColorG => ((groundColor >> 8) & 0xFF) / 255.0;
  double get groundColorB => (groundColor & 0xFF) / 255.0;
  @override
  State<Fiber3DCanvas> createState() => Fiber3DCanvasState();
}

class Fiber3DCanvasState extends State<Fiber3DCanvas>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final Set<Fiber3DFrameCallback> _frameCallbacks = {};
  final Set<_Hittable> _hittables = {};

  /// Meshes registered for rendering. Actual per-mesh draw logic (buffer
  /// building, uniform upload) is Section 7d work this registry just
  /// tracks which meshes currently exist, same lifecycle-safe
  /// register/unregister pattern as everything else.
  final Set<dynamic> _meshes = {};

  VoidCallback registerMesh(dynamic meshState) {
    _meshes.add(meshState);
    return () => _meshes.remove(meshState);
  }

  // --- GL context ownership (moved here from one-off example code,

  FlutterGlPlugin? _glPlugin;
  num _dpr = 1.0;
  Size? _glSize;
  bool _glInitStarted = false;
  bool _glReady = false;

  dynamic _defaultFramebuffer;
  dynamic _defaultFramebufferTexture;
  dynamic _sourceTexture;
  dynamic _defaultDepthRenderbuffer;

  bool get isGlReady => _glReady;

  Future<void> _initGl(Size size, double dpr) async {
    if (_glInitStarted) return;
    _glInitStarted = true;

    _glSize = size;
    _dpr = dpr;

    _glPlugin = FlutterGlPlugin();

    final options = <String, dynamic>{
      "antialias": true,
      "alpha": false,
      "width": size.width.toInt(),
      "height": size.height.toInt(),
      "dpr": dpr,
    };

    await _glPlugin!.initialize(options: options);

    if (!mounted) return;
    setState(() {});

    // Same 100ms wait the reference example uses — gives the platform
    // texture/view time to settle before touching the GL context.
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;

    if (!kIsWeb) {
      await _glPlugin!.prepareContext();
      _setupDefaultFBO();
      _sourceTexture = _defaultFramebufferTexture;
    }

    _compileShader();
    _compileEdgeShader();

    if (!mounted) return;
    setState(() {
      _glReady = true;
    });
  }
  // --- Shader compilation/caching (compiled once per canvas, reused by
  // every mesh not recompiled per draw call) ---

  dynamic glProgram;

  int aPositionLocation = -1;
  int aNormalLocation = -1;

  int uModelMatrixLocation = -1;
  int uViewMatrixLocation = -1;
  int uProjectionMatrixLocation = -1;
  int uCameraPositionLocation = -1;

  int uBaseColorLocation = -1;
  int uRoughnessLocation = -1;
  int uMetalnessLocation = -1;
  int uEmissiveLocation = -1;
  int uEmissiveIntensityLocation = -1;
  int uAmbientLightColorLocation = -1;
  int uSkyColorLocation = -1;
  int uGroundColorLocation = -1;
  int uPointLightCountLocation = -1;
  int uPointLightPositionLocation = -1;
  int uPointLightColorLocation = -1;
  int uPointLightDistanceLocation = -1;
  int uPointLightDecayLocation = -1;

  String _glslVersion() {
    if (kIsWeb) return "300 es";
    if (Platform.isMacOS || Platform.isWindows) return "150";
    return "300 es";
  }

  void _compileShader() {
    final gl = _glPlugin!.gl;
    final version = _glslVersion();

    final vs = _makeShader(
      gl,
      Fiber3DPbrShader.vertex(version),
      gl.VERTEX_SHADER,
    );
    final fs = _makeShader(
      gl,
      Fiber3DPbrShader.fragment(version),
      gl.FRAGMENT_SHADER,
    );

    glProgram = gl.createProgram();
    gl.attachShader(glProgram, vs);
    gl.attachShader(glProgram, fs);
    gl.linkProgram(glProgram);

    final linked = gl.getProgramParameter(glProgram, gl.LINK_STATUS);
    if (linked == false || linked == 0) {
      // ignore: avoid_print
      print("Fiber3DCanvas: shader program failed to link");
      return;
    }

    gl.useProgram(glProgram);

    aPositionLocation = gl.getAttribLocation(glProgram, 'a_Position');
    aNormalLocation = gl.getAttribLocation(glProgram, 'a_Normal');

    uModelMatrixLocation = gl.getUniformLocation(glProgram, 'u_ModelMatrix');
    uViewMatrixLocation = gl.getUniformLocation(glProgram, 'u_ViewMatrix');
    uProjectionMatrixLocation = gl.getUniformLocation(
      glProgram,
      'u_ProjectionMatrix',
    );
    uCameraPositionLocation = gl.getUniformLocation(
      glProgram,
      'u_CameraPosition',
    );

    uBaseColorLocation = gl.getUniformLocation(glProgram, 'u_BaseColor');
    uRoughnessLocation = gl.getUniformLocation(glProgram, 'u_Roughness');
    uMetalnessLocation = gl.getUniformLocation(glProgram, 'u_Metalness');
    uEmissiveLocation = gl.getUniformLocation(glProgram, 'u_Emissive');
    uEmissiveIntensityLocation = gl.getUniformLocation(
      glProgram,
      'u_EmissiveIntensity',
    );

    uAmbientLightColorLocation = gl.getUniformLocation(
      glProgram,
      'u_AmbientLightColor',
    );
    uSkyColorLocation = gl.getUniformLocation(glProgram, 'u_SkyColor');
    uGroundColorLocation = gl.getUniformLocation(glProgram, 'u_GroundColor');
    uPointLightCountLocation = gl.getUniformLocation(
      glProgram,
      'u_PointLightCount',
    );
    uPointLightPositionLocation = gl.getUniformLocation(
      glProgram,
      'u_PointLightPosition',
    );
    uPointLightColorLocation = gl.getUniformLocation(
      glProgram,
      'u_PointLightColor',
    );
    uPointLightDistanceLocation = gl.getUniformLocation(
      glProgram,
      'u_PointLightDistance',
    );
    uPointLightDecayLocation = gl.getUniformLocation(
      glProgram,
      'u_PointLightDecay',
    );
  }

  dynamic edgeGlProgram;
  int aEdgePositionLocation = -1;
  int uEdgeModelMatrixLocation = -1;
  int uEdgeViewMatrixLocation = -1;
  int uEdgeProjectionMatrixLocation = -1;
  int uEdgeColorLocation = -1;

  void _compileEdgeShader() {
    final gl = _glPlugin!.gl;
    final version = _glslVersion();

    final vs = _makeShader(
      gl,
      Fiber3DEdgeShader.vertex(version),
      gl.VERTEX_SHADER,
    );
    final fs = _makeShader(
      gl,
      Fiber3DEdgeShader.fragment(version),
      gl.FRAGMENT_SHADER,
    );

    edgeGlProgram = gl.createProgram();
    gl.attachShader(edgeGlProgram, vs);
    gl.attachShader(edgeGlProgram, fs);
    gl.linkProgram(edgeGlProgram);

    final linked = gl.getProgramParameter(edgeGlProgram, gl.LINK_STATUS);
    if (linked == false || linked == 0) {
      // ignore: avoid_print
      print("Fiber3DCanvas: edge shader program failed to link");
      return;
    }

    aEdgePositionLocation = gl.getAttribLocation(edgeGlProgram, 'a_Position');
    uEdgeModelMatrixLocation = gl.getUniformLocation(
      edgeGlProgram,
      'u_ModelMatrix',
    );
    uEdgeViewMatrixLocation = gl.getUniformLocation(
      edgeGlProgram,
      'u_ViewMatrix',
    );
    uEdgeProjectionMatrixLocation = gl.getUniformLocation(
      edgeGlProgram,
      'u_ProjectionMatrix',
    );
    uEdgeColorLocation = gl.getUniformLocation(edgeGlProgram, 'u_EdgeColor');
  }

  dynamic _makeShader(dynamic gl, String src, dynamic type) {
    final shader = gl.createShader(type);
    gl.shaderSource(shader, src);
    gl.compileShader(shader);

    final compiled = gl.getShaderParameter(shader, gl.COMPILE_STATUS);
    if (compiled == 0 || compiled == false) {
      // ignore: avoid_print
      print(
        "Fiber3DCanvas: shader compile error: ${gl.getShaderInfoLog(shader)}",
      );
      return null;
    }
    return shader;
  }

  void _setupDefaultFBO() {
    final gl = _glPlugin!.gl;
    final glWidth = (_glSize!.width * _dpr).toInt();
    final glHeight = (_glSize!.height * _dpr).toInt();

    _defaultFramebuffer = gl.createFramebuffer();
    _defaultFramebufferTexture = gl.createTexture();
    gl.activeTexture(gl.TEXTURE0);

    gl.bindTexture(gl.TEXTURE_2D, _defaultFramebufferTexture);
    gl.texImage2D(
      gl.TEXTURE_2D,
      0,
      gl.RGBA,
      glWidth,
      glHeight,
      0,
      gl.RGBA,
      gl.UNSIGNED_BYTE,
      null,
    );
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);

    gl.bindFramebuffer(gl.FRAMEBUFFER, _defaultFramebuffer);
    gl.framebufferTexture2D(
      gl.FRAMEBUFFER,
      gl.COLOR_ATTACHMENT0,
      gl.TEXTURE_2D,
      _defaultFramebufferTexture,
      0,
    );

    // Depth renderbuffer — without it, DEPTH_TEST has nothing to test or
    // write against, so triangles draw in submission order regardless of
    // actual depth.
    _defaultDepthRenderbuffer = gl.createRenderbuffer();
    gl.bindRenderbuffer(gl.RENDERBUFFER, _defaultDepthRenderbuffer);
    gl.renderbufferStorage(
      gl.RENDERBUFFER,
      gl.DEPTH_COMPONENT16,
      glWidth,
      glHeight,
    );
    gl.framebufferRenderbuffer(
      gl.FRAMEBUFFER,
      gl.DEPTH_ATTACHMENT,
      gl.RENDERBUFFER,
      _defaultDepthRenderbuffer,
    );
  }

  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;

  /// ------ Lifecycle: visibility + app-state pause, idel frame stop -----
  bool _canvasVisible = true;
  bool _appActive = true;
  final Key _visibilityKey = UniqueKey();

  late Fiber3DCamera _camera;
  Fiber3DOrbitControls? _orbitControls;
  late Fiber3DMatrix4 _lastProjection = Fiber3DMatrix4();
  bool _orbiting = false;
  bool _gestureActive = false;

  /// The camera currently in effect — reflects live orbit/zoom state when
  /// orbitEnabled is true, otherwise just widget.camera.
  Fiber3DCamera get camera => _camera;

  double get _bgR => ((widget.backgroundColor >> 16) & 0xFF) / 255.0;
  double get _bgG => ((widget.backgroundColor >> 8) & 0xFF) / 255.0;
  double get _bgB => (widget.backgroundColor & 0xFF) / 255.0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker = createTicker(_onTick)..start();
    _camera = widget.camera;
    if (widget.orbitEnabled) {
      _orbitControls = Fiber3DOrbitControls(camera: widget.camera);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final active = state == AppLifecycleState.resumed;
    if (active != _appActive) {
      _appActive = active;
      if (active) _wakeTicker();
    }
  }

  void _onTick(Duration elapsed) {
    final delta = elapsed - _lastElapsed;
    _lastElapsed = elapsed;

    // Snapshot to avoid concurrent-modification if a callback registers
    // or unregisters another callback mid-tick.
    for (final callback in List<Fiber3DFrameCallback>.from(_frameCallbacks)) {
      callback(elapsed, delta);
    }

    if (_glReady) _renderFrame();

    // Idle-frame stop: once this frame is drawn, fully stop the ticker
    // (not just throttle) if nothing needs continuous updates — no
    // registered onFrame callbacks and no gesture in progress — or the
    // canvas is off-screen/backgrounded. Always keep ticking through
    // initial GL setup so the first frame is guaranteed to render
    // regardless of when meshes happen to register.
    if (!_shouldKeepTicking()) {
      _ticker.stop();
    }
  }

  bool _shouldKeepTicking() {
    if (!_canvasVisible || !_appActive) return false;
    if (!_glReady) return true;
    return _frameCallbacks.isNotEmpty || _gestureActive;
  }

  /// Restarts the ticker if it was stopped. Ticker.start() resets its own
  /// elapsed-time clock to zero, so _lastElapsed is reset to match —
  /// otherwise the first delta after waking would read as a large
  /// negative number (an apparent huge time jump backwards).
  void _wakeTicker() {
    if (!_ticker.isActive) {
      _lastElapsed = Duration.zero;
      _ticker.start();
    }
  }

  // --- Per-mesh GPU buffer cache: built once per mesh, on first sight,
  // not rebuilt every frame. Keyed by the Fiber3DMesh's own State object
  // (stable identity across rebuilds while the widget stays mounted). ---
  final Map<dynamic, _MeshBuffers> _meshBufferCache = {};

  _MeshBuffers? _buffersFor(dynamic meshState) {
    final cached = _meshBufferCache[meshState];
    if (cached != null) return cached;

    final gl = _glPlugin!.gl;
    final geometry = meshState.widget.geometry;

    List<double>? positions;
    List<double>? normals;
    List<int>? indices;

    // Pattern-match the concrete geometry type — see the note on
    // Fiber3DMesh for why geometry/material are typed dynamic.
    if (geometry.runtimeType.toString().startsWith('Fiber3D')) {
      positions = geometry.positions as List<double>;
      normals = geometry.normals as List<double>;
      indices = geometry.indices as List<int>;
    }

    if (positions == null || normals == null || indices == null) return null;

    final material = meshState.widget.material;

    // Flat shading: one normal per triangle instead of interpolated
    // shared vertex normals, so adjacent triangles show a hard lighting
    // discontinuity at their shared edge (the faceted look). Requires
    // mesh's GPU buffers.
    if (material.flatShading == true) {
      final flatPositions = <double>[];
      final flatNormals = <double>[];
      final flatIndices = <int>[];

      for (var i = 0; i + 2 < indices.length; i += 3) {
        final ia = indices[i], ib = indices[i + 1], ic = indices[i + 2];

        final ax = positions[ia * 3],
            ay = positions[ia * 3 + 1],
            az = positions[ia * 3 + 2];
        final bx = positions[ib * 3],
            by = positions[ib * 3 + 1],
            bz = positions[ib * 3 + 2];
        final cx = positions[ic * 3],
            cy = positions[ic * 3 + 1],
            cz = positions[ic * 3 + 2];

        final e1x = bx - ax, e1y = by - ay, e1z = bz - az;
        final e2x = cx - ax, e2y = cy - ay, e2z = cz - az;

        var nx = e1y * e2z - e1z * e2y;
        var ny = e1z * e2x - e1x * e2z;
        var nz = e1x * e2y - e1y * e2x;
        final len = sqrt(nx * nx + ny * ny + nz * nz);
        if (len > 0) {
          nx /= len;
          ny /= len;
          nz /= len;
        }

        final base = flatPositions.length ~/ 3;
        flatPositions.addAll([ax, ay, az, bx, by, bz, cx, cy, cz]);
        flatNormals.addAll([nx, ny, nz, nx, ny, nz, nx, ny, nz]);
        flatIndices.addAll([base, base + 1, base + 2]);
      }

      positions = flatPositions;
      normals = flatNormals;
      indices = flatIndices;
    }

    final positionBuffer = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, positionBuffer);
    final posArray = Float32Array.fromList(positions);
    if (kIsWeb) {
      gl.bufferData(gl.ARRAY_BUFFER, posArray.length, posArray, gl.STATIC_DRAW);
    } else {
      gl.bufferData(
        gl.ARRAY_BUFFER,
        posArray.lengthInBytes,
        posArray,
        gl.STATIC_DRAW,
      );
    }

    final normalBuffer = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, normalBuffer);
    final normArray = Float32Array.fromList(normals);
    if (kIsWeb) {
      gl.bufferData(
        gl.ARRAY_BUFFER,
        normArray.length,
        normArray,
        gl.STATIC_DRAW,
      );
    } else {
      gl.bufferData(
        gl.ARRAY_BUFFER,
        normArray.lengthInBytes,
        normArray,
        gl.STATIC_DRAW,
      );
    }

    final indexBuffer = gl.createBuffer();
    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, indexBuffer);
    final idxArray = Uint16Array.fromList(indices);
    if (kIsWeb) {
      gl.bufferData(
        gl.ELEMENT_ARRAY_BUFFER,
        idxArray.length,
        idxArray,
        gl.STATIC_DRAW,
      );
    } else {
      gl.bufferData(
        gl.ELEMENT_ARRAY_BUFFER,
        idxArray.lengthInBytes,
        idxArray,
        gl.STATIC_DRAW,
      );
    }

    dynamic lineIndexBuffer;
    var lineIndexCount = 0;

    final bool wantsEdgeBuffer =
        material.wireframe == true || meshState.widget.showEdges == true;
    if (wantsEdgeBuffer) {
      final lineIndices = <int>[];
      for (var i = 0; i + 2 < indices.length; i += 3) {
        final a = indices[i], b = indices[i + 1], c = indices[i + 2];
        lineIndices.addAll([a, b, b, c, c, a]);
      }

      lineIndexBuffer = gl.createBuffer();
      gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, lineIndexBuffer);
      final lineIdxArray = Uint16Array.fromList(lineIndices);
      if (kIsWeb) {
        gl.bufferData(
          gl.ELEMENT_ARRAY_BUFFER,
          lineIdxArray.length,
          lineIdxArray,
          gl.STATIC_DRAW,
        );
      } else {
        gl.bufferData(
          gl.ELEMENT_ARRAY_BUFFER,
          lineIdxArray.lengthInBytes,
          lineIdxArray,
          gl.STATIC_DRAW,
        );
      }
      lineIndexCount = lineIndices.length;
    }

    final buffers = _MeshBuffers(
      positionBuffer: positionBuffer,
      normalBuffer: normalBuffer,
      indexBuffer: indexBuffer,
      indexCount: indices.length,
      lineIndexBuffer: lineIndexBuffer,
      lineIndexCount: lineIndexCount,
    );
    _meshBufferCache[meshState] = buffers;
    return buffers;
  }

  void _renderFrame() {
    final gl = _glPlugin!.gl;
    if (glProgram == null) return;

    final glWidth = (_glSize!.width * _dpr).toInt();
    final glHeight = (_glSize!.height * _dpr).toInt();
    gl.viewport(0, 0, glWidth, glHeight);

    gl.enable(gl.DEPTH_TEST);
    gl.clearColor(_bgR, _bgG, _bgB, 1.0);
    gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
    gl.useProgram(glProgram);

    final runtimeAspect = _glSize!.width / _glSize!.height;
    final projection = Fiber3DMatrix4();
    final top = _camera.near * tan(_camera.fov * pi / 360.0);
    final height = 2 * top;
    final width = runtimeAspect * height;
    final left = -0.5 * width;
    projection.makePerspective(
      left,
      left + width,
      top,
      top - height,
      _camera.near,
      _camera.far,
    );

    _lastProjection = projection;

    gl.uniformMatrix4fv(
      uViewMatrixLocation,
      false,
      Float32Array.fromList(_camera.viewMatrix.elements),
    );
    gl.uniformMatrix4fv(
      uProjectionMatrixLocation,
      false,
      Float32Array.fromList(projection.elements),
    );
    gl.uniform3f(
      uCameraPositionLocation,
      _camera.position.x,
      _camera.position.y,
      _camera.position.z,
    );

    // Light uniforms.
    _uploadLights(gl);

    for (final meshState in _meshes) {
      _drawMesh(gl, meshState);
    }

    gl.finish();

    if (!kIsWeb) {
      _glPlugin!.updateTexture(_sourceTexture);
    }
  }

  void _uploadLights(dynamic gl) {
    gl.uniform3f(
      uSkyColorLocation,
      widget.skyColorR,
      widget.skyColorG,
      widget.skyColorB,
    );
    gl.uniform3f(
      uGroundColorLocation,
      widget.groundColorR,
      widget.groundColorG,
      widget.groundColorB,
    );
    var ambient = const [0.0, 0.0, 0.0];
    final pointPositions = <double>[];
    final pointColors = <double>[];
    final pointDistances = <double>[];
    final pointDecays = <double>[];

    for (final light in widget.lights) {
      final typeName = light.runtimeType.toString();
      if (typeName == 'Fiber3DAmbientLight') {
        ambient = [
          light.r * light.intensity,
          light.g * light.intensity,
          light.b * light.intensity,
        ];
      } else if (typeName == 'Fiber3DPointLight' &&
          pointPositions.length < Fiber3DPbrShader.maxPointLights * 3) {
        pointPositions.addAll([
          light.position.x,
          light.position.y,
          light.position.z,
        ]);
        pointColors.addAll([
          light.r * light.intensity,
          light.g * light.intensity,
          light.b * light.intensity,
        ]);
        pointDistances.add(light.distance);
        pointDecays.add(light.decay);
      }
    }

    gl.uniform3f(
      uAmbientLightColorLocation,
      ambient[0],
      ambient[1],
      ambient[2],
    );

    final count = pointDistances.length;
    gl.uniform1i(uPointLightCountLocation, count);

    // Pad arrays to the fixed shader-side size.
    while (pointPositions.length < Fiber3DPbrShader.maxPointLights * 3) {
      pointPositions.add(0);
    }
    while (pointColors.length < Fiber3DPbrShader.maxPointLights * 3) {
      pointColors.add(0);
    }
    while (pointDistances.length < Fiber3DPbrShader.maxPointLights) {
      pointDistances.add(0);
    }
    while (pointDecays.length < Fiber3DPbrShader.maxPointLights) {
      pointDecays.add(2);
    }

    gl.uniform3fv(uPointLightPositionLocation, pointPositions);
    gl.uniform3fv(uPointLightColorLocation, pointColors);
    gl.uniform1fv(uPointLightDistanceLocation, pointDistances);
    gl.uniform1fv(uPointLightDecayLocation, pointDecays);
  }

  void _drawMesh(dynamic gl, dynamic meshState) {
    final buffers = _buffersFor(meshState);
    if (buffers == null) return;

    meshState.transform.updateWorldMatrix(updateParents: true);
    final modelMatrix = meshState.transform.matrixWorld;
    gl.uniformMatrix4fv(
      uModelMatrixLocation,
      false,
      Float32Array.fromList(modelMatrix.elements),
    );

    final material = meshState.widget.material;
    final materialType = material.runtimeType.toString();

    if (materialType == 'Fiber3DStandardMaterial') {
      gl.uniform3f(uBaseColorLocation, material.r, material.g, material.b);
      gl.uniform1f(uRoughnessLocation, material.roughness);
      gl.uniform1f(uMetalnessLocation, material.metalness);
      gl.uniform3f(
        uEmissiveLocation,
        material.emissiveR,
        material.emissiveG,
        material.emissiveB,
      );
      gl.uniform1f(uEmissiveIntensityLocation, material.emissiveIntensity);
    } else if (materialType == 'Fiber3DBasicMaterial') {
      // Basic material has no lighting response — feed it through as a
      // fully "emissive" surface so it reads as flat/unlit, same
      // conceptual behavior as three.js's MeshBasicMaterial.
      gl.uniform3f(uBaseColorLocation, 0, 0, 0);
      gl.uniform1f(uRoughnessLocation, 1.0);
      gl.uniform1f(uMetalnessLocation, 0.0);
      gl.uniform3f(uEmissiveLocation, material.r, material.g, material.b);
      gl.uniform1f(uEmissiveIntensityLocation, 1.0);
    }

    gl.bindBuffer(gl.ARRAY_BUFFER, buffers.positionBuffer);
    gl.vertexAttribPointer(aPositionLocation, 3, gl.FLOAT, false, 0, 0);
    gl.enableVertexAttribArray(aPositionLocation);

    gl.bindBuffer(gl.ARRAY_BUFFER, buffers.normalBuffer);
    gl.vertexAttribPointer(aNormalLocation, 3, gl.FLOAT, false, 0, 0);
    gl.enableVertexAttribArray(aNormalLocation);

    final wireframeOnly = material.wireframe == true;

    if (wireframeOnly && buffers.lineIndexBuffer != null) {
      gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, buffers.lineIndexBuffer);
      gl.drawElements(gl.LINES, buffers.lineIndexCount, gl.UNSIGNED_SHORT, 0);
      return;
    }

    // Standard filled draw. Polygon offset pushes the filled faces
    // slightly back in depth so the edge overlay (drawn next) can sit
    // visually in front without z-fighting — the standard technique for
    // this exact "shaded + visible wireframe" look.
    gl.enable(gl.POLYGON_OFFSET_FILL);
    gl.polygonOffset(1, 1);
    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, buffers.indexBuffer);
    gl.drawElements(gl.TRIANGLES, buffers.indexCount, gl.UNSIGNED_SHORT, 0);
    gl.disable(gl.POLYGON_OFFSET_FILL);

    if (meshState.widget.showEdges == true && buffers.lineIndexBuffer != null) {
      _drawEdgeOverlay(gl, meshState, buffers);
    }
  }

  void _drawEdgeOverlay(dynamic gl, dynamic meshState, _MeshBuffers buffers) {
    if (edgeGlProgram == null) return;

    gl.useProgram(edgeGlProgram);

    final modelMatrix = meshState.transform.matrixWorld;
    gl.uniformMatrix4fv(
      uEdgeModelMatrixLocation,
      false,
      Float32Array.fromList(modelMatrix.elements),
    );
    gl.uniformMatrix4fv(
      uEdgeViewMatrixLocation,
      false,
      Float32Array.fromList(_camera.viewMatrix.elements),
    );
    gl.uniformMatrix4fv(
      uEdgeProjectionMatrixLocation,
      false,
      Float32Array.fromList(_lastProjection.elements),
    );

    // A dark neutral edge color, matching the reference look (not pure
    // black, so edges read as structure rather than a harsh outline).
    gl.uniform3f(uEdgeColorLocation, 0.85, 0.92, 0.98);

    gl.bindBuffer(gl.ARRAY_BUFFER, buffers.positionBuffer);
    gl.vertexAttribPointer(aEdgePositionLocation, 3, gl.FLOAT, false, 0, 0);
    gl.enableVertexAttribArray(aEdgePositionLocation);

    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, buffers.lineIndexBuffer);
    gl.drawElements(gl.LINES, buffers.lineIndexCount, gl.UNSIGNED_SHORT, 0);

    gl.useProgram(glProgram);
  }

  VoidCallback registerFrameCallback(Fiber3DFrameCallback callback) {
    _frameCallbacks.add(callback);
    _wakeTicker();
    return () => _frameCallbacks.remove(callback);
  }

  VoidCallback registerHittable({
    required Fiber3DVector3 Function() getPosition,
    required double radius,
    VoidCallback? onTap,
    void Function(Offset delta)? onPan,
    VoidCallback? onPinchStart,
    void Function(double scale)? onPinch,
  }) {
    final hittable = _Hittable(
      getPosition: getPosition,
      radius: radius,
      onTap: onTap,
      onPan: onPan,
      onPinchStart: onPinchStart,
      onPinch: onPinch,
    );
    _hittables.add(hittable);
    return () => _hittables.remove(hittable);
  }

  _Hittable? _closestHitAt(Offset localPosition, Size canvasSize) {
    // Convert a screen-space tap to normalized device coordinates (NDC),
    // each in [-1, 1], with Y flipped since screen Y grows downward while
    // NDC Y grows upward — same convention three.js's setFromCamera uses.
    final ndcX = (localPosition.dx / canvasSize.width) * 2 - 1;
    final ndcY = -((localPosition.dy / canvasSize.height) * 2 - 1);

    final ray = _camera.rayFromNdc(ndcX, ndcY);

    _Hittable? closest;
    double? closestDistance;

    for (final hittable in _hittables) {
      final distance = ray.intersectSphereDistance(
        hittable.getPosition(),
        hittable.radius,
      );
      if (distance != null &&
          (closestDistance == null || distance < closestDistance)) {
        closest = hittable;
        closestDistance = distance;
      }
    }

    return closest;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _releaseGlResources();
    _ticker.dispose();
    super.dispose();
  }

  /// Releases GPU resources compiled/allocated by this canvas — mesh
  /// buffers, both shader programs, and the default framebuffer's texture
  /// and depth renderbuffer — since stopping the ticker alone doesn't free
  /// GPU memory when this widget leaves the tree.
  void _releaseGlResources() {
    final plugin = _glPlugin;
    if (plugin == null) return;
    final gl = plugin.gl;

    for (final buffers in _meshBufferCache.values) {
      gl.deleteBuffer(buffers.positionBuffer);
      gl.deleteBuffer(buffers.normalBuffer);
      gl.deleteBuffer(buffers.indexBuffer);
      if (buffers.lineIndexBuffer != null) {
        gl.deleteBuffer(buffers.lineIndexBuffer);
      }
    }
    _meshBufferCache.clear();

    if (glProgram != null) gl.deleteProgram(glProgram);
    if (edgeGlProgram != null) gl.deleteProgram(edgeGlProgram);

    if (_defaultFramebufferTexture != null) {
      gl.deleteTexture(_defaultFramebufferTexture);
    }
    if (_defaultDepthRenderbuffer != null) {
      gl.deleteRenderbuffer(_defaultDepthRenderbuffer);
    }
    if (_defaultFramebuffer != null) {
      gl.deleteFramebuffer(_defaultFramebuffer);
    }

    plugin.dispose();
  }

  _Hittable? _gestureTarget;  
  @override
  Widget build(BuildContext context) {
    return _Fiber3DCanvasScope(
      state: this,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;

          if (size.width == 0 || size.height == 0) {
            // Same zero-size first-frame issue found in Section 1
            // retry after the frame actually lays out.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() {});
            });
            return const SizedBox.shrink();
          }

          if (!_glInitStarted) {
            final dpr = MediaQuery.of(context).devicePixelRatio;
            _initGl(size, dpr);
          }

          return VisibilityDetector(
            key: _visibilityKey,
            onVisibilityChanged: (info) {
              final visible = info.visibleFraction > 0;
              if (visible != _canvasVisible) {
                _canvasVisible = visible;
                if (visible) _wakeTicker();
              }
            },
            child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (details) {
              final hit = _closestHitAt(details.localPosition, size);
              hit?.onTap?.call();
            },
            // Flutter's scale gesture subsumes single-finger pan: a
            // one-finger drag reports scale ~1.0 with a real
            // focalPointDelta; a two-finger pinch reports both a
            // changing scale and a delta. onPan and onScale can't both
            // be registered on one GestureDetector (conflicting
            // recognizers), so this one recognizer drives both
            // onPan, onPinch, and when the gesture starts on empty
            // space with orbitEnabled — camera orbit/zoom.
            onScaleStart: (details) {
              _gestureTarget = _closestHitAt(details.localFocalPoint, size);
              _orbiting = _gestureTarget == null && _orbitControls != null;
              _gestureTarget?.onPinchStart?.call();
              _gestureActive = true;
              _wakeTicker();
            },
            onScaleUpdate: (details) {
              if (_orbiting) {
                _orbitControls!.rotate(
                  details.focalPointDelta.dx,
                  details.focalPointDelta.dy,
                  size.height,
                );
                if (details.pointerCount >= 2) {
                  _orbitControls!.zoom(details.scale);
                }
                setState(() {
                  _camera = _orbitControls!.camera;
                });
                return;
              }

              _gestureTarget?.onPan?.call(details.focalPointDelta);
              if (details.pointerCount >= 2) {
                _gestureTarget?.onPinch?.call(details.scale);
              }
            },
            onScaleEnd: (_) {
              _gestureTarget = null;
              _orbiting = false;
              _gestureActive = false;
            },
            child: Stack(
              children: [
                if (_glReady && _glPlugin != null)
                  SizedBox(
                    width: size.width,
                    height: size.height,
                    child: kIsWeb
                        ? HtmlElementView(
                            viewType: _glPlugin!.textureId!.toString(),
                          )
                        : Texture(textureId: _glPlugin!.textureId!),
                  ),
                ...widget.children,
              ],
            ),
            ),
          );
        },
      ),
    );
  }
}

class _Fiber3DCanvasScope extends InheritedWidget {
  final Fiber3DCanvasState state;

  const _Fiber3DCanvasScope({required this.state, required super.child});

  static Fiber3DCanvasState of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<_Fiber3DCanvasScope>();
    assert(
      scope != null,
      'No Fiber3DCanvas found in context. onFrame requires being inside a Fiber3DCanvas.',
    );
    return scope!.state;
  }

  @override
  bool updateShouldNotify(_Fiber3DCanvasScope oldWidget) => false;
}

/// Holds the compiled GPU buffers for one mesh, built once and reused
/// every frame rather than rebuilt per draw call.
class _MeshBuffers {
  final dynamic positionBuffer;
  final dynamic normalBuffer;
  final dynamic indexBuffer;
  final int indexCount;

  /// Present only when the material requested wireframe rendering —
  /// each source triangle (a,b,c) contributes 3 line-index pairs
  /// (a-b, b-c, c-a), drawn with GL_LINES instead of GL_TRIANGLES.
  final dynamic lineIndexBuffer;
  final int lineIndexCount;

  _MeshBuffers({
    required this.positionBuffer,
    required this.normalBuffer,
    required this.indexBuffer,
    required this.indexCount,
    this.lineIndexBuffer,
    this.lineIndexCount = 0,
  });
}

mixin Fiber3DFrameCallbackMixin<T extends StatefulWidget> on State<T> {
  VoidCallback? _unregister;

  void onFrame(Duration elapsed, Duration delta);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _unregister?.call();
    _unregister = _Fiber3DCanvasScope.of(
      context,
    ).registerFrameCallback(onFrame);
  }

  @override
  void dispose() {
    _unregister?.call();
    super.dispose();
  }
}
