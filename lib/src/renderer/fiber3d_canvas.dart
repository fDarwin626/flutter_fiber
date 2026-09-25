import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_fiber/src/core/fiber3d_matrix4.dart';
import 'dart:io';
import 'package:coconut_flutter_gl/flutter_gl.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../camera/fiber3d_camera.dart';
import '../camera/fiber3d_orbit_controls.dart';
import '../material/fiber3d_pbr_shader.dart';
import '../material/fiber3d_lambert_shader.dart';
import '../material/fiber3d_phong_shader.dart';
import '../material/fiber3d_toon_shader.dart';
import '../material/fiber3d_matcap_shader.dart';
import '../core/fiber3d_vector3.dart';
import '../core/fiber3d_color.dart';
import '../light/fiber3d_lights_state.dart';
import '../core/fiber3d_color_management.dart';
import 'fiber3d_tone_mapping.dart';
import 'dart:math';
import '../material/fiber3d_dfg_lut_data.dart';
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

/// One frame's worth of resolved light data, computed once and applied
/// to every compiled program's uniform locations (PBR, Lambert, ...)
/// rather than re-walking widget.lights once per program.
class _LightsSnapshot {
  final List<double> ambient;
  final List<Fiber3DPointLightUniforms> points;

  _LightsSnapshot({required this.ambient, required this.points});
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

  /// When true (default), hex colors are converted to linear space for
  /// lighting and the final image is sRGB-encoded, like three.js. Set
  /// false for the v1 look (raw colors, no output encoding). Read once at
  /// creation.
  final bool colorManagement;

  /// Tone-mapping operator applied to the final color (three.js
  /// `renderer.toneMapping`). Read once at creation.
  final Fiber3DToneMapping toneMapping;

  /// Brightness multiplier used by the tone-mapping operators (three.js
  /// `renderer.toneMappingExposure`).
  final double toneMappingExposure;

  Fiber3DCanvas({
    super.key,
    this.children = const [],
    this.lights = const [],
    Fiber3DCamera? camera,
    this.orbitEnabled = false,
     this.backgroundColor = 0xFFFFFF,
    this.colorManagement = true,
    this.toneMapping = Fiber3DToneMapping.none,
    this.toneMappingExposure = 1.0,
  }) : camera = camera ?? Fiber3DCamera();

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

  /// The precomputed DFG lookup texture used by the physical material's
  /// specular BRDF (see lights_physical_pars_fragment). Uploaded once,
  /// never changes.
  dynamic _dfgLutTexture;

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


    _setupDfgLutTexture();
    _compileShader();
    _compileLambertShader();
    _compilePhongShader();
    _compileToonShader();
    _compileMatcapShader();
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
  int uModelViewMatrixLocation = -1;
  int uProjectionMatrixLocation = -1;
  int uNormalMatrixLocation = -1;
  int uViewMatrixLocation = -1;
  int uCameraPositionLocation = -1;

  int uDiffuseLocation = -1;
  int uRoughnessLocation = -1;
  int uMetalnessLocation = -1;
  int uOpacityLocation = -1;
  int uIsOrthographicLocation = -1;
  int uEmissiveLocation = -1;
  int uEmissiveIntensityLocation = -1;
  int uAmbientLightColorLocation = -1;
  int uDfgLutLocation = -1;

  List<int> uPointLightPositionLocations = [];
  List<int> uPointLightColorLocations = [];
  List<int> uPointLightDistanceLocations = [];
  List<int> uPointLightDecayLocations = [];

  int uToneMappingExposureLocation = -1;

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
      Fiber3DPbrShader.fragment(
        version,
        toneMapping: widget.toneMapping,
        outputColorSpace: widget.colorManagement
            ? Fiber3DColorSpace.srgb
            : Fiber3DColorSpace.linearSrgb,
      ),
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

    aPositionLocation = gl.getAttribLocation(glProgram, 'position');
    aNormalLocation = gl.getAttribLocation(glProgram, 'normal');
    
    uModelViewMatrixLocation = gl.getUniformLocation(
      glProgram,
      'modelViewMatrix',
    );
    uProjectionMatrixLocation = gl.getUniformLocation(
      glProgram,
      'projectionMatrix',
    );
    uNormalMatrixLocation = gl.getUniformLocation(glProgram, 'normalMatrix');
    uViewMatrixLocation = gl.getUniformLocation(glProgram, 'viewMatrix');
    uCameraPositionLocation = -1;

    uDiffuseLocation = gl.getUniformLocation(glProgram, 'diffuse');
    uRoughnessLocation = gl.getUniformLocation(glProgram, 'roughness');
    uMetalnessLocation = gl.getUniformLocation(glProgram, 'metalness');
    uOpacityLocation = gl.getUniformLocation(glProgram, 'opacity');
    uIsOrthographicLocation = gl.getUniformLocation(
      glProgram,
      'isOrthographic',
    );
    uEmissiveLocation = gl.getUniformLocation(glProgram, 'emissive');
    uEmissiveIntensityLocation = gl.getUniformLocation(
      glProgram,
      'emissiveIntensity',
    );

    uAmbientLightColorLocation = gl.getUniformLocation(
      glProgram,
      'ambientLightColor',
    );
    uDfgLutLocation = gl.getUniformLocation(glProgram, 'dfgLUT');

    uPointLightPositionLocations = List<int>.generate(
      Fiber3DPbrShader.maxPointLights,
      (i) => gl.getUniformLocation(glProgram, 'pointLights[$i].position'),
    );
    uPointLightColorLocations = List<int>.generate(
      Fiber3DPbrShader.maxPointLights,
      (i) => gl.getUniformLocation(glProgram, 'pointLights[$i].color'),
    );
    uPointLightDistanceLocations = List<int>.generate(
      Fiber3DPbrShader.maxPointLights,
      (i) => gl.getUniformLocation(glProgram, 'pointLights[$i].distance'),
    );
    uPointLightDecayLocations = List<int>.generate(
      Fiber3DPbrShader.maxPointLights,
      (i) => gl.getUniformLocation(glProgram, 'pointLights[$i].decay'),
    );

    uToneMappingExposureLocation = gl.getUniformLocation(
      glProgram,
      'toneMappingExposure',
    );
  }

  dynamic lambertGlProgram;

  int lambertAPositionLocation = -1;
  int lambertANormalLocation = -1;
  int uLambertModelViewMatrixLocation = -1;
  int uLambertProjectionMatrixLocation = -1;
  int uLambertNormalMatrixLocation = -1;
  int uLambertViewMatrixLocation = -1;
  int uLambertIsOrthographicLocation = -1;

  int uLambertDiffuseLocation = -1;
  int uLambertOpacityLocation = -1;
  int uLambertEmissiveLocation = -1;
  int uLambertEmissiveIntensityLocation = -1;
  int uLambertAmbientLightColorLocation = -1;

  List<int> uLambertPointLightPositionLocations = [];
  List<int> uLambertPointLightColorLocations = [];
  List<int> uLambertPointLightDistanceLocations = [];
  List<int> uLambertPointLightDecayLocations = [];

  /// Compiles Lambert as a second, independent GL program — matching
  /// three.js's WebGLPrograms (one compiled program per material type),
  /// not a variant of the PBR program. PBR and Lambert meshes each bind
  /// their own program in `_drawMesh`.
  void _compileLambertShader() {
    final gl = _glPlugin!.gl;
    final version = _glslVersion();

    final vs = _makeShader(
      gl,
      Fiber3DLambertShader.vertex(version),
      gl.VERTEX_SHADER,
    );
    final fs = _makeShader(
      gl,
      Fiber3DLambertShader.fragment(
        version,
        toneMapping: widget.toneMapping,
        outputColorSpace: widget.colorManagement
            ? Fiber3DColorSpace.srgb
            : Fiber3DColorSpace.linearSrgb,
      ),
      gl.FRAGMENT_SHADER,
    );

    lambertGlProgram = gl.createProgram();
    gl.attachShader(lambertGlProgram, vs);
    gl.attachShader(lambertGlProgram, fs);
    gl.linkProgram(lambertGlProgram);

    final linked = gl.getProgramParameter(lambertGlProgram, gl.LINK_STATUS);
    if (linked == false || linked == 0) {
      // ignore: avoid_print
      print("Fiber3DCanvas: lambert shader program failed to link");
      return;
    }

    gl.useProgram(lambertGlProgram);

    lambertAPositionLocation = gl.getAttribLocation(
      lambertGlProgram,
      'position',
    );
    lambertANormalLocation = gl.getAttribLocation(lambertGlProgram, 'normal');

    uLambertModelViewMatrixLocation = gl.getUniformLocation(
      lambertGlProgram,
      'modelViewMatrix',
    );
    uLambertProjectionMatrixLocation = gl.getUniformLocation(
      lambertGlProgram,
      'projectionMatrix',
    );
    uLambertNormalMatrixLocation = gl.getUniformLocation(
      lambertGlProgram,
      'normalMatrix',
    );
    uLambertViewMatrixLocation = gl.getUniformLocation(
      lambertGlProgram,
      'viewMatrix',
    );
    uLambertIsOrthographicLocation = gl.getUniformLocation(
      lambertGlProgram,
      'isOrthographic',
    );

    uLambertDiffuseLocation = gl.getUniformLocation(
      lambertGlProgram,
      'diffuse',
    );
    uLambertOpacityLocation = gl.getUniformLocation(
      lambertGlProgram,
      'opacity',
    );
    uLambertEmissiveLocation = gl.getUniformLocation(
      lambertGlProgram,
      'emissive',
    );
    uLambertEmissiveIntensityLocation = gl.getUniformLocation(
      lambertGlProgram,
      'emissiveIntensity',
    );
    uLambertAmbientLightColorLocation = gl.getUniformLocation(
      lambertGlProgram,
      'ambientLightColor',
    );

    uLambertPointLightPositionLocations = List<int>.generate(
      Fiber3DPbrShader.maxPointLights,
      (i) =>
          gl.getUniformLocation(lambertGlProgram, 'pointLights[$i].position'),
    );
    uLambertPointLightColorLocations = List<int>.generate(
      Fiber3DPbrShader.maxPointLights,
      (i) => gl.getUniformLocation(lambertGlProgram, 'pointLights[$i].color'),
    );
    uLambertPointLightDistanceLocations = List<int>.generate(
      Fiber3DPbrShader.maxPointLights,
      (i) => gl.getUniformLocation(
        lambertGlProgram,
        'pointLights[$i].distance',
      ),
    );
    uLambertPointLightDecayLocations = List<int>.generate(
      Fiber3DPbrShader.maxPointLights,
      (i) => gl.getUniformLocation(lambertGlProgram, 'pointLights[$i].decay'),
    );
  }

  dynamic phongGlProgram;

  int phongAPositionLocation = -1;
  int phongANormalLocation = -1;
  int uPhongModelViewMatrixLocation = -1;
  int uPhongProjectionMatrixLocation = -1;
  int uPhongNormalMatrixLocation = -1;
  int uPhongViewMatrixLocation = -1;
  int uPhongIsOrthographicLocation = -1;

  int uPhongDiffuseLocation = -1;
  int uPhongOpacityLocation = -1;
  int uPhongEmissiveLocation = -1;
  int uPhongEmissiveIntensityLocation = -1;
  int uPhongSpecularLocation = -1;
  int uPhongShininessLocation = -1;
  int uPhongAmbientLightColorLocation = -1;

  List<int> uPhongPointLightPositionLocations = [];
  List<int> uPhongPointLightColorLocations = [];
  List<int> uPhongPointLightDistanceLocations = [];
  List<int> uPhongPointLightDecayLocations = [];

  /// Compiles Phong as a third, independent GL program — same
  /// one-program-per-material-type pattern as Lambert.
  void _compilePhongShader() {
    final gl = _glPlugin!.gl;
    final version = _glslVersion();

    final vs = _makeShader(
      gl,
      Fiber3DPhongShader.vertex(version),
      gl.VERTEX_SHADER,
    );
    final fs = _makeShader(
      gl,
      Fiber3DPhongShader.fragment(
        version,
        toneMapping: widget.toneMapping,
        outputColorSpace: widget.colorManagement
            ? Fiber3DColorSpace.srgb
            : Fiber3DColorSpace.linearSrgb,
      ),
      gl.FRAGMENT_SHADER,
    );

    phongGlProgram = gl.createProgram();
    gl.attachShader(phongGlProgram, vs);
    gl.attachShader(phongGlProgram, fs);
    gl.linkProgram(phongGlProgram);

    final linked = gl.getProgramParameter(phongGlProgram, gl.LINK_STATUS);
    if (linked == false || linked == 0) {
      // ignore: avoid_print
      print("Fiber3DCanvas: phong shader program failed to link");
      return;
    }

    gl.useProgram(phongGlProgram);

    phongAPositionLocation = gl.getAttribLocation(phongGlProgram, 'position');
    phongANormalLocation = gl.getAttribLocation(phongGlProgram, 'normal');

    uPhongModelViewMatrixLocation = gl.getUniformLocation(
      phongGlProgram,
      'modelViewMatrix',
    );
    uPhongProjectionMatrixLocation = gl.getUniformLocation(
      phongGlProgram,
      'projectionMatrix',
    );
    uPhongNormalMatrixLocation = gl.getUniformLocation(
      phongGlProgram,
      'normalMatrix',
    );
    uPhongViewMatrixLocation = gl.getUniformLocation(
      phongGlProgram,
      'viewMatrix',
    );
    uPhongIsOrthographicLocation = gl.getUniformLocation(
      phongGlProgram,
      'isOrthographic',
    );

    uPhongDiffuseLocation = gl.getUniformLocation(phongGlProgram, 'diffuse');
    uPhongOpacityLocation = gl.getUniformLocation(phongGlProgram, 'opacity');
    uPhongEmissiveLocation = gl.getUniformLocation(
      phongGlProgram,
      'emissive',
    );
    uPhongEmissiveIntensityLocation = gl.getUniformLocation(
      phongGlProgram,
      'emissiveIntensity',
    );
    uPhongSpecularLocation = gl.getUniformLocation(
      phongGlProgram,
      'specular',
    );
    uPhongShininessLocation = gl.getUniformLocation(
      phongGlProgram,
      'shininess',
    );
    uPhongAmbientLightColorLocation = gl.getUniformLocation(
      phongGlProgram,
      'ambientLightColor',
    );

    uPhongPointLightPositionLocations = List<int>.generate(
      Fiber3DPbrShader.maxPointLights,
      (i) =>
          gl.getUniformLocation(phongGlProgram, 'pointLights[$i].position'),
    );
    uPhongPointLightColorLocations = List<int>.generate(
      Fiber3DPbrShader.maxPointLights,
      (i) => gl.getUniformLocation(phongGlProgram, 'pointLights[$i].color'),
    );
    uPhongPointLightDistanceLocations = List<int>.generate(
      Fiber3DPbrShader.maxPointLights,
      (i) =>
          gl.getUniformLocation(phongGlProgram, 'pointLights[$i].distance'),
    );
    uPhongPointLightDecayLocations = List<int>.generate(
      Fiber3DPbrShader.maxPointLights,
      (i) => gl.getUniformLocation(phongGlProgram, 'pointLights[$i].decay'),
    );
  }

  dynamic toonGlProgram;

  int toonAPositionLocation = -1;
  int toonANormalLocation = -1;
  int uToonModelViewMatrixLocation = -1;
  int uToonProjectionMatrixLocation = -1;
  int uToonNormalMatrixLocation = -1;
  int uToonViewMatrixLocation = -1;
  int uToonIsOrthographicLocation = -1;

  int uToonDiffuseLocation = -1;
  int uToonOpacityLocation = -1;
  int uToonEmissiveLocation = -1;
  int uToonEmissiveIntensityLocation = -1;
  int uToonAmbientLightColorLocation = -1;

  List<int> uToonPointLightPositionLocations = [];
  List<int> uToonPointLightColorLocations = [];
  List<int> uToonPointLightDistanceLocations = [];
  List<int> uToonPointLightDecayLocations = [];

  /// Compiles Toon as a fourth, independent GL program — same
  /// one-program-per-material-type pattern as Lambert/Phong. No
  /// specular/shininess uniforms — Toon has neither, matching three.js's
  /// own MeshToonMaterial.
  void _compileToonShader() {
    final gl = _glPlugin!.gl;
    final version = _glslVersion();

    final vs = _makeShader(
      gl,
      Fiber3DToonShader.vertex(version),
      gl.VERTEX_SHADER,
    );
    final fs = _makeShader(
      gl,
      Fiber3DToonShader.fragment(
        version,
        toneMapping: widget.toneMapping,
        outputColorSpace: widget.colorManagement
            ? Fiber3DColorSpace.srgb
            : Fiber3DColorSpace.linearSrgb,
      ),
      gl.FRAGMENT_SHADER,
    );

    toonGlProgram = gl.createProgram();
    gl.attachShader(toonGlProgram, vs);
    gl.attachShader(toonGlProgram, fs);
    gl.linkProgram(toonGlProgram);

    final linked = gl.getProgramParameter(toonGlProgram, gl.LINK_STATUS);
    if (linked == false || linked == 0) {
      // ignore: avoid_print
      print("Fiber3DCanvas: toon shader program failed to link");
      return;
    }

    gl.useProgram(toonGlProgram);

    toonAPositionLocation = gl.getAttribLocation(toonGlProgram, 'position');
    toonANormalLocation = gl.getAttribLocation(toonGlProgram, 'normal');

    uToonModelViewMatrixLocation = gl.getUniformLocation(
      toonGlProgram,
      'modelViewMatrix',
    );
    uToonProjectionMatrixLocation = gl.getUniformLocation(
      toonGlProgram,
      'projectionMatrix',
    );
    uToonNormalMatrixLocation = gl.getUniformLocation(
      toonGlProgram,
      'normalMatrix',
    );
    uToonViewMatrixLocation = gl.getUniformLocation(
      toonGlProgram,
      'viewMatrix',
    );
    uToonIsOrthographicLocation = gl.getUniformLocation(
      toonGlProgram,
      'isOrthographic',
    );

    uToonDiffuseLocation = gl.getUniformLocation(toonGlProgram, 'diffuse');
    uToonOpacityLocation = gl.getUniformLocation(toonGlProgram, 'opacity');
    uToonEmissiveLocation = gl.getUniformLocation(toonGlProgram, 'emissive');
    uToonEmissiveIntensityLocation = gl.getUniformLocation(
      toonGlProgram,
      'emissiveIntensity',
    );
    uToonAmbientLightColorLocation = gl.getUniformLocation(
      toonGlProgram,
      'ambientLightColor',
    );

    uToonPointLightPositionLocations = List<int>.generate(
      Fiber3DPbrShader.maxPointLights,
      (i) => gl.getUniformLocation(toonGlProgram, 'pointLights[$i].position'),
    );
    uToonPointLightColorLocations = List<int>.generate(
      Fiber3DPbrShader.maxPointLights,
      (i) => gl.getUniformLocation(toonGlProgram, 'pointLights[$i].color'),
    );
    uToonPointLightDistanceLocations = List<int>.generate(
      Fiber3DPbrShader.maxPointLights,
      (i) => gl.getUniformLocation(toonGlProgram, 'pointLights[$i].distance'),
    );
    uToonPointLightDecayLocations = List<int>.generate(
      Fiber3DPbrShader.maxPointLights,
      (i) => gl.getUniformLocation(toonGlProgram, 'pointLights[$i].decay'),
    );
  }

  dynamic matcapGlProgram;

  int matcapAPositionLocation = -1;
  int matcapANormalLocation = -1;
  int uMatcapModelViewMatrixLocation = -1;
  int uMatcapProjectionMatrixLocation = -1;
  int uMatcapNormalMatrixLocation = -1;

  int uMatcapDiffuseLocation = -1;
  int uMatcapOpacityLocation = -1;

  /// Compiles Matcap as a fifth, independent GL program. Unlike every
  /// other material here, Matcap's real three.js shader declares no
  /// viewMatrix, no isOrthographic, and no light-related uniforms at
  /// all — it does no light accumulation, so there's nothing to upload
  /// beyond the standard transform matrices and diffuse/opacity.
  void _compileMatcapShader() {
    final gl = _glPlugin!.gl;
    final version = _glslVersion();

    final vs = _makeShader(
      gl,
      Fiber3DMatcapShader.vertex(version),
      gl.VERTEX_SHADER,
    );
    final fs = _makeShader(
      gl,
      Fiber3DMatcapShader.fragment(
        version,
        toneMapping: widget.toneMapping,
        outputColorSpace: widget.colorManagement
            ? Fiber3DColorSpace.srgb
            : Fiber3DColorSpace.linearSrgb,
      ),
      gl.FRAGMENT_SHADER,
    );

    matcapGlProgram = gl.createProgram();
    gl.attachShader(matcapGlProgram, vs);
    gl.attachShader(matcapGlProgram, fs);
    gl.linkProgram(matcapGlProgram);

    final linked = gl.getProgramParameter(matcapGlProgram, gl.LINK_STATUS);
    if (linked == false || linked == 0) {
      // ignore: avoid_print
      print("Fiber3DCanvas: matcap shader program failed to link");
      return;
    }

    gl.useProgram(matcapGlProgram);

    matcapAPositionLocation = gl.getAttribLocation(matcapGlProgram, 'position');
    matcapANormalLocation = gl.getAttribLocation(matcapGlProgram, 'normal');

    uMatcapModelViewMatrixLocation = gl.getUniformLocation(
      matcapGlProgram,
      'modelViewMatrix',
    );
    uMatcapProjectionMatrixLocation = gl.getUniformLocation(
      matcapGlProgram,
      'projectionMatrix',
    );
    uMatcapNormalMatrixLocation = gl.getUniformLocation(
      matcapGlProgram,
      'normalMatrix',
    );

    uMatcapDiffuseLocation = gl.getUniformLocation(matcapGlProgram, 'diffuse');
    uMatcapOpacityLocation = gl.getUniformLocation(matcapGlProgram, 'opacity');
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
  /// Uploads the precomputed 16x16 DFG lookup table as an RG32F texture.
  /// Ported from three.js's DFGLUT.js texture setup (minFilter/magFilter
  /// Linear, wrapS/wrapT ClampToEdge, no mipmaps).
  void _setupDfgLutTexture() {
    final gl = _glPlugin!.gl;

    _dfgLutTexture = gl.createTexture();
    gl.bindTexture(gl.TEXTURE_2D, _dfgLutTexture);

    final data = Float32Array.fromList(dfgLutData);
    gl.texImage2D(
      gl.TEXTURE_2D,
      0,
      gl.RG32F,
      dfgLutSize,
      dfgLutSize,
      0,
      gl.RG,
      gl.FLOAT,
      data,
    );

    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
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
    final material = meshState.widget.material;
    final wantsEdges =
        material.wireframe == true || meshState.widget.showEdges == true;
    final wantsFlat = material.flatShading == true;

    final cached = _meshBufferCache[meshState];
    if (cached != null) {
      // Rebuild if edge/flat-shading settings changed since these buffers
      // were built e.g. wireframe toggled on for a mesh that had no
      // line-index buffer generated at first build.
      final cacheStillValid =
          cached.builtWithEdges == wantsEdges &&
          cached.builtWithFlatShading == wantsFlat;
      if (cacheStillValid) return cached;

      // Stale free the old GPU buffers before rebuilding.
      final gl = _glPlugin!.gl;
      gl.deleteBuffer(cached.positionBuffer);
      gl.deleteBuffer(cached.normalBuffer);
      gl.deleteBuffer(cached.indexBuffer);
      if (cached.lineIndexBuffer != null) {
        gl.deleteBuffer(cached.lineIndexBuffer);
      }
      _meshBufferCache.remove(meshState);
    }
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

    // Flat shading: one normal per triangle instead of interpolated
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

    if (wantsEdges) {
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
      builtWithEdges: wantsEdges,
      builtWithFlatShading: wantsFlat,
    );
    _meshBufferCache[meshState] = buffers;
    return buffers;
  }


  dynamic _currentBoundProgram;

  /// Switches the active GL program only when it differs from what's
  /// currently bound — avoids a redundant useProgram call when
  /// consecutive meshes share a material type.
  void _useProgram(dynamic gl, dynamic program) {
    if (!identical(_currentBoundProgram, program)) {
      gl.useProgram(program);
      _currentBoundProgram = program;
    }
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
    _useProgram(gl, glProgram);
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
    gl.uniform1i(uIsOrthographicLocation, 0);

    gl.activeTexture(gl.TEXTURE1);
    gl.bindTexture(gl.TEXTURE_2D, _dfgLutTexture);
    gl.uniform1i(uDfgLutLocation, 1);

    if (widget.toneMapping != Fiber3DToneMapping.none) {
      gl.uniform1f(uToneMappingExposureLocation, widget.toneMappingExposure);
    }

    // Light uniforms, computed once and applied to every compiled
    // program in turn (PBR always exists; Lambert only if wired).
    final lights = _computeLights();
    _applyLights(
      gl,
      lights,
      uAmbientLightColorLocation,
      uPointLightPositionLocations,
      uPointLightColorLocations,
      uPointLightDistanceLocations,
      uPointLightDecayLocations,
    );

    if (lambertGlProgram != null) {
      _useProgram(gl, lambertGlProgram);
      gl.uniformMatrix4fv(
        uLambertViewMatrixLocation,
        false,
        Float32Array.fromList(_camera.viewMatrix.elements),
      );
      gl.uniformMatrix4fv(
        uLambertProjectionMatrixLocation,
        false,
        Float32Array.fromList(projection.elements),
      );
      gl.uniform1i(uLambertIsOrthographicLocation, 0);
      _applyLights(
        gl,
        lights,
        uLambertAmbientLightColorLocation,
        uLambertPointLightPositionLocations,
        uLambertPointLightColorLocations,
        uLambertPointLightDistanceLocations,
        uLambertPointLightDecayLocations,
      );
    }

    if (phongGlProgram != null) {
      _useProgram(gl, phongGlProgram);
      gl.uniformMatrix4fv(
        uPhongViewMatrixLocation,
        false,
        Float32Array.fromList(_camera.viewMatrix.elements),
      );
      gl.uniformMatrix4fv(
        uPhongProjectionMatrixLocation,
        false,
        Float32Array.fromList(projection.elements),
      );
      gl.uniform1i(uPhongIsOrthographicLocation, 0);
      _applyLights(
        gl,
        lights,
        uPhongAmbientLightColorLocation,
        uPhongPointLightPositionLocations,
        uPhongPointLightColorLocations,
        uPhongPointLightDistanceLocations,
        uPhongPointLightDecayLocations,
      );
    }

    if (toonGlProgram != null) {
      _useProgram(gl, toonGlProgram);
      gl.uniformMatrix4fv(
        uToonViewMatrixLocation,
        false,
        Float32Array.fromList(_camera.viewMatrix.elements),
      );
      gl.uniformMatrix4fv(
        uToonProjectionMatrixLocation,
        false,
        Float32Array.fromList(projection.elements),
      );
      gl.uniform1i(uToonIsOrthographicLocation, 0);
      _applyLights(
        gl,
        lights,
        uToonAmbientLightColorLocation,
        uToonPointLightPositionLocations,
        uToonPointLightColorLocations,
        uToonPointLightDistanceLocations,
        uToonPointLightDecayLocations,
      );
    }

    if (matcapGlProgram != null) {
      _useProgram(gl, matcapGlProgram);
      gl.uniformMatrix4fv(
        uMatcapProjectionMatrixLocation,
        false,
        Float32Array.fromList(projection.elements),
      );
    }

    // Back to PBR _drawMesh assumes glProgram is the default bound
    // program and only switches away for Lambert/Phong/Toon/Matcap
    // meshes.
    _useProgram(gl, glProgram);

    for (final meshState in _meshes) {
      _drawMesh(gl, meshState);
    }
    gl.finish();

    if (!kIsWeb) {
      _glPlugin!.updateTexture(_sourceTexture);
    }
  }

    final Fiber3DColor _workingColor = Fiber3DColor();

  Fiber3DColor _linearColor(int hex) => _workingColor.setHex(
    hex,
    colorSpace: widget.colorManagement
        ? Fiber3DColorSpace.srgb
        : Fiber3DColorSpace.linearSrgb,
  );

  _LightsSnapshot _computeLights() {
    var ambientColorsLinear = <List<double>>[];
    var ambientIntensities = <double>[];
    final pointLightUniforms = <Fiber3DPointLightUniforms>[];

    for (final light in widget.lights) {
      final typeName = light.runtimeType.toString();
      if (typeName == 'Fiber3DAmbientLight') {
        final c = _linearColor(light.color);
        ambientColorsLinear.add([c.r, c.g, c.b]);
        ambientIntensities.add(light.intensity as double);
      } else if (typeName == 'Fiber3DPointLight' &&
          pointLightUniforms.length < Fiber3DPbrShader.maxPointLights) {
        final c = _linearColor(light.color);
        pointLightUniforms.add(
          Fiber3DLightsState.pointLightUniforms(
            x: light.position.x,
            y: light.position.y,
            z: light.position.z,
            colorLinear: [c.r, c.g, c.b],
            intensity: light.intensity,
            distance: light.distance,
            decay: light.decay,
            viewMatrix: _camera.viewMatrix,
          ),
        );
      }
    }

    final ambient = Fiber3DLightsState.sumAmbient(
      colorsLinear: ambientColorsLinear,
      intensities: ambientIntensities,
    );

    return _LightsSnapshot(ambient: ambient, points: pointLightUniforms);
  }

  void _applyLights(
    dynamic gl,
    _LightsSnapshot lights,
    int ambientLoc,
    List<int> posLocs,
    List<int> colorLocs,
    List<int> distLocs,
    List<int> decayLocs,
  ) {
    final ambient = lights.ambient;
    gl.uniform3f(ambientLoc, ambient[0], ambient[1], ambient[2]);

    for (var i = 0; i < Fiber3DPbrShader.maxPointLights; i++) {
      if (i < lights.points.length) {
        final u = lights.points[i];
        gl.uniform3f(posLocs[i], u.x, u.y, u.z);
        gl.uniform3f(colorLocs[i], u.r, u.g, u.b);
        gl.uniform1f(distLocs[i], u.distance);
        gl.uniform1f(decayLocs[i], u.decay);
      } else {
        gl.uniform3f(posLocs[i], 0, 0, 0);
        gl.uniform3f(colorLocs[i], 0, 0, 0);
        gl.uniform1f(distLocs[i], 0);
        gl.uniform1f(decayLocs[i], 2);
      }
    }
  }

  void _drawMesh(dynamic gl, dynamic meshState) {
    final buffers = _buffersFor(meshState);
    if (buffers == null) return;

    meshState.transform.updateWorldMatrix(updateParents: true);
    final modelMatrix = meshState.transform.matrixWorld;

    final modelViewMatrix = _camera.viewMatrix.clone();
    modelViewMatrix.multiply(modelMatrix);

    final normalSource = modelViewMatrix.clone();
    normalSource.invert();
    final ns = normalSource.elements;
    final normalMatrix = Float32Array.fromList([
      ns[0], ns[4], ns[8],
      ns[1], ns[5], ns[9],
      ns[2], ns[6], ns[10],
    ]);


    final material = meshState.widget.material;
    final materialType = material.runtimeType.toString();
        final isLambert =
        materialType == 'Fiber3DLambertMaterial' && lambertGlProgram != null;
    final isPhong =
        materialType == 'Fiber3DPhongMaterial' && phongGlProgram != null;
    final isToon =
        materialType == 'Fiber3DToonMaterial' && toonGlProgram != null;
    final isMatcap =
        materialType == 'Fiber3DMatcapMaterial' && matcapGlProgram != null;

    final program = isLambert
        ? lambertGlProgram
        : isPhong
            ? phongGlProgram
            : isToon
                ? toonGlProgram
                : isMatcap
                    ? matcapGlProgram
                    : glProgram;
    _useProgram(gl, program);

    final positionLoc = isLambert
        ? lambertAPositionLocation
        : isPhong
            ? phongAPositionLocation
            : isToon
                ? toonAPositionLocation
                : isMatcap
                    ? matcapAPositionLocation
                    : aPositionLocation;
    final normalLoc = isLambert
        ? lambertANormalLocation
        : isPhong
            ? phongANormalLocation
            : isToon
                ? toonANormalLocation
                : isMatcap
                    ? matcapANormalLocation
                    : aNormalLocation;
    final mvLoc = isLambert
        ? uLambertModelViewMatrixLocation
        : isPhong
            ? uPhongModelViewMatrixLocation
            : isToon
                ? uToonModelViewMatrixLocation
                : isMatcap
                    ? uMatcapModelViewMatrixLocation
                    : uModelViewMatrixLocation;
    final normalMatLoc = isLambert
        ? uLambertNormalMatrixLocation
        : isPhong
            ? uPhongNormalMatrixLocation
            : isToon
                ? uToonNormalMatrixLocation
                : isMatcap
                    ? uMatcapNormalMatrixLocation
                    : uNormalMatrixLocation;
    final diffuseLoc = isLambert
        ? uLambertDiffuseLocation
        : isPhong
            ? uPhongDiffuseLocation
            : isToon
                ? uToonDiffuseLocation
                : isMatcap
                    ? uMatcapDiffuseLocation
                    : uDiffuseLocation;
    final opacityLoc = isLambert
        ? uLambertOpacityLocation
        : isPhong
            ? uPhongOpacityLocation
            : isToon
                ? uToonOpacityLocation
                : isMatcap
                    ? uMatcapOpacityLocation
                    : uOpacityLocation;
    final emissiveLoc = isLambert
        ? uLambertEmissiveLocation
        : isPhong
            ? uPhongEmissiveLocation
            : isToon
                ? uToonEmissiveLocation
                : uEmissiveLocation;
    final emissiveIntensityLoc = isLambert
        ? uLambertEmissiveIntensityLocation
        : isPhong
            ? uPhongEmissiveIntensityLocation
            : isToon
                ? uToonEmissiveIntensityLocation
                : uEmissiveIntensityLocation;
    gl.uniformMatrix4fv(
      mvLoc,
      false,
      Float32Array.fromList(modelViewMatrix.elements),
    );
    gl.uniformMatrix3fv(normalMatLoc, false, normalMatrix);

    if (materialType == 'Fiber3DStandardMaterial') {
      final base = _linearColor(material.color);
      gl.uniform3f(diffuseLoc, base.r, base.g, base.b);
      gl.uniform1f(uRoughnessLocation, material.roughness);
      gl.uniform1f(uMetalnessLocation, material.metalness);
      gl.uniform1f(opacityLoc, 1.0);
      final emissive = _linearColor(material.emissive);
      gl.uniform3f(emissiveLoc, emissive.r, emissive.g, emissive.b);
      gl.uniform1f(emissiveIntensityLoc, material.emissiveIntensity);
    } else if (materialType == 'Fiber3DLambertMaterial') {
      final base = _linearColor(material.color);
      gl.uniform3f(diffuseLoc, base.r, base.g, base.b);
      gl.uniform1f(opacityLoc, 1.0);
      final emissive = _linearColor(material.emissive);
      gl.uniform3f(emissiveLoc, emissive.r, emissive.g, emissive.b);
      gl.uniform1f(emissiveIntensityLoc, material.emissiveIntensity);
    } else if (materialType == 'Fiber3DPhongMaterial') {
      final base = _linearColor(material.color);
      gl.uniform3f(diffuseLoc, base.r, base.g, base.b);
      gl.uniform1f(opacityLoc, 1.0);
      final emissive = _linearColor(material.emissive);
      gl.uniform3f(emissiveLoc, emissive.r, emissive.g, emissive.b);
      gl.uniform1f(emissiveIntensityLoc, material.emissiveIntensity);
      final specular = _linearColor(material.specular);
      gl.uniform3f(uPhongSpecularLocation, specular.r, specular.g, specular.b);
      gl.uniform1f(uPhongShininessLocation, material.shininess);
     } else if (materialType == 'Fiber3DToonMaterial') {
      final base = _linearColor(material.color);
      gl.uniform3f(diffuseLoc, base.r, base.g, base.b);
      gl.uniform1f(opacityLoc, 1.0);
      final emissive = _linearColor(material.emissive);
      gl.uniform3f(emissiveLoc, emissive.r, emissive.g, emissive.b);
      gl.uniform1f(emissiveIntensityLoc, material.emissiveIntensity);
    } else if (materialType == 'Fiber3DMatcapMaterial') {
      final base = _linearColor(material.color);
      gl.uniform3f(diffuseLoc, base.r, base.g, base.b);
      gl.uniform1f(opacityLoc, 1.0);
    } else if (materialType == 'Fiber3DBasicMaterial') {      
      gl.uniform3f(diffuseLoc, 0, 0, 0);
      gl.uniform1f(uRoughnessLocation, 1.0);
      gl.uniform1f(uMetalnessLocation, 0.0);
      gl.uniform1f(opacityLoc, 1.0);
      final basic = _linearColor(material.color);
      gl.uniform3f(emissiveLoc, basic.r, basic.g, basic.b);
      gl.uniform1f(emissiveIntensityLoc, 1.0);
    }

    gl.bindBuffer(gl.ARRAY_BUFFER, buffers.positionBuffer);
    gl.vertexAttribPointer(positionLoc, 3, gl.FLOAT, false, 0, 0);
    gl.enableVertexAttribArray(positionLoc);

    gl.bindBuffer(gl.ARRAY_BUFFER, buffers.normalBuffer);
    gl.vertexAttribPointer(normalLoc, 3, gl.FLOAT, false, 0, 0);
    gl.enableVertexAttribArray(normalLoc);

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

    final previousProgram = _currentBoundProgram;
    _useProgram(gl, edgeGlProgram);

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

    _useProgram(gl, previousProgram);
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
  /// and depth renderbuffer since stopping the ticker alone doesn't free
  /// GPU memory when this widget leaves the tree.
  void _releaseGlResources() {
    final plugin = _glPlugin;
    if (plugin == null) return;

    // Disposed before initialize() finished: there is no GL context yet,
    // plugin.gl throws a LateInitializationError, and nothing needs releasing.
    final dynamic gl;
    try {
      gl = plugin.gl;
    } on Error {
      return;
    }
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
    if (lambertGlProgram != null) gl.deleteProgram(lambertGlProgram);
    if (phongGlProgram != null) gl.deleteProgram(phongGlProgram);
    if (toonGlProgram != null) gl.deleteProgram(toonGlProgram);
    if (matcapGlProgram != null) gl.deleteProgram(matcapGlProgram);
    if (edgeGlProgram != null) gl.deleteProgram(edgeGlProgram);          
    if (_defaultFramebufferTexture != null) {
      gl.deleteTexture(_defaultFramebufferTexture);
    }
    if (_dfgLutTexture != null) {
      gl.deleteTexture(_dfgLutTexture);
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

  /// The edge/flat-shading settings these buffers were built with
  /// compared against the mesh's current settings each frame so a live
  /// toggle (e.g. showEdges flipped after first build) triggers a rebuild
  /// instead of silently reusing stale buffers.
  final bool builtWithEdges;
  final bool builtWithFlatShading;

  _MeshBuffers({
    required this.positionBuffer,
    required this.normalBuffer,
    required this.indexBuffer,
    required this.indexCount,
    this.lineIndexBuffer,
    this.lineIndexCount = 0,
    required this.builtWithEdges,
    required this.builtWithFlatShading,
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
