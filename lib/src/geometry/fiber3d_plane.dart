class Fiber3DPlane {
  final double width;
  final double height;
  final int widthSegments;
  final int heightSegments;

  final List<double> positions = [];
  final List<double> normals = [];
  final List<double> uvs = [];
  final List<int> indices = [];

  Fiber3DPlane({
    this.width = 1,
    this.height = 1,
    this.widthSegments = 1,
    this.heightSegments = 1,
  }) {
    _build();
  }

  void _build() {
    final widthHalf = width / 2;
    final heightHalf = height / 2;

    final gridX = widthSegments;
    final gridY = heightSegments;

    final gridX1 = gridX + 1;
    final gridY1 = gridY + 1;

    final segmentWidth = width / gridX;
    final segmentHeight = height / gridY;

    for (var iy = 0; iy < gridY1; iy++) {
      final y = iy * segmentHeight - heightHalf;

      for (var ix = 0; ix < gridX1; ix++) {
        final x = ix * segmentWidth - widthHalf;

        positions.addAll([x, -y, 0]);
        normals.addAll([0, 0, 1]);

        uvs.add(ix / gridX);
        uvs.add(1 - (iy / gridY));
      }
    }

    for (var iy = 0; iy < gridY; iy++) {
      for (var ix = 0; ix < gridX; ix++) {
        final a = ix + gridX1 * iy;
        final b = ix + gridX1 * (iy + 1);
        final c = (ix + 1) + gridX1 * (iy + 1);
        final d = (ix + 1) + gridX1 * iy;

        indices.addAll([a, b, d]);
        indices.addAll([b, c, d]);
      }
    }
  }
}