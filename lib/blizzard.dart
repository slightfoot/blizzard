import 'dart:ui' as ui;
import 'dart:math';

import 'package:vector_math/vector_math_64.dart';

const uiWhite = ui.Color(0xFFFFFFFF);

class Blizzard {

  bool debugEnabled = false;

  void paint(ui.Canvas canvas, ui.Size size, double elapsedSeconds) {

    final random = Random(1);
    double range(double min, double max) {
      return min + ((max - min) * random.nextDouble());
    }

    Vector3 blah = Vector3.zero();

    const minSpeed = 3.0;
    const maxSpeed = 10.0;

    final paint = ui.Paint()..color = uiWhite;
    for (int i = 0; i < 200; i++) {
      final xOrigin = random.nextDouble();
      final yOrigin = random.nextDouble() * 1.5;
      final zOrigin = random.nextDouble();

      final speed = range(minSpeed, maxSpeed);
      final waves = range(5, 10);
      final amp = range(0.01, 0.004) * speed;
      final y = ((yOrigin + (elapsedSeconds / speed)) % 1.5) - 0.25;
      final x = xOrigin + sin(y * pi * waves) * amp;
      final z = zOrigin + cos(y * pi * waves) * amp;

      canvas.drawCircle(
        ui.Offset(x * size.width, y * size.height),
        3.0 + ((maxSpeed - speed) * 1.5),
        paint,
      );
    }
  }
}
