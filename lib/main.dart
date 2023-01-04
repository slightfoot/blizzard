import 'package:blizzard/blizzard.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

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
  @override
  Widget build(BuildContext context) {
    return SnowBlizzard(vsync: this);
  }
}

class SnowBlizzard extends SingleChildRenderObjectWidget {
  const SnowBlizzard({
    super.key,
    super.child,
    required this.vsync,
  });

  final TickerProvider vsync;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderSnowBlizzard(vsync: vsync);
  }

  @override
  void updateRenderObject(BuildContext context, covariant RenderSnowBlizzard renderObject) {
    renderObject.vsync = vsync;
  }
}

class RenderSnowBlizzard extends RenderProxyBox {
  RenderSnowBlizzard({
    required TickerProvider vsync,
  }) : _vsync = vsync;

  final blizzard = Blizzard();
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
    _elapsed = elapsed;
    markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    super.paint(context, offset);

    final canvas = context.canvas;

    blizzard.debugEnabled = debugPaintSizeEnabled;

    if (debugPaintSizeEnabled) {
      canvas.save();
      canvas.translate(size.width * 0.25, size.height * 0.25);
      canvas.scale(0.5, 0.5);
      final border = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10.0
        ..color = Colors.cyanAccent;
      canvas.drawRect(offset & size, border);
    }

    final elapsedSeconds = _elapsed.inMicroseconds / Duration.microsecondsPerSecond;
    blizzard.paint(canvas, size, elapsedSeconds);

    if (debugPaintSizeEnabled) {
      canvas.restore();
    }
  }
}
