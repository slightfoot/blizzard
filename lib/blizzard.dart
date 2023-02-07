import 'dart:ui' as ui;

import 'package:vector_math/vector_math_64.dart' hide Triangle;

const uiWhite = ui.Color(0xFFFFFFFF);

final forward = Vector3(0.0, 0.0, 1.0);
final up = Vector3(0.0, 1.0, 0.0);
final right = Vector3(1.0, 0.0, 0.0);
final one = Vector3(1.0, 1.0, 1.0);
final center = Vector3(0.5, 0.5, 0.5);

class Blizzard {
  Blizzard() {
    camera.updateProjectionMatrix(1.0);
  }

  final _renderer = Renderer();
  ui.Size? lastSize;
  bool debugEnabled = false;

  Camera get camera => _renderer.scene.camera;

  void setup() {
    _renderer.scene.meshes.addAll([
      Mesh.forDemoQuad(Vector3(-0.5, 0.5, 0.0), Vector3(0.5, 0.5, 1.0)),
      Mesh.forDemoQuad(Vector3(-0.5, 0.5, 0.0), Vector3(-0.5, -0.5, 1.0)),
    ]);
  }

  void paint(ui.Canvas canvas, ui.Size size, double elapsedSeconds) {
    if (lastSize != size) {
      camera.updateProjectionMatrix(size.aspectRatio);
      lastSize = size;
    }
    _renderer.render();
    _renderer.paint(canvas, size);
  }
}

extension DrawString on ui.Canvas {
  void drawText(String text, ui.Offset offset, ui.TextStyle textStyle, {ui.TextAlign? textAlign}) {
    textStyle;
    final paragraphBuilder = ui.ParagraphBuilder(ui.ParagraphStyle(
      textAlign: textAlign ?? ui.TextAlign.left,
      textDirection: ui.TextDirection.ltr,
    ));
    paragraphBuilder.pushStyle(textStyle);
    paragraphBuilder.addText(text);
    final paragraph = paragraphBuilder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: double.infinity));
    drawParagraph(paragraph, offset);
  }
}

class Renderer {
  Renderer();

  final _scene = Scene(Camera());
  final triangles = <Triangle>[];

  Scene get scene => _scene;

  Matrix4 get viewProjection => _scene.camera.computeTransform();

  void render() {
    triangles.clear();
    _scene.render(this);
  }

  void paint(ui.Canvas canvas, ui.Size size) {
    if (triangles.isEmpty) {
      return;
    }

    final offsets = <ui.Offset>[];
    //final indices = <int>[];
    final colors = <ui.Color>[];

    final screenSpaceTransform = makeScreenSpaceMatrix(size.width / 2.0, size.height / 2.0);

    for (final triangle in triangles) {
      final v1 = triangle.v1.transform(screenSpaceTransform).perspectiveDivide();
      final v2 = triangle.v2.transform(screenSpaceTransform).perspectiveDivide();
      final v3 = triangle.v3.transform(screenSpaceTransform).perspectiveDivide();
      offsets.add(ui.Offset(v1.x, v1.y));
      offsets.add(ui.Offset(v2.x, v2.y));
      offsets.add(ui.Offset(v3.x, v3.y));
      colors.add(v1.color);
      colors.add(v2.color);
      colors.add(v3.color);
    }

    canvas.drawVertices(
      ui.Vertices(
        ui.VertexMode.triangles,
        offsets,
        //indices: indices,
        colors: colors,
      ),
      ui.BlendMode.dst,
      ui.Paint(),
    );

    canvas.drawPoints(
      ui.PointMode.lines,
      [
        for (var i = 0; i < offsets.length; i += 3) ...[
          // Line 1
          offsets[i + 0],
          offsets[i + 1],
          // Line 2
          offsets[i + 1],
          offsets[i + 2],
          // Line 3
          offsets[i + 2],
          offsets[i + 0],
        ],
      ],
      ui.Paint()
        ..color = uiWhite
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    canvas.drawPoints(
      ui.PointMode.points,
      offsets,
      ui.Paint()
        ..color = uiWhite
        ..strokeWidth = 6.0,
    );
  }

  Matrix4 makeScreenSpaceMatrix(double halfWidth, double halfHeight) {
    return Matrix4.identity()
      ..setEntry(0, 0, halfWidth)
      ..setEntry(0, 3, halfWidth - 0.5)
      ..setEntry(1, 1, -halfHeight)
      ..setEntry(1, 3, halfHeight - 0.5);
  }

  void renderTriangle(Vertex v1, Vertex v2, Vertex v3) {
    if (v1.isInsideFrustum() && v2.isInsideFrustum() && v3.isInsideFrustum()) {
      triangles.add(Triangle(v1, v2, v3));
      return;
    }
    final vertices = [v1, v2, v3];
    if (_clipPolygonAxis(vertices, 0) &&
        _clipPolygonAxis(vertices, 1) &&
        _clipPolygonAxis(vertices, 2)) {
      final initialVertex = vertices[0];
      for (var i = 1; i < vertices.length - 1; i++) {
        triangles.add(Triangle(
          initialVertex,
          vertices[i],
          vertices[i + 1],
        ));
      }
    }
  }

  bool _clipPolygonAxis(List<Vertex> vertices, int compIndex) {
    final clipVertices = <Vertex>[];
    _clipPolygonComp(vertices, compIndex, 1.0, clipVertices);
    vertices.clear();
    if (clipVertices.isEmpty) {
      return false;
    }
    _clipPolygonComp(clipVertices, compIndex, -1.0, vertices);
    return vertices.isNotEmpty;
  }

  void _clipPolygonComp(
      List<Vertex> vertices, int compIndex, double compFactor, List<Vertex> result) {
    var prevVertex = vertices.last;
    var prevComp = prevVertex[compIndex] * compFactor;
    var prevInside = prevComp <= prevVertex.position.w;
    for (final currVertex in vertices) {
      double currComp = currVertex[compIndex] * compFactor;
      bool currentInside = currComp <= currVertex.position.w;
      if (currentInside ^ prevInside) {
        double overlap = prevVertex.position.w - prevComp;
        double lerpAmount = overlap / (overlap - (currVertex.position.w - currComp));
        result.add(prevVertex.lerp(currVertex, lerpAmount));
      }
      if (currentInside) {
        result.add(currVertex);
      }
      prevVertex = currVertex;
      prevComp = currComp;
      prevInside = currentInside;
    }
  }
}

class Triangle {
  Triangle(this.v1, this.v2, this.v3);

  final Vertex v1;
  final Vertex v2;
  final Vertex v3;
}

class Camera {
  Camera();

  Matrix4 projection = Matrix4.zero();
  Vector3 cameraPosition = Vector3(0.0, 0.0, -1.5);
  Quaternion cameraRotation = Quaternion.euler(0.0, 0.0, 0.0);
  double angle = 0.0;

  void moveForward(double delta) {
    cameraPosition += cameraRotation.rotated(forward * delta);
  }

  void moveBackwards(double delta) {
    cameraPosition -= cameraRotation.rotated(forward * delta);
  }

  void moveLeft(double delta) {
    //cameraPosition -= right * delta;
    angle = (angle - (360.0 * delta * 0.5)) % 360.0;
    cameraRotation = Quaternion.euler(radians(angle), 0.0, 0.0);
  }

  void moveRight(double delta) {
    //cameraPosition += right * delta;
    angle = (angle + (360.0 * delta * 0.5)) % 360.0;
    cameraRotation = Quaternion.euler(radians(angle), 0.0, 0.0);
  }

  void updateProjectionMatrix(double aspectRatio) {
    setPerspectiveMatrix(projection, radians(45.0), aspectRatio, 0.01, 100.0);
  }

  Matrix4 makeCameraMatrix() {
    final lookAt = cameraPosition + cameraRotation.rotated(forward);
    return makeViewMatrix(cameraPosition, lookAt, up);
  }

  Matrix4 computeTransform() {
    return projection * makeCameraMatrix();
  }
}

class Scene {
  Scene(this.camera);

  final Camera camera;
  final meshes = <Mesh>[];

  void render(Renderer renderer) {
    final identity = Matrix4.identity();
    for (int i = 0; i < meshes.length; i++) {
      meshes[i].render(renderer, identity);
    }
  }
}

class Mesh {
  Mesh._(this.vertices, this.indices);

  final List<Vertex> vertices;
  final List<int> indices;

  factory Mesh.forDemoQuad(Vector3 min, Vector3 max) {
    return Mesh._(
      List.unmodifiable(<Vertex>[
        Vertex(Vector4(min.x, min.y, min.z, 1.0), const ui.Color(0xFFFF0000)),
        Vertex(Vector4(min.x, min.y, max.z, 1.0), const ui.Color(0xFF00FF00)),
        Vertex(Vector4(max.x, max.y, max.z, 1.0), const ui.Color(0xFF0000FF)),
        Vertex(Vector4(max.x, max.y, min.z, 1.0), const ui.Color(0xFFFFFF00)),
      ]),
      List.unmodifiable(<int>[0, 1, 2, 0, 3, 2]),
    );
  }

  void render(Renderer renderer, Matrix4 transform) {
    final mvp = renderer.viewProjection.multiplied(transform);
    for (int i = 0; i < indices.length; i += 3) {
      renderer.renderTriangle(
        vertices[indices[i + 0]].transform(mvp),
        vertices[indices[i + 1]].transform(mvp),
        vertices[indices[i + 2]].transform(mvp),
      );
    }
  }
}

class Vertex {
  Vertex(this._position, this._color);

  final Vector4 _position;
  final ui.Color _color;

  Vector4 get position => _position;

  ui.Color get color => _color;

  double get x => _position.x;

  double get y => _position.y;

  double get z => _position.z;

  double get w => _position.w;

  Vertex transform(Matrix4 transform) {
    return Vertex(transform.transformed(_position), _color);
  }

  Vertex perspectiveDivide() {
    return Vertex(Vector4(x / w, y / w, z / w, w), _color);
  }

  Vertex lerp(Vertex other, double amount) {
    return Vertex(
      other._position.clone()
        ..sub(_position)
        ..scale(amount)
        ..add(_position),
      ui.Color.lerp(_color, other._color, amount)!,
    );
  }

  bool isInsideFrustum() {
    return x.abs() <= w.abs() && y.abs() <= w.abs() && z.abs() <= w.abs();
  }

  double operator [](int i) => _position[i];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Vertex &&
          runtimeType == other.runtimeType &&
          _position == other._position &&
          _color == other._color;

  @override
  int get hashCode => Object.hash(_position.hashCode, _color.hashCode);
}
