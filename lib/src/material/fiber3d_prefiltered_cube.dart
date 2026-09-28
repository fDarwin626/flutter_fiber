import 'dart:math';
import 'dart:typed_data';

/// Writes the linear-RGB radiance seen along the unit direction (x, y, z)
/// into out[0..2]. Values may exceed 1.0 (HDR).
typedef Fiber3DRadianceFunction =
    void Function(double x, double y, double z, List<double> out);

class Fiber3DPrefilteredCube {
  /// Log2 of the face size of the roughest level (three.js `LOD_MIN`).
  static const int lodMin = 3;

  /// Smallest allowed face size (gives maxLod >= 0).
  static const int minSize = 8;

  /// Face size of level 0.
  final int size;

  /// Last mip level index (three.js `ENVMAP_MAX_LOD`).
  final int maxLod;

  /// `faces[lod][face]` is a `faceSize(lod)^2 * 4` RGBA float array.
  final List<List<Float32List>> faces;

  Fiber3DPrefilteredCube._(this.size, this.maxLod, this.faces);

  int faceSize(int lod) => size >> lod;

  /// The roughness a mip level is prefiltered for
  /// (three.js `PMREMGenerator.lodToRoughness`).
  static double lodToRoughness(int lod, int maxLod) =>
      maxLod > 0 ? 1 - sqrt(1 - lod / maxLod) : 0.0;

  /// Inverse of [lodToRoughness] (three.js `roughnessToMip`).
  static double roughnessToMip(double roughness, int maxLod) {
    final r = roughness < 0 ? 0.0 : (roughness > 1 ? 1.0 : roughness);
    return maxLod * r * (2.0 - r);
  }

  /// Unit direction for texel coordinates (a, b) in [-1, 1] on [face],
  /// where a grows with the column and b grows with the row (downwards).
  /// Inverse of the GL cube-map face selection table.
  static void faceDirection(int face, double a, double b, List<double> out) {
    double x, y, z;
    switch (face) {
      case 0:
        x = 1;
        y = -b;
        z = -a;
      case 1:
        x = -1;
        y = -b;
        z = a;
      case 2:
        x = a;
        y = 1;
        z = b;
      case 3:
        x = a;
        y = -1;
        z = -b;
      case 4:
        x = a;
        y = -b;
        z = 1;
      default:
        x = -a;
        y = -b;
        z = -1;
    }
    final inv = 1.0 / sqrt(x * x + y * y + z * z);
    out[0] = x * inv;
    out[1] = y * inv;
    out[2] = z * inv;
  }

  /// Builds the mip chain by sampling [radiance]. [size] must be a power
  /// of two >= [minSize]; [samples] is the GGX sample count per texel.
  factory Fiber3DPrefilteredCube.generate(
    Fiber3DRadianceFunction radiance, {
    int size = 128,
    int samples = 128,
  }) {
    if (size < minSize || (size & (size - 1)) != 0) {
      throw ArgumentError.value(
        size,
        'size',
        'must be a power of two >= $minSize',
      );
    }

    final maxLod = size.bitLength - 1 - lodMin;
    final faces = <List<Float32List>>[];
    final dir = List<double>.filled(3, 0);
    final rad = List<double>.filled(3, 0);

    for (var lod = 0; lod <= maxLod; lod++) {
      final n = size >> lod;
      final roughness = lodToRoughness(lod, maxLod);
      final levelFaces = <Float32List>[];

      for (var face = 0; face < 6; face++) {
        final data = Float32List(n * n * 4);
        for (var j = 0; j < n; j++) {
          final b = 2.0 * (j + 0.5) / n - 1.0;
          for (var i = 0; i < n; i++) {
            final a = 2.0 * (i + 0.5) / n - 1.0;
            faceDirection(face, a, b, dir);

            if (roughness <= 0) {
              radiance(dir[0], dir[1], dir[2], rad);
            } else {
              _prefilterTexel(radiance, dir, roughness, samples, rad);
            }

            final o = (j * n + i) * 4;
            data[o] = rad[0];
            data[o + 1] = rad[1];
            data[o + 2] = rad[2];
            data[o + 3] = 1.0;
          }
        }
        levelFaces.add(data);
      }
      faces.add(levelFaces);
    }

    return Fiber3DPrefilteredCube._(size, maxLod, faces);
  }

  /// Radical inverse in base 2 (Van der Corput), the second Hammersley
  /// coordinate.
  static double _radicalInverse(int i) {
    var f = 0.5;
    var r = 0.0;
    var n = i;
    while (n > 0) {
      if ((n & 1) == 1) r += f;
      f *= 0.5;
      n >>= 1;
    }
    return r;
  }

  /// Split-sum prefilter for one texel: GGX importance sampling with
  /// N = V = R, weighted by N.L.
  static void _prefilterTexel(
    Fiber3DRadianceFunction radiance,
    List<double> n,
    double roughness,
    int samples,
    List<double> out,
  ) {
    final alpha = roughness * roughness;
    final a2 = alpha * alpha;
    final nx = n[0], ny = n[1], nz = n[2];

    // Tangent frame: T = normalize(cross(up, N)), B = cross(N, T).
    final upIsZ = nz.abs() < 0.999;
    final ux = upIsZ ? 0.0 : 1.0;
    final uz = upIsZ ? 1.0 : 0.0;
    var tx = -uz * ny;
    var ty = uz * nx - ux * nz;
    var tz = ux * ny;
    final tl = 1.0 / sqrt(tx * tx + ty * ty + tz * tz);
    tx *= tl;
    ty *= tl;
    tz *= tl;
    final bx = ny * tz - nz * ty;
    final by = nz * tx - nx * tz;
    final bz = nx * ty - ny * tx;

    final tmp = List<double>.filled(3, 0);
    var r = 0.0, g = 0.0, bl = 0.0, w = 0.0;

    for (var k = 0; k < samples; k++) {
      final phi = 2.0 * pi * ((k + 0.5) / samples);
      final xi = _radicalInverse(k);
      final cosT = sqrt((1.0 - xi) / (1.0 + (a2 - 1.0) * xi));
      final sinT = sqrt(max(0.0, 1.0 - cosT * cosT));

      final hx = sinT * cos(phi);
      final hy = sinT * sin(phi);
      final hz = cosT;

      final wx = tx * hx + bx * hy + nx * hz;
      final wy = ty * hx + by * hy + ny * hz;
      final wz = tz * hx + bz * hy + nz * hz;

      // L = 2 (N.H) H - N, and N.H = hz in the tangent frame.
      final lx = 2.0 * hz * wx - nx;
      final ly = 2.0 * hz * wy - ny;
      final lz = 2.0 * hz * wz - nz;
      final ndl = lx * nx + ly * ny + lz * nz;

      if (ndl > 0) {
        radiance(lx, ly, lz, tmp);
        r += tmp[0] * ndl;
        g += tmp[1] * ndl;
        bl += tmp[2] * ndl;
        w += ndl;
      }
    }

    if (w > 0) {
      out[0] = r / w;
      out[1] = g / w;
      out[2] = bl / w;
    } else {
      radiance(nx, ny, nz, out);
    }
  }
}