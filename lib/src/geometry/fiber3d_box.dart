/// A geometry class for a rectangular cuboid with a given width, height,
/// and depth. On creation, the cuboid is centred on the origin, with each
/// edge parallel to one of the axes.
///
/// Ported from three.js's `BoxGeometry` (src/geometries/BoxGeometry.js).
/// Multi-material face groups are intentionally omitted — flutter_fiber's
class Fiber3DBox {
  final double width;
  final double height;
  final double depth;
  final int widthSegments;
  final int heightSegments;
  final int depthSegments;

  /// Flat list of vertex positions, 3 floats (x, y, z) per vertex.
  final List<double> positions = [];

  /// Flat list of vertex normals, 3 floats (x, y, z) per vertex.
  final List<double> normals = [];

  /// Flat list of vertex UVs, 2 floats (u, v) per vertex.
  final List<double> uvs = [];

  /// Triangle indices into the position/normal/uv buffers.
  final List<int> indices = [];

  int _numberOfVertices = 0;

  Fiber3DBox({
    this.width = 1,
    this.height = 1,
    this.depth = 1,
    this.widthSegments = 1,
    this.heightSegments = 1,
    this.depthSegments = 1,
  }) {
    // Axis indices: 0 = x, 1 = y, 2 = z — mirrors three.js's 'x'/'y'/'z'
    // string component lookup (vector[u], vector[v], vector[w]).
    // Face order and parameters match three.js exactly: px, nx, py, ny, pz, nz
    _buildPlane(2, 1, 0, -1, -1, depth, height, width, depthSegments, heightSegments); // px
    _buildPlane(2, 1, 0, 1, -1, depth, height, -width, depthSegments, heightSegments); // nx
    _buildPlane(0, 2, 1, 1, 1, width, depth, height, widthSegments, depthSegments); // py
    _buildPlane(0, 2, 1, 1, -1, width, depth, -height, widthSegments, depthSegments); // ny
    _buildPlane(0, 1, 2, 1, -1, width, height, depth, widthSegments, heightSegments); // pz
    _buildPlane(0, 1, 2, -1, -1, width, height, -depth, widthSegments, heightSegments); // nz
  }

  void _buildPlane(
    int u,
    int v,
    int w,
    double uDir,
    double vDir,
    double planeWidth,
    double planeHeight,
    double planeDepth,
    int gridX,
    int gridY,
  ) {
    final segmentWidth = planeWidth / gridX;
    final segmentHeight = planeHeight / gridY;

    final widthHalf = planeWidth / 2;
    final heightHalf = planeHeight / 2;
    final depthHalf = planeDepth / 2;

    final gridX1 = gridX + 1;
    final gridY1 = gridY + 1;

    var vertexCounter = 0;

    for (var iy = 0; iy < gridY1; iy++) {
      final y = iy * segmentHeight - heightHalf;

      for (var ix = 0; ix < gridX1; ix++) {
        final x = ix * segmentWidth - widthHalf;

        final vertex = List<double>.filled(3, 0);
        vertex[u] = x * uDir;
        vertex[v] = y * vDir;
        vertex[w] = depthHalf;
        positions.addAll(vertex);

        final normal = List<double>.filled(3, 0);
        normal[u] = 0;
        normal[v] = 0;
        normal[w] = planeDepth > 0 ? 1 : -1;
        normals.addAll(normal);

        uvs.add(ix / gridX);
        uvs.add(1 - (iy / gridY));

        vertexCounter++;
      }
    }

    for (var iy = 0; iy < gridY; iy++) {
      for (var ix = 0; ix < gridX; ix++) {
        final a = _numberOfVertices + ix + gridX1 * iy;
        final b = _numberOfVertices + ix + gridX1 * (iy + 1);
        final c = _numberOfVertices + (ix + 1) + gridX1 * (iy + 1);
        final d = _numberOfVertices + (ix + 1) + gridX1 * iy;

        indices.addAll([a, b, d]);
        indices.addAll([b, c, d]);
      }
    }

    _numberOfVertices += vertexCounter;
  }
}