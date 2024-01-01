import 'package:blizzard/blizzard.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const BlizzardApp());
}

class BlizzardApp extends StatelessWidget {
  const BlizzardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Snow Blizzard',
      theme: ThemeData.dark(),
      home: const HomeScreen(),
    );
  }
}

@immutable
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final inputManager = InputManager();

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: inputManager.onKeyEvent,
      child: SizedBox.expand(
        child: SnowBlizzard(
          inputManager: inputManager,
          vsync: this,
        ),
      ),
    );
  }
}

class SnowBlizzard extends LeafRenderObjectWidget {
  const SnowBlizzard({
    super.key,
    required this.inputManager,
    required this.vsync,
  });

  final InputManager inputManager;
  final TickerProvider vsync;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderSnowBlizzard(inputManager: inputManager, vsync: vsync);
  }

  @override
  void updateRenderObject(BuildContext context, covariant RenderSnowBlizzard renderObject) {
    renderObject
      ..inputManager = inputManager
      ..vsync = vsync;
  }
}

class RenderSnowBlizzard extends RenderProxyBox {
  RenderSnowBlizzard({
    required InputManager inputManager,
    required TickerProvider vsync,
  })  : _inputManager = inputManager,
        _vsync = vsync {
    blizzard.setup();
  }

  final blizzard = Blizzard();

  late InputManager _inputManager;

  InputManager get inputManager => _inputManager;

  set inputManager(InputManager value) {
    _inputManager = inputManager;
  }

  late Ticker _ticker;

  TickerProvider? _vsync;

  TickerProvider get vsync => _vsync!;

  set vsync(TickerProvider value) {
    if (_vsync != value) {
      if (attached) {
        _ticker.stop();
      }
      _vsync = value;
      if (attached) {
        _ticker = vsync.createTicker(_onTick);
        _ticker.start();
      }
    }
  }

  @override
  void attach(covariant PipelineOwner owner) {
    super.attach(owner);
    _ticker = vsync.createTicker(_onTick);
    _ticker.start();
  }

  @override
  void detach() {
    _ticker.stop();
    super.detach();
  }

  Duration _elapsed = Duration.zero;

  void _onTick(Duration elapsed) {
    final elapsedDelta = (elapsed - _elapsed).inMicroseconds / Duration.microsecondsPerSecond;
    if (inputManager.moveForwards) {
      blizzard.camera.moveForward(elapsedDelta);
    } else if (inputManager.moveBackwards) {
      blizzard.camera.moveBackwards(elapsedDelta);
    }
    if (inputManager.moveLeft) {
      blizzard.camera.moveLeft(elapsedDelta);
    } else if (inputManager.moveRight) {
      blizzard.camera.moveRight(elapsedDelta);
    }
    _elapsed = elapsed;
    markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    super.paint(context, offset);

    final canvas = context.canvas;

    // Paint our background black
    canvas.drawRect(offset & size, Paint()..color = Colors.black);

    blizzard.debugEnabled = debugPaintSizeEnabled;

    if (debugPaintSizeEnabled) {
      canvas.save();
      canvas.translate(size.width * 0.125, size.height * 0.125);
      canvas.scale(0.75, 0.75);
    }

    final elapsedSeconds = _elapsed.inMicroseconds / Duration.microsecondsPerSecond;
    blizzard.paint(canvas, size, elapsedSeconds);

    if (debugPaintSizeEnabled) {
      final border = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..color = Colors.cyanAccent;
      canvas.drawRect(offset & size, border);
      canvas.restore();
    }
  }

  @override
  bool hitTestSelf(Offset position) => true;
}

class InputManager {
  InputManager();

  bool moveForwards = false;
  bool moveBackwards = false;
  bool moveLeft = false;
  bool moveRight = false;

  KeyEventResult onKeyEvent(FocusNode node, KeyEvent event) {
    final isPressed = event is! KeyUpEvent;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.keyW:
        moveForwards = isPressed;
      case LogicalKeyboardKey.keyS:
        moveBackwards = isPressed;
      case LogicalKeyboardKey.keyA:
        moveLeft = isPressed;
      case LogicalKeyboardKey.keyD:
        moveRight = isPressed;
      default:
        return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }
}
