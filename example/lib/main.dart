import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gl_flutterflow/flutter_gl.dart';
import 'package:flutter_fiber/src/geometry/fiber3d_ring.dart';

void main() {
  runApp(const FiberRingTest());
}

class FiberRingTest extends StatefulWidget {
  const FiberRingTest({super.key});

  @override
  State<FiberRingTest> createState() => _FiberRingTestState();
}

class _FiberRingTestState extends State<FiberRingTest> {
  late FlutterGlPlugin flutterGlPlugin;

  num dpr = 1.0;
  late double width;
  late double height;

  Size? screenSize;

  dynamic glProgram;
  dynamic _vao;

  dynamic sourceTexture;
  dynamic defaultFramebuffer;
  dynamic defaultFramebufferTexture;

  int indexCount = 0;
  int t = DateTime.now().millisecondsSinceEpoch;
  bool _glReady = false;

  int _uMatrixLocation = -1;

  Timer? _spinTimer;

  Future<void> initPlatformState() async {
    width = screenSize!.width;
    height = width;

    flutterGlPlugin = FlutterGlPlugin();

    Map<String, dynamic> options = {
      "antialias": true,
      "alpha": false,
      "width": width.toInt(),
      "height": height.toInt(),
      "dpr": dpr,
    };

    await flutterGlPlugin.initialize(options: options);

    setState(() {});

    Future.delayed(const Duration(milliseconds: 100), () {
      setup();
    });
  }

  Future<void> setup() async {
    if (!kIsWeb) {
      await flutterGlPlugin.prepareContext();
      setupDefaultFBO();
      sourceTexture = defaultFramebufferTexture;
    }

    setState(() {});

    prepare();

    setState(() {
      _glReady = true;
    });

    // Auto-spin so the cube's 3D shape is visible without manual taps.
    _spinTimer = Timer.periodic(const Duration(milliseconds: 40), (_) {
      render();
    });
  }

  void initSize(BuildContext context) {
    if (screenSize != null) return;

    final mq = MediaQuery.of(context);
    final size = mq.size;

    if (size.width == 0 || size.height == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
      return;
    }

    screenSize = size;
    dpr = mq.devicePixelRatio;

    initPlatformState();
  }

  @override
  void dispose() {
    _spinTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('flutter_fiber — Section 2.1 Ring test'),
        ),
        body: Builder(
          builder: (BuildContext context) {
            initSize(context);
            return SingleChildScrollView(child: _build(context));
          },
        ),
      ),
    );
  }

  Widget _build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: width,
          height: width,
          color: Colors.black,
          child: Builder(builder: (BuildContext context) {
            if (kIsWeb) {
              return flutterGlPlugin.isInitialized
                  ? HtmlElementView(
                      viewType: flutterGlPlugin.textureId!.toString())
                  : Container();
            } else {
              return flutterGlPlugin.isInitialized
                  ? Texture(textureId: flutterGlPlugin.textureId!)
                  : Container();
            }
          }),
        ),
      ],
    );
  }

  void setupDefaultFBO() {
    final gl = flutterGlPlugin.gl;
    int glWidth = (width * dpr).toInt();
    int glHeight = (height * dpr).toInt();

    defaultFramebuffer = gl.createFramebuffer();
    defaultFramebufferTexture = gl.createTexture();
    gl.activeTexture(gl.TEXTURE0);

    gl.bindTexture(gl.TEXTURE_2D, defaultFramebufferTexture);
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, glWidth, glHeight, 0, gl.RGBA,
        gl.UNSIGNED_BYTE, null);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);

    gl.bindFramebuffer(gl.FRAMEBUFFER, defaultFramebuffer);
    gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0,
        gl.TEXTURE_2D, defaultFramebufferTexture, 0);
  }

  void render() {
    final gl = flutterGlPlugin.gl;

    int current = DateTime.now().millisecondsSinceEpoch;

    gl.viewport(0, 0, (width * dpr).toInt(), (height * dpr).toInt());

    gl.clearColor(0.05, 0.05, 0.08, 1.0);
    gl.clear(gl.COLOR_BUFFER_BIT);

    final angle = (current - t) / 1000.0;
    final matrix = _rotationY(angle);
    gl.uniformMatrix4fv(_uMatrixLocation, false, Float32Array.fromList(matrix));

    gl.drawElements(gl.TRIANGLES, indexCount, gl.UNSIGNED_SHORT, 0);

    gl.finish();

    if (!kIsWeb) {
      flutterGlPlugin.updateTexture(sourceTexture);
    }
  }

  /// Column-major 4x4 rotation matrix around the Y axis.
  List<double> _rotationY(double radians) {
    final c = cos(radians);
    final s = sin(radians);
    return [
      c, 0, -s, 0,
      0, 1, 0, 0,
      s, 0, c, 0,
      0, 0, 0, 1,
    ];
  }

  void prepare() {
    final gl = flutterGlPlugin.gl;

    String version = "300 es";
    if (!kIsWeb) {
      if (Platform.isMacOS || Platform.isWindows) {
        version = "150";
      }
    }

    var vs = """#version $version
#define attribute in
#define varying out
attribute vec3 a_Position;
uniform mat4 u_Matrix;
void main() {
    gl_Position = u_Matrix * vec4(a_Position, 1.0);
}
    """;

    var fs = """#version $version
out highp vec4 pc_fragColor;
#define gl_FragColor pc_fragColor

void main() {
  gl_FragColor = vec4(0.2, 0.8, 1.0, 1.0);
}
    """;

    if (!initShaders(gl, vs, fs)) {
      print('Failed to initialize shaders.');
      return;
    }

    _uMatrixLocation = gl.getUniformLocation(glProgram, 'u_Matrix');

    indexCount = initVertexBuffers(gl);
    if (indexCount < 0) {
      print('Failed to set the positions of the vertices');
      return;
    }
  }

  int initVertexBuffers(gl) {
    final ring = Fiber3DRing();
    var dim = 3;

    var vertices = Float32Array.fromList(ring.positions);
    var indices = Uint16Array.fromList(ring.indices);

    _vao = gl.createVertexArray();
    gl.bindVertexArray(_vao);

    var vertexBuffer = gl.createBuffer();
    if (vertexBuffer == null) {
      print('Failed to create the vertex buffer object');
      return -1;
    }
    gl.bindBuffer(gl.ARRAY_BUFFER, vertexBuffer);

    if (kIsWeb) {
      gl.bufferData(
          gl.ARRAY_BUFFER, vertices.length, vertices, gl.STATIC_DRAW);
    } else {
      gl.bufferData(gl.ARRAY_BUFFER, vertices.lengthInBytes, vertices,
          gl.STATIC_DRAW);
    }

    var a_Position = gl.getAttribLocation(glProgram, 'a_Position');
    if (a_Position < 0) {
      print('Failed to get the storage location of a_Position');
      return -1;
    }

    gl.vertexAttribPointer(
        a_Position, dim, gl.FLOAT, false, Float32List.bytesPerElement * 3, 0);
    gl.enableVertexAttribArray(a_Position);

    var indexBuffer = gl.createBuffer();
    if (indexBuffer == null) {
      print('Failed to create the index buffer object');
      return -1;
    }
    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, indexBuffer);

    if (kIsWeb) {
      gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, indices.length, indices,
          gl.STATIC_DRAW);
    } else {
      gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, indices.lengthInBytes, indices,
          gl.STATIC_DRAW);
    }

    return ring.indices.length;
  }

  bool initShaders(gl, vsSource, fsSource) {
    var vertexShader = makeShader(gl, vsSource, gl.VERTEX_SHADER);
    var fragmentShader = makeShader(gl, fsSource, gl.FRAGMENT_SHADER);

    glProgram = gl.createProgram();

    gl.attachShader(glProgram, vertexShader);
    gl.attachShader(glProgram, fragmentShader);
    gl.linkProgram(glProgram);
    var res = gl.getProgramParameter(glProgram, gl.LINK_STATUS);
    if (res == false || res == 0) {
      print("Unable to initialize the shader program");
      return false;
    }

    gl.useProgram(glProgram);

    return true;
  }

  dynamic makeShader(gl, src, type) {
    var shader = gl.createShader(type);
    gl.shaderSource(shader, src);
    gl.compileShader(shader);
    var res = gl.getShaderParameter(shader, gl.COMPILE_STATUS);
    if (res == 0 || res == false) {
      print("Error compiling shader: ${gl.getShaderInfoLog(shader)}");
      return;
    }
    return shader;
  }
}