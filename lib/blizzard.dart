import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:vector_math/vector_math_64.dart';

const uiWhite = ui.Color(0xFFFFFFFF);

final forward = Vector3(0.0, 0.0, 1.0);
final up = Vector3(0.0, 1.0, 0.0);
final right = Vector3(1.0, 0.0, 0.0);
final one = Vector3(1.0, 1.0, 1.0);
final center = Vector3(0.5, 0.5, 0.5);

class Blizzard {
  Blizzard() {
    updateProjectionMatrix(1.0);
  }

  Matrix4 projection = Matrix4.zero();
  Vector3 cameraPosition = Vector3(0.0, 0.0, -1.5);
  Quaternion cameraRotation = Quaternion.euler(0.0, 0.0, 0.0);

  ui.Size? lastSize;
  double angle = 0.0;
  bool debugEnabled = false;

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

  void paint(ui.Canvas canvas, ui.Size size, double elapsedSeconds) {
    final random = math.Random(1);
    double range(double min, double max) {
      return min + ((max - min) * random.nextDouble());
    }

    const minSpeed = 3.0;
    const maxSpeed = 10.0;

    if (lastSize != size) {
      updateProjectionMatrix(size.aspectRatio);
      lastSize = size;
    }

    final viewMatrix = makeCameraMatrix();

    final paint = ui.Paint()..color = uiWhite;
    int clip = 0;
    // for (int i = 0; i < 400; i++) {
    //   final origin = Vector3(
    //         random.nextDouble() * 1.0,
    //         random.nextDouble() * 1.0,
    //         random.nextDouble() * 1.0,
    //       ) -
    //       one * 0.5;
//
    //   final speed = range(minSpeed, maxSpeed);
    //   final waves = range(5, 10);
    //   final amp = range(0.01, 0.004) * speed;
    //   final y = ((origin.y + (elapsedSeconds / speed)) % 1.0) - 0.5;
    //   final x = origin.x + math.sin(y * math.pi * waves) * amp;
//
    //   final animated = viewMatrix.transformed(Vector4(x, y, origin.z, 1.0));
    //   var pos = projection.transformed(animated);
    //   pos.xyz /= pos.w;
    //   if (pos.z > pos.w && pos.z <= pos.w) {
    //     clip++;
    //     continue;
    //   }
//
    //   final distance = 0.5; //(animated.z;
    //   // print('distance: ${distance}');
    //   // final opacity = flutter.Curves.easeInCubic //
    //   //     .transform((distance * 4.0).clamp(0.0, 1.0));
    //   // paint.color = ui.Color.fromRGBO(0xFF, 0xFF, 0xFF, opacity);
    //   canvas.drawCircle(ui.Offset(pos.x, pos.y), distance * 0.015, paint);
    // }
    // print('clipped $clip');

    // void drawTestQuad1(Vector3 min, Vector3 max) {
    //   final positions = <Vector3>[
    //     Vector3(min.x, min.y, min.z),
    //     Vector3(min.x, min.y, max.z),
    //     Vector3(max.x, max.y, max.z),
    //     Vector3(max.x, max.y, min.z),
    //   ];

    //   final offsets = positions
    //       .map((Vector3 p) {
    //         final v = viewMatrix.transformed3(p);
    //         return projection.perspectiveTransform(v.clone());
    //       })
    //       .map((v) => (v * 0.5) + Vector3(0.5, 0.5, 0.0))
    //       .map((v) => ui.Offset(v.x * size.width, v.y * size.height))
    //       .toList();

    //   final indices = <int>[0, 1, 2, 2, 3, 0];

    //   final paint = ui.Paint()..color = uiWhite;
    //   canvas.drawVertices(
    //     ui.Vertices(
    //       ui.VertexMode.triangles,
    //       offsets,
    //       indices: indices,
    //       colors: [
    //         flutter.Colors.red,
    //         flutter.Colors.green,
    //         flutter.Colors.blue,
    //         flutter.Colors.yellow,
    //       ],
    //     ),
    //     ui.BlendMode.src,
    //     paint,
    //   );
    //   canvas.drawPoints(
    //     ui.PointMode.lines,
    //     [
    //       for (var i = 0; i < indices.length; i += 3) ...[
    //         offsets[indices[i + 0]],
    //         offsets[indices[i + 1]],
    //         offsets[indices[i + 1]],
    //         offsets[indices[i + 2]],
    //         offsets[indices[i + 2]],
    //         offsets[indices[i + 0]],
    //       ],
    //     ],
    //     paint
    //       ..style = ui.PaintingStyle.stroke
    //       ..strokeWidth = 0.002,
    //   );
    // }

    void drawTestQuad2(Vector3 min, Vector3 max, ui.Offset offset) {
      final positions = <Vector3>[
        Vector3(min.x, min.y, min.z),
        Vector3(min.x, min.y, max.z),
        Vector3(max.x, max.y, max.z),
        Vector3(max.x, max.y, min.z),
      ];

      final viewCamera = positions
          .map((Vector3 v) => viewMatrix.transformed(Vector4(v.x, v.y, v.z, 1.0)))
          .toList();
      final clipSpace = viewCamera.map((Vector4 v) => projection.transformed(v)).toList();
      final ndcSpace = clipSpace.map((Vector4 v) {
        final q = v.clone();
        q.xyz /= v.w;
        //q.w = 1 / v.w;
        return q;
      }).toList();

      // for(int i = 0; i < ndcSpace.length; i++) {
      //   final v = ndcSpace[i];
      //   if(v.x <= -v.w || v.x >= v.w) {
      //     print("x:${v.x} w:${v.w}");
      //   }
      //   if(v.y <= -v.w || v.y >= v.w) {
      //     print("y:${v.y} w:${v.w}");
      //   }
      //   if(v.z <= -v.w || v.z >= v.w) {
      //     print("z:${v.z} w:${v.w}");
      //   }
      // }

      final screenSpace = ndcSpace.map((Vector4 v) {
        return Vector4(
          size.width * ((v.x + 1.0) / 2.0),
          -size.height * ((v.y - 1.0) / 2.0),
          ((v.z + 1.0) / 2.0),
          v.w,
        );
      }).toList();

      // final offsets = positions
      //     .map((Vector3 p) {
      //       final v = viewMatrix.transformed(Vector4(p.x, p.y, p.z, 1.0));
      //       var pos = projection.transformed(v);
      //       pos.xyz /= pos.w;
      //       // pos.w = 1 / pos.w;
      //       // var pos = projection.perspectiveTransform(v.xyz);
      //       return pos;
      //     })
      //     // -1 - +1  = 2.0;
      //     //.where((el) =>
      //     //    (el.x.abs() <= el.w.abs()) &&
      //     //    (el.y.abs() <= el.w.abs()) &&
      //     //    (el.z.abs() <= el.w.abs()))
      //     .map((v) => (v + Vector4(1.0, 1.0, 0.0, 0.0)) * 0.5)
      //     .map((v) => ui.Offset(v.x * size.width, v.y * size.height))
      //     .toList();

      final indices = <int>[0, 1, 2, 0, 3, 2];

      final offsets = screenSpace.map((Vector4 v) => ui.Offset(v.x, v.y)).toList();
      canvas.drawVertices(
        ui.Vertices(
          ui.VertexMode.triangles,
          offsets,
          indices: indices,
          colors: const [
            ui.Color(0xFFFF0000),
            ui.Color(0xFF00FF00),
            ui.Color(0xFF0000FF),
            ui.Color(0xFFFFFF00),
          ].sublist(0, offsets.length),
        ),
        ui.BlendMode.dst,
        ui.Paint(),
      );

      canvas.drawPoints(
        ui.PointMode.lines,
        [
          for (var i = 0; i < indices.length; i += 3) ...[
            // Line 1
            offsets[indices[i + 0]],
            offsets[indices[i + 1]],
            // Line 2
            offsets[indices[i + 1]],
            offsets[indices[i + 2]],
            // Line 3
            offsets[indices[i + 2]],
            offsets[indices[i + 0]],
          ],
        ],
        ui.Paint()
          ..color = uiWhite
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );

      canvas.drawPoints(
        ui.PointMode.points,
        [
          for (var i = 0; i < indices.length; i++) //
            offsets[indices[i]],
        ],
        ui.Paint()
          ..color = uiWhite
          ..strokeWidth = 6.0,
      );

      String listVectors(List<Vector4> v) {
        return v.map((el) {
          return "[${el.x.toStringAsFixed(3)}, ${el.y.toStringAsFixed(3)}, "
              "${el.z.toStringAsFixed(3)}, ${el.w.toStringAsFixed(3)}]";
        }).join(", ");
      }

      // canvas.drawText(
      //   "${listVectors(viewCamera)}\n${listVectors(clipSpace)}\n"
      //   "${listVectors(ndcSpace)}\n${listVectors(screenSpace)}",
      //   const ui.Offset(8.0, 4.0) + offset,
      //   ui.TextStyle(fontSize: 16.0),
      // );
    }

    //drawTestQuad1(Vector3(-0.5, 0.5, 0.0), Vector3(0.5, 0.5, 1.0));
    //drawTestQuad1(Vector3(-0.5, 0.5, 0.0), Vector3(-0.5, -0.5, 1.0));
    drawTestQuad2(Vector3(-0.5, 0.5, 0.0), Vector3(0.5, 0.5, 1.0), ui.Offset.zero);
    drawTestQuad2(Vector3(-0.5, 0.5, 0.0), Vector3(-0.5, -0.5, 1.0), ui.Offset(0.0, 350.0));

    // canvas.restore();
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
  }
}
