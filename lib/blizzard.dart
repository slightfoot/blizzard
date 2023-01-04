import 'dart:math';
import 'dart:ui' as ui;

import 'package:vector_math/vector_math_64.dart';

const uiWhite = ui.Color(0xFFFFFFFF);

final forward = Vector3(0.0, 0.0, -1.0);
final up = Vector3(0.0, 1.0, 0.0);
final center = Vector3(0.5, 0.5, 0.5);

class Blizzard {
  Blizzard() {
    projection = makePerspectiveMatrix(radians(90.0), 1.0, 0.1, 100.0);
    cameraPosition = Vector3(0.0, 0.0, -1.0);
    cameraRotation = Quaternion.euler(0.0, 0.0, 0.0);
  }

  late Matrix4 projection;
  late Vector3 cameraPosition;
  late Quaternion cameraRotation;

  bool debugEnabled = false;

  void moveForward(double delta) {
    cameraPosition -= forward * delta;
  }

  void moveBackwards(double delta) {
    cameraPosition += forward * delta;
  }

  Matrix4 makeCameraMatrix() {
    final lookAt = cameraPosition + cameraRotation.rotated(forward);
    return makeViewMatrix(cameraPosition, lookAt, up);
  }

  void paint(ui.Canvas canvas, ui.Size size, double elapsedSeconds) {
    final random = Random(1);
    double range(double min, double max) {
      return min + ((max - min) * random.nextDouble());
    }

    const minSpeed = 3.0;
    const maxSpeed = 10.0;

    canvas.save();
    canvas.scale(size.width * 0.5, size.height * 0.5);
    canvas.translate(1.0, 1.0);
    canvas.scale(1.0, -1.0);

    final viewMatrix = makeCameraMatrix();
    final paint = ui.Paint()..color = uiWhite;
    for (int i = 0; i < 600; i++) {
      final origin = Vector3(
            random.nextDouble() * 5.0,
            random.nextDouble(),
            random.nextDouble() * 10.0,
          ) -
          Vector3(2.5, 0.5, 0.0);

      final speed = range(minSpeed, maxSpeed);
      final waves = range(5, 10);
      final amp = range(0.01, 0.004) * speed;
      final y = ((origin.y + (elapsedSeconds / speed)) % 1.0) - 0.5;
      final x = origin.x + sin(y * pi * waves) * amp;

      final animated = Vector3(x, y, origin.z);

      final pos = projection.perspectiveTransform(viewMatrix.transform3(animated));

      final distance = (pos.z - 1.0);

      //paint.color = ui.Color.fromRGBO(
      //  0xFF,
      //  0xFF,
      //  0xFF,
      //  (distance * 3.0).clamp(0.0, 1.0),
      //);
      canvas.drawCircle(ui.Offset(pos.x, pos.y), distance * 0.05, paint);
    }

    canvas.restore();
  }
}
