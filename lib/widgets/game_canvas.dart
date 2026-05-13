import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../models/game_state.dart';
import '../services/sound_service.dart';

class GameCanvas extends StatefulWidget {
  final GameMode mode;

  const GameCanvas({super.key, required this.mode});

  @override
  State<GameCanvas> createState() => _GameCanvasState();
}

class _GameCanvasState extends State<GameCanvas>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Offset _touchPosition = Offset.zero;
  bool _isTouching = false;

  // Accelerometer data
  double _accelX = 0;
  double _accelY = 0;
  StreamSubscription? _accelSubscription;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // Sensors only work on Mobile/Web
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      _accelSubscription = accelerometerEventStream().listen((
        AccelerometerEvent event,
      ) {
        if (mounted) {
          setState(() {
            _accelX = event.x;
            _accelY = event.y;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _accelSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanDown: (details) => _handleTouch(details.localPosition),
      onPanUpdate: (details) => _handleTouch(details.localPosition),
      onPanEnd: (_) => setState(() => _isTouching = false),
      onTapDown: (details) => _handleTouch(details.localPosition),
      onTapUp: (_) => setState(() => _isTouching = false),
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(painter: _getPainter(), size: Size.infinite);
          },
        ),
      ),
    );
  }

  void _handleTouch(Offset pos) {
    setState(() {
      _touchPosition = pos;
      _isTouching = true;
    });

    // Trigger specific game interactions on initial tap
    _triggerInteraction(pos);
  }

  void _triggerInteraction(Offset pos) {
    switch (widget.mode) {
      case GameMode.underTheRug:
        UnderTheRugPainter.handleTap(pos);
        break;
      case GameMode.bugSwarm:
        BugSwarmPainter.handleTap(pos);
        break;
      case GameMode.laserPath:
        LaserPathPainter.handleTap(pos);
        break;
      case GameMode.pondSkater:
        PondSkaterPainter.handleTap(pos);
        break;
      case GameMode.stringFeather:
        StringFeatherPainter.handleTap(pos);
        break;
      case GameMode.whackAMouse:
        WhackAMousePainter.handleTap(pos);
        break;
      case GameMode.fishTank:
        FishTankPainter.handleTap(pos);
        break;
    }
  }

  CustomPainter _getPainter() {
    switch (widget.mode) {
      case GameMode.underTheRug:
        return UnderTheRugPainter(
          _touchPosition,
          _isTouching,
          _controller.value,
        );
      case GameMode.bugSwarm:
        return BugSwarmPainter(_touchPosition, _isTouching, _controller.value);
      case GameMode.laserPath:
        return LaserPathPainter(_touchPosition, _isTouching, _controller.value);
      case GameMode.pondSkater:
        return PondSkaterPainter(
          _touchPosition,
          _isTouching,
          _controller.value,
        );
      case GameMode.stringFeather:
        return StringFeatherPainter(
          _touchPosition,
          _isTouching,
          _controller.value,
          _accelX,
          _accelY,
        );
      case GameMode.whackAMouse:
        return WhackAMousePainter(_touchPosition, _isTouching, _controller.value);
      case GameMode.fishTank:
        return FishTankPainter(_touchPosition, _isTouching, _controller.value);
    }
    // Fallback to prevent null return
    return UnderTheRugPainter(_touchPosition, _isTouching, _controller.value);
  }
}

// --- SHARED CLASSES ---

class Particle {
  Offset pos;
  Offset vel;
  Color color;
  double life = 1.0;
  Particle(this.pos, this.vel, this.color);

  void update() {
    pos += vel;
    life -= 0.02;
  }
}

class Ripple {
  Offset pos;
  double radius = 0;
  double life = 1.0;

  Ripple(this.pos);

  void update() {
    radius += 4;
    life -= 0.02;
  }
}

// --- PAINTERS ---

class UnderTheRugPainter extends CustomPainter {
  final Offset touch;
  final bool isTouching;
  final double time;

  static Offset bumpPos = const Offset(200, 400);
  static Offset targetPos = const Offset(200, 400);
  static double pokeState = 0;
  static double peekState = 0; // Mouse peeking out
  static double movementPhase = 0; // for erratic movement
  static List<Offset> tailSegments = List.generate(12, (_) => const Offset(200, 400));

  UnderTheRugPainter(this.touch, this.isTouching, this.time);

  static void handleTap(Offset pos) {
    if ((pos - bumpPos).distance < 80) {
      peekState = 1.0;
      // Scared dart
      final corners = [
        const Offset(100, 100),
        const Offset(300, 100),
        const Offset(100, 700),
        const Offset(300, 700),
      ];
      targetPos = corners[math.Random().nextInt(4)];
      SoundService().playSqueak();
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rugColor = const Color(0xFF06402B); // Deep Forest Green

    // 1. Base Rug Color
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = rugColor,
    );

    // 2. Movement Calculations
    movementPhase += 0.025;
    if (math.Random().nextDouble() > 0.98 &&
        (bumpPos - targetPos).distance < 15) {
      targetPos = Offset(
        80 + math.Random().nextDouble() * (size.width - 160),
        120 + math.Random().nextDouble() * (size.height - 240),
      );
    }
    double speed = (math.sin(movementPhase * 6).abs() > 0.6) ? 0.2 : 0.03;
    bumpPos = Offset.lerp(bumpPos, targetPos, speed)!;

    // 3. Volumetric Bulge Lighting (Under the texture)
    final bulgeHighlight = Paint()
      ..shader = RadialGradient(
        colors: [
          Color.lerp(rugColor, Colors.white, 0.25)!,
          rugColor,
        ],
        stops: const [0.0, 0.8],
      ).createShader(Rect.fromCircle(center: bumpPos, radius: 65));
    canvas.drawCircle(bumpPos, 65, bulgeHighlight);

    // 4. Warped Weave Pattern (Flows over the bump)
    final weavePaint = Paint()
      ..color = Colors.black.withOpacity(0.12)
      ..strokeWidth = 1.0;

    // Vertical lines with warping
    for (double x = 0; x < size.width; x += 8) {
      final path = Path();
      path.moveTo(x, 0);
      for (double y = 0; y < size.height; y += 20) {
        double dx = 0;
        final dist = (Offset(x, y) - bumpPos).distance;
        if (dist < 80) {
          final power = (1.0 - dist / 80);
          dx = (x - bumpPos.dx) * power * 0.4;
        }
        path.lineTo(x + dx, y);
      }
      path.lineTo(x, size.height);
      canvas.drawPath(path, weavePaint..style = PaintingStyle.stroke);
    }

    // Horizontal lines with warping
    for (double y = 0; y < size.height; y += 8) {
      final path = Path();
      path.moveTo(0, y);
      for (double x = 0; x < size.width; x += 20) {
        double dy = 0;
        final dist = (Offset(x, y) - bumpPos).distance;
        if (dist < 80) {
          final power = (1.0 - dist / 80);
          dy = (y - bumpPos.dy) * power * 0.4;
        }
        path.lineTo(x, y + dy);
      }
      path.lineTo(size.width, y);
      canvas.drawPath(path, weavePaint..style = PaintingStyle.stroke);
    }

    // 5. Creases and Folds
    final creasePaint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    for (int i = 0; i < 4; i++) {
      final angle = (time * 0.5 + i) * 1.5;
      canvas.drawArc(
        Rect.fromCircle(center: bumpPos, radius: 68),
        angle,
        0.5,
        false,
        creasePaint,
      );
    }

    // 6. Surface Lint (Over everything for depth)
    final random = math.Random(123);
    for (int i = 0; i < 150; i++) {
      final p = Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height,
      );
      double dx = 0, dy = 0;
      final dist = (p - bumpPos).distance;
      if (dist < 70) {
        final power = (1.0 - dist / 70);
        dx = (p.dx - bumpPos.dx) * power * 0.3;
        dy = (p.dy - bumpPos.dy) * power * 0.3;
      }
      canvas.drawCircle(
        p + Offset(dx, dy),
        1.0,
        Paint()..color = Colors.white.withOpacity(0.06),
      );
    }

    // 7. Fringes
    final fringePaint = Paint()
      ..color = const Color(0xFF7CB342) // Sage/Lime Fringe
      ..strokeWidth = 1.5;
    for (double i = 0; i < size.width; i += 3) {
      final h = 12.0 + math.sin(i + time) * 3;
      canvas.drawLine(Offset(i, 0), Offset(i, h), fringePaint);
      canvas.drawLine(
        Offset(i, size.height),
        Offset(i, size.height - h),
        fringePaint,
      );
    }

    // 8. BIG Peek-a-boo Mouse
    if (peekState > 0) {
      peekState -= 0.025;
      final mousePos =
          bumpPos + Offset(math.cos(time * 3) * 30, -60 * peekState);
      final mousePaint = Paint()..color = Colors.grey[700]!;
      canvas.drawCircle(mousePos, 30, mousePaint);
      canvas.drawCircle(mousePos + const Offset(-25, -20), 18, mousePaint);
      canvas.drawCircle(mousePos + const Offset(25, -20), 18, mousePaint);
      canvas.drawCircle(
        mousePos + const Offset(-10, -8),
        5,
        Paint()..color = Colors.black,
      );
      canvas.drawCircle(
        mousePos + const Offset(10, -8),
        5,
        Paint()..color = Colors.black,
      );
      canvas.drawCircle(
        mousePos + const Offset(-12, -10),
        2,
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(
        mousePos + const Offset(8, -10),
        2,
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(
        mousePos + const Offset(0, 5),
        4,
        Paint()..color = Colors.pink[200]!,
      );
    }

    // 9. Realistic Physics Tail
    // Update segments to follow the bump
    tailSegments[0] = bumpPos;
    for (int i = 1; i < tailSegments.length; i++) {
      final target = tailSegments[i - 1];
      final current = tailSegments[i];
      final dir = current - target;
      final dist = dir.distance;
      const kSegmentLen = 8.0;

      if (dist > kSegmentLen) {
        // Simple constraint: keep segments at kSegmentLen distance
        tailSegments[i] = target + (dir / dist) * kSegmentLen;
      }
      
      // Add a bit of "drift" and gravity-like pull
      tailSegments[i] += Offset(math.sin(time * 2 + i) * 0.5, 2.0 * (i / tailSegments.length));
    }

    // Draw the tail with tapering
    for (int i = 0; i < tailSegments.length - 1; i++) {
      final t = i / tailSegments.length;
      final thickness = (10.0 * (1.0 - t)).clamp(2.0, 10.0);
      canvas.drawLine(
        tailSegments[i],
        tailSegments[i + 1],
        Paint()
          ..color = const Color(0xFFAD1457) // Deep Mahogany Rose
          ..strokeWidth = thickness
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class BugSwarmPainter extends CustomPainter {
  final Offset touch;
  final bool isTouching;
  final double time;

  static List<Bug> bugs = List.generate(3, (_) => Bug());
  static List<Particle> particles = [];

  BugSwarmPainter(this.touch, this.isTouching, this.time);

  static void handleTap(Offset pos) {
    for (int i = bugs.length - 1; i >= 0; i--) {
      if ((pos - bugs[i].pos).distance < 60) {
        // Splat!
        for (int p = 0; p < 15; p++) {
          particles.add(
            Particle(
              bugs[i].pos,
              Offset(
                    math.Random().nextDouble() - 0.5,
                    math.Random().nextDouble() - 0.5,
                  ) *
                  12,
              bugs[i].color,
            ),
          );
        }
        SoundService().playSplat();
        bugs.removeAt(i);
        // Respawn later only if we have room
        Future.delayed(const Duration(seconds: 2), () {
          if (bugs.length < 3) bugs.add(Bug());
        });
        break;
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Proper Grass Texture
    final bgPaint = Paint()..color = const Color(0xFF1B5E20);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final grassPaint = Paint()..strokeWidth = 1.5;
    final random = math.Random(42); // Fixed seed for stable texture
    for (int i = 0; i < 400; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final h = 10.0 + random.nextDouble() * 15.0;
      final angle = math.sin(time + x) * 0.2;

      grassPaint.color = Color.lerp(
        const Color(0xFF2E7D32),
        const Color(0xFF1B5E20),
        random.nextDouble(),
      )!;
      canvas.drawLine(
        Offset(x, y),
        Offset(x + math.sin(angle) * h, y - math.cos(angle) * h),
        grassPaint,
      );
    }

    // 2. Update Particles
    for (int i = particles.length - 1; i >= 0; i--) {
      particles[i].update();
      if (particles[i].life <= 0) {
        particles.removeAt(i);
      } else {
        canvas.drawCircle(
          particles[i].pos,
          4,
          Paint()..color = particles[i].color.withOpacity(particles[i].life),
        );
      }
    }

    // 3. Update and Draw Diverse Bugs
    for (var bug in bugs) {
      bug.update(touch, isTouching, size);
      _drawBug(canvas, bug, time);
    }
  }

  void _drawBug(Canvas canvas, Bug bug, double time) {
    final bodyWidth = bug.size;
    final bodyHeight = bug.size * 1.4;

    canvas.save();
    canvas.translate(bug.pos.dx, bug.pos.dy);
    canvas.rotate(bug.rotation);

    // Glow/Aura for Fireflies
    if (bug.type == BugType.firefly) {
      final glowPaint = Paint()
        ..color = Colors.yellow.withOpacity(0.4 + math.sin(time * 8) * 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
      canvas.drawCircle(Offset(0, bodyHeight * 0.3), bodyWidth * 1.5, glowPaint);
    }

    final bodyPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          bug.color,
          Color.lerp(bug.color, Colors.black, 0.4)!,
        ],
        center: const Alignment(-0.3, -0.3),
      ).createShader(Rect.fromCenter(center: Offset.zero, width: bodyWidth, height: bodyHeight));

    switch (bug.type) {
      case BugType.beetle:
        // Segmented Shell
        canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: bodyWidth, height: bodyHeight), bodyPaint);
        // Wing Split
        final linePaint = Paint()..color = Colors.black.withOpacity(0.3)..strokeWidth = 2;
        canvas.drawLine( Offset(0, -bodyHeight * 0.3),  Offset(0, bodyHeight * 0.5), linePaint);
        break;

      case BugType.moth:
        // Fuzzy Wing Logic
        final wingPaint = Paint()
          ..color = bug.color.withOpacity(0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        final flap = math.sin(time * 25) * 0.5;
        
        for (int i = -1; i <= 1; i += 2) {
          canvas.save();
          canvas.scale(i.toDouble(), 1.0);
          canvas.rotate(flap);
          final wingPath = Path();
          wingPath.moveTo(2, -5);
          wingPath.quadraticBezierTo(40, -40, 50, 10);
          wingPath.quadraticBezierTo(40, 40, 2, 5);
          canvas.drawPath(wingPath, wingPaint);
          canvas.restore();
        }
        canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: bodyWidth * 0.6, height: bodyHeight), bodyPaint);
        break;

      case BugType.cockroach:
        // Tapered segmented body
        final roachPath = Path();
        roachPath.moveTo(0, -bodyHeight * 0.6);
        roachPath.quadraticBezierTo(bodyWidth * 0.6, 0, 0, bodyHeight * 0.6);
        roachPath.quadraticBezierTo(-bodyWidth * 0.6, 0, 0, -bodyHeight * 0.6);
        canvas.drawPath(roachPath, bodyPaint);
        
        // Long wavy antennas
        final antPaint = Paint()..color = Colors.black45..style = PaintingStyle.stroke..strokeWidth = 1.2;
        for (int i = -1; i <= 1; i += 2) {
           final antPath = Path();
           antPath.moveTo(i * 3, -bodyHeight * 0.5);
           antPath.quadraticBezierTo(i * 20, -bodyHeight, i * (30 + math.sin(time * 5) * 10), -bodyHeight - 30);
           canvas.drawPath(antPath, antPaint);
        }
        break;

      case BugType.firefly:
        canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: bodyWidth * 0.7, height: bodyHeight * 0.8), bodyPaint);
        // Glowing Tail Segment
        final tailGlow = Paint()..color = Colors.yellowAccent.withOpacity(0.8 + math.sin(time * 10) * 0.2)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
        canvas.drawCircle(Offset(0, bodyHeight * 0.3), bodyWidth * 0.4, tailGlow);
        break;

      case BugType.crawler:
        // Multi-segmented body
        for (int i = 0; i < 4; i++) {
          final offset = -bodyHeight * 0.4 + (i * bodyHeight * 0.25);
          canvas.drawCircle(Offset(0, offset), bodyWidth * (0.5 - i * 0.05), bodyPaint);
        }
        break;
    }

    // High Contrast Eyes with Glint
    final eyePaint = Paint()..color = Colors.white;
    final pupilPaint = Paint()..color = Colors.black;
    for (int i = -1; i <= 1; i += 2) {
      final eyePos = Offset(i * bodyWidth * 0.3, -bodyHeight * 0.45);
      canvas.drawCircle(eyePos, 4, eyePaint);
      canvas.drawCircle(eyePos + const Offset(-1, -1), 2, pupilPaint);
      canvas.drawCircle(eyePos + const Offset(1, 1), 1, eyePaint); // Glint
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

enum BugType { beetle, moth, crawler, cockroach, firefly }

class Bug {
  Offset pos = Offset(
    math.Random().nextDouble() * 300,
    math.Random().nextDouble() * 600,
  );
  Offset vel =
      Offset(
        math.Random().nextDouble() - 0.5,
        math.Random().nextDouble() - 0.5,
      ) *
      3;
  late Color color;
  double size = 35.0;
  BugType type = BugType.beetle;
  double rotation = 0;

  Bug() {
    type = BugType.values[math.Random().nextInt(BugType.values.length)];
    switch (type) {
      case BugType.beetle:
        color = Colors.yellowAccent[100]!; 
        size = 60.0; // Increased from 35
        break;
      case BugType.moth:
        color = Colors.white; 
        size = 55.0; // Increased from 30
        break;
      case BugType.crawler:
        color = Colors.blueAccent[100]!; 
        size = 45.0; // Increased from 28
        break;
      case BugType.cockroach:
        color = Colors.yellowAccent[100]!; 
        size = 75.0; // Increased from 40
        break;
      case BugType.firefly:
        color = Colors.yellowAccent[400]!;
        size = 35.0; // Increased from 20
        break;
    }
  }

  void update(Offset touch, bool isTouching, Size sizeLimit) {
    if (isTouching) {
      final dir = (pos - touch);
      if (dir.distance < 250) {
        vel += dir / 45; // Scared!
      }
    }

    pos += vel;
    vel *= 0.985; // Friction

    // Proper Bouncing Physics (with clamping to prevent sticking)
    final radius = size / 2;
    if (pos.dx < radius) {
      pos = Offset(radius, pos.dy);
      vel = Offset(vel.dx.abs(), vel.dy);
    } else if (pos.dx > sizeLimit.width - radius) {
      pos = Offset(sizeLimit.width - radius, pos.dy);
      vel = Offset(-vel.dx.abs(), vel.dy);
    }

    if (pos.dy < radius) {
      pos = Offset(pos.dx, radius);
      vel = Offset(vel.dx, vel.dy.abs());
    } else if (pos.dy > sizeLimit.height - radius) {
      pos = Offset(pos.dx, sizeLimit.height - radius);
      vel = Offset(vel.dx, -vel.dy.abs());
    }

    // Minimum activity - much smoother to prevent jittering (epilepsy-like movement)
    if (vel.distance < 1.0) {
      vel += Offset(
        (math.Random().nextDouble() - 0.5) * 0.5,
        (math.Random().nextDouble() - 0.5) * 0.5,
      );
    }

    // Smooth rotation update to prevent vibration/jitter
    if (vel.distance > 0.1) {
      double targetRotation = math.atan2(vel.dy, vel.dx) + math.pi / 2;
      double diff = targetRotation - rotation;
      // Normalize angle difference to [-pi, pi]
      while (diff > math.pi) diff -= 2 * math.pi;
      while (diff < -math.pi) diff += 2 * math.pi;
      rotation += diff * 0.15; // Smooth interpolation factor
    }
  }
}

class LaserPathPainter extends CustomPainter {
  final Offset touch;
  final bool isTouching;
  final double time;

  static List<LaserDot> dots = [
    LaserDot(
      const Offset(200, 400),
      const Offset(12, 12),
      size: 20,
      canReproduce: true,
    ),
  ];
  static List<Particle> sparks = [];
  static double shakeState = 0;

  LaserPathPainter(this.touch, this.isTouching, this.time);

  static void handleTap(Offset pos) {
    for (int i = dots.length - 1; i >= 0; i--) {
      if ((pos - dots[i].pos).distance < 60) {
        final parent = dots.removeAt(i);
        shakeState = 1.0; // Trigger "vibrate" effect
        try {
          SoundService().playLaserBlast();
        } catch (_) {}

        if (parent.canReproduce) {
          // Calculate how many we can spawn (max 3 on screen)
          int spaceLeft = 3 - dots.length;
          int toSpawn = spaceLeft >= 2 ? 2 : spaceLeft;

          for (int j = 0; j < toSpawn; j++) {
            dots.add(
              LaserDot(
                parent.pos,
                Offset(
                      math.Random().nextDouble() - 0.5,
                      math.Random().nextDouble() - 0.5,
                    ) *
                    25,
                size: 20,
                canReproduce: j == 0, // Only one of the two gives birth
              ),
            );
          }
        }

        // Sparks
        for (int p = 0; p < 20; p++) {
          sparks.add(
            Particle(
              parent.pos,
              Offset(
                    math.Random().nextDouble() - 0.5,
                    math.Random().nextDouble() - 0.5,
                  ) *
                  10,
              Colors.redAccent,
            ),
          );
        }
        break;
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Vibrate/Shake Effect
    if (shakeState > 0) {
      shakeState -= 0.05;
      canvas.translate(
        math.sin(time * 100) * 10 * shakeState,
        math.cos(time * 100) * 10 * shakeState,
      );
    }

    // Starry Background
    canvas.drawRect(
      Rect.fromLTWH(-20, -20, size.width + 40, size.height + 40),
      Paint()..color = const Color(0xFF000510),
    );
    final starPaint = Paint()..color = Colors.white.withOpacity(0.3);
    for (int i = 0; i < 50; i++) {
      final r = math.Random(i);
      canvas.drawCircle(
        Offset(r.nextDouble() * size.width, r.nextDouble() * size.height),
        r.nextDouble() * 1.5,
        starPaint,
      );
    }

    // Update Sparks
    for (int i = sparks.length - 1; i >= 0; i--) {
      sparks[i].update();
      if (sparks[i].life <= 0)
        sparks.removeAt(i);
      else
        canvas.drawCircle(
          sparks[i].pos,
          2.5,
          Paint()..color = sparks[i].color.withOpacity(sparks[i].life),
        );
    }

    // Update and Draw Dots
    for (var dot in dots) {
      dot.update(size);

      // Heavy Glow effect
      final glowPaint = Paint()
        ..color = (dot.canReproduce ? Colors.red : Colors.orange).withOpacity(
          0.6,
        )
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
      canvas.drawCircle(dot.pos, dot.size * 2.5, glowPaint);

      // Core
      canvas.drawCircle(
        dot.pos,
        dot.size,
        Paint()..color = dot.canReproduce ? Colors.red : Colors.orange,
      );
      canvas.drawCircle(dot.pos, dot.size * 0.5, Paint()..color = Colors.white);

      // Visual indicator for "can give birth"
      if (dot.canReproduce) {
        canvas.drawCircle(
          dot.pos,
          dot.size * 1.2,
          Paint()
            ..color = Colors.white.withOpacity(0.2)
            ..style = PaintingStyle.stroke,
        );
      }
    }

    // Cleanup if too many dots
    if (dots.length > 8) dots.removeAt(0);
    if (dots.isEmpty)
      dots.add(
        LaserDot(
          Offset(size.width / 2, size.height / 2),
          const Offset(12, 12),
          size: 20,
          canReproduce: true,
        ),
      );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class LaserDot {
  Offset pos;
  Offset vel;
  double size;
  bool canReproduce;
  LaserDot(this.pos, this.vel, {this.size = 15.0, this.canReproduce = false});

  void update(Size bounds) {
    pos += vel;
    if (pos.dx < 0.0) {
      pos = Offset(0.0, pos.dy);
      vel = Offset(vel.dx.abs(), vel.dy);
    }
    if (pos.dx > bounds.width) {
      pos = Offset(bounds.width, pos.dy);
      vel = Offset(-vel.dx.abs(), vel.dy);
    }
    if (pos.dy < 0.0) {
      pos = Offset(pos.dx, 0.0);
      vel = Offset(vel.dx, vel.dy.abs());
    }
    if (pos.dy > bounds.height) {
      pos = Offset(pos.dx, bounds.height);
      vel = Offset(vel.dx, -vel.dy.abs());
    }
  }
}

class PondSkaterPainter extends CustomPainter {
  final Offset touch;
  final bool isTouching;
  final double time;

  static List<Koi> fish = List.generate(5, (_) => Koi());
  static List<Ripple> ripples = [];

  PondSkaterPainter(this.touch, this.isTouching, this.time);

  static void handleTap(Offset pos) {
    ripples.add(Ripple(pos));
    SoundService().playSplash();
    for (var f in fish) {
      final dir = f.pos - pos;
      if (dir.distance < 200) {
        f.vel += dir / 20; // Pushed away
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Water Background
    final waterPaint = Paint()..color = const Color(0xFF00BCD4);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), waterPaint);

    // Light Refractions
    final refractionPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 2;
    for (int i = 0; i < 10; i++) {
      canvas.drawLine(
        Offset(0, i * 100 + math.sin(time * 2) * 20),
        Offset(size.width, i * 100 + math.cos(time * 2) * 20),
        refractionPaint,
      );
    }

    // Update and Draw Fish
    for (var f in fish) {
      f.update(size);
      final koiPaint = Paint()..color = f.color;
      canvas.drawOval(
        Rect.fromCenter(center: f.pos, width: 20, height: 40),
        koiPaint,
      );
      // Tail
      canvas.drawCircle(
        f.pos + Offset(0, 25 + math.sin(time * 10) * 5),
        8,
        koiPaint,
      );
    }

    // Ripples
    for (int i = ripples.length - 1; i >= 0; i--) {
      ripples[i].update();
      if (ripples[i].life <= 0) {
        ripples.removeAt(i);
      } else {
        canvas.drawCircle(
          ripples[i].pos,
          ripples[i].radius,
          Paint()
            ..color = Colors.white.withOpacity(ripples[i].life.clamp(0.0, 1.0))
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class Koi {
  Offset pos = Offset(
    math.Random().nextDouble() * 300,
    math.Random().nextDouble() * 600,
  );
  Offset vel = Offset(0, 2);
  Color color = math.Random().nextBool() ? Colors.orange : Colors.white;

  void update(Size size) {
    pos += vel;
    if (pos.dx < 0 || pos.dx > size.width) vel = Offset(-vel.dx, vel.dy);
    if (pos.dy < 0 || pos.dy > size.height) vel = Offset(vel.dx, -vel.dy);
    vel = Offset.lerp(
      vel,
      Offset(math.sin(DateTime.now().millisecondsSinceEpoch / 1000) * 2, 2),
      0.05,
    )!;
  }
}

class StringFeatherPainter extends CustomPainter {
  final Offset touch;
  final bool isTouching;
  final double time;
  final double accelX;
  final double accelY;

  static Offset featherPos = const Offset(200, 300);
  static Offset vel = Offset.zero;
  static List<Particle> catnip = [];

  StringFeatherPainter(
    this.touch,
    this.isTouching,
    this.time,
    this.accelX,
    this.accelY,
  );

  static void handleTap(Offset pos) {
    if ((pos - featherPos).distance < 100) {
      // Pull and release logic is handled in update
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Premium Hardwood Floor Background
    final floorColor = const Color(0xFF2D1B10); // Rich Dark Oak
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = floorColor);

    // Plank Lines
    final plankPaint = Paint()..color = Colors.black.withOpacity(0.3)..strokeWidth = 2.0;
    for (double i = 0; i < size.width; i += 60) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), plankPaint);
    }
    
    // Subtle Wood Grain/Texture
    final grainPaint = Paint()..color = Colors.white.withOpacity(0.03);
    final random = math.Random(555);
    for (int i = 0; i < 150; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      canvas.drawRect(Rect.fromLTWH(x, y, 40, 2), grainPaint);
    }

    final anchor = Offset(size.width / 2, 0);

    // Physics
    final gravity = Offset(-accelX, accelY + 9.8) * 0.5;
    if (isTouching && (touch - featherPos).distance < 150) {
      featherPos = Offset.lerp(featherPos, touch, 0.3)!;
      if (featherPos.dy > 600) {
        // Trigger catnip
        for (int i = 0; i < 5; i++) {
          catnip.add(
            Particle(
              featherPos,
              Offset(
                    math.Random().nextDouble() - 0.5,
                    math.Random().nextDouble(),
                  ) *
                  5,
              Colors.green,
            ),
          );
        }
      }
    } else {
      final springForce = (anchor + const Offset(0, 350) - featherPos) * 0.1;
      vel += springForce + gravity;
      featherPos += vel;
      vel *= 0.92; // Damping
    }

    // Update Catnip
    for (int i = catnip.length - 1; i >= 0; i--) {
      catnip[i].update();
      if (catnip[i].life <= 0)
        catnip.removeAt(i);
      else
        canvas.drawCircle(
          catnip[i].pos,
          5,
          Paint()..color = Colors.green[300]!.withOpacity(catnip[i].life),
        );
    }

    // Calculate rotation once for both string and feather
    final rotation = (vel.dx * 0.05).clamp(-0.8, 0.8);

    // Calculate the "Upper Tip" position in global space for the string connection
    // The longer feather tip is now at local Offset(0, -75)
    final tipOffset = Offset(
      math.sin(rotation) * 75,
      -math.cos(rotation) * 75,
    );

    // Draw String connected to the tip
    canvas.drawLine(
      anchor,
      featherPos + tipOffset,
      Paint()
        ..color = Colors.white70
        ..strokeWidth = 1.5,
    );

    // Draw Feather (Longer High Fidelity Design)
    canvas.save();
    canvas.translate(featherPos.dx, featherPos.dy);
    canvas.rotate(rotation);

    final shaftPaint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
      
    final barbPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    // Draw the Rachis (Central Shaft) - Extended to 150 total length
    final shaftPath = Path();
    shaftPath.moveTo(0, -75);
    shaftPath.quadraticBezierTo(math.sin(time * 2.5) * 8, 10, 0, 85);
    canvas.drawPath(shaftPath, shaftPaint);

    // Draw the Barbs (Denser loop for longer feather)
    for (double i = -65; i < 75; i += 1.5) {
      final t = (i + 65) / 140; // Normalized position (0 to 1)
      final width = math.sin(t * math.pi) * 45; // Wider tapered width
      
      barbPaint.color = Color.lerp(Colors.yellow[50], Colors.white, t)!;
      
      // Top side barbs (point up)
      canvas.drawLine(
        Offset(0, i),
        Offset(-width, i + 18),
        barbPaint,
      );
      
      canvas.drawLine(
        Offset(0, i),
        Offset(width, i + 18),
        barbPaint,
      );
    }

    // Add an elegant soft glow
    final coreGlow = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawOval(Rect.fromCenter(center: const Offset(0, 0), width: 50, height: 160), coreGlow);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class WhackAMousePainter extends CustomPainter {
  final Offset touch;
  final bool isTouching;
  final double time;

  static List<MouseHole> holes = [];
  static List<Particle> particles = [];
  static List<PawEffect> paws = [];
  static bool initialized = false;

  WhackAMousePainter(this.touch, this.isTouching, this.time);

  void _initialize(Size size) {
    if (initialized) return;
    double cellWidth = size.width / 3;
    double cellHeight = size.height / 4;
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 4; j++) {
        holes.add(MouseHole(Offset(
          cellWidth * (i + 0.5),
          cellHeight * (j + 0.5 + 0.1), // Offset down slightly to avoid top bar
        )));
      }
    }
    initialized = true;
  }

  static void handleTap(Offset pos) {
    for (var hole in holes) {
      if (hole.popState > 0.5 && (pos - hole.pos).distance < 70) {
        // Hit! Reset immediately
        hole.popState = 0;
        hole.isUp = false;
        hole.nextActionTime = DateTime.now().millisecondsSinceEpoch + 2000;
        
        SoundService().playWhack();
        HapticFeedback.heavyImpact();
        
        // Add paw effect
        paws.add(PawEffect(hole.pos));
        
        for (int i = 0; i < 15; i++) {
          particles.add(Particle(
            hole.pos,
            Offset(math.Random().nextDouble() - 0.5, math.Random().nextDouble() - 0.5) * 12,
            Colors.grey,
          ));
        }
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    _initialize(size);
    
    // 1. Cheese Background
    final cheeseColor = const Color(0xFFFFD54F);
    final holeColor = const Color(0xFFFFC107);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = cheeseColor);
    
    final rand = math.Random(42);
    final texturePaint = Paint()..color = holeColor.withOpacity(0.4);
    for(int i=0; i<25; i++) {
       canvas.drawCircle(Offset(rand.nextDouble() * size.width, rand.nextDouble() * size.height), 15 + rand.nextDouble() * 40, texturePaint);
    }

    // 2. Update and Draw Holes/Mice
    final now = DateTime.now().millisecondsSinceEpoch;
    final mouseBodyPaint = Paint()..color = Colors.grey[600]!;
    final eyePaint = Paint()..color = Colors.black;
    final nosePaint = Paint()..color = Colors.pink[200]!;

    bool anyMouseUp = holes.any((h) => h.isUp || h.popState > 0);

    for (var hole in holes) {
      if (!hole.isUp && now > hole.nextActionTime && !anyMouseUp) {
        if (math.Random().nextDouble() < 0.008) { // Slow chance
          hole.isUp = true;
          anyMouseUp = true; // Mark as up so other holes don't pop in the same frame
          hole.stayUpUntil = now + 2000 + math.Random().nextInt(2500); // Stays up longer
        }
      }
      
      if (hole.isUp && now > hole.stayUpUntil) {
        hole.isUp = false;
        hole.nextActionTime = now + 1500 + math.Random().nextInt(3000);
      }

      if (hole.isUp && hole.popState < 1.0) {
        hole.popState += 0.04; // Slow pop up
      } else if (!hole.isUp && hole.popState > 0.0) {
        hole.popState -= 0.04; // Slow pop down
      }
      hole.popState = hole.popState.clamp(0.0, 1.0);

      // 1. Hole Base & Border (Drawn first)
      canvas.drawCircle(hole.pos, 60, Paint()..color = Colors.black.withOpacity(0.25));
      canvas.drawCircle(
        hole.pos, 
        60, 
        Paint()..color = holeColor.withOpacity(0.8)..style = PaintingStyle.stroke..strokeWidth = 12
      );
      
      // 2. Draw Mouse (Drawn on top)
      if (hole.popState > 0) {
        canvas.save();
        canvas.translate(hole.pos.dx, hole.pos.dy);
        canvas.scale(hole.popState);
        
        // Mouse Body Gradient (Rounded Look)
        final mousePaint = Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.grey[400]!,
              Colors.grey[700]!,
            ],
            center: const Alignment(-0.3, -0.3),
          ).createShader(Rect.fromCircle(center: Offset.zero, radius: 50));

        // Head (High Detail)
        canvas.drawCircle(Offset.zero, 50, mousePaint);
        
        // Ears (Translucent Inner Shading)
        for (int i = -1; i <= 1; i += 2) {
          canvas.save();
          canvas.translate(i * 40, -35);
          canvas.drawCircle(Offset.zero, 28, mousePaint);
          canvas.drawCircle(Offset.zero, 18, Paint()..color = Colors.pink[100]!.withOpacity(0.6));
          canvas.restore();
        }
        
        // Realistic Eyes with Glint
        final eyePaint = Paint()..color = Colors.black;
        final glintPaint = Paint()..color = Colors.white;
        for (int i = -1; i <= 1; i += 2) {
           final eyePos = Offset(i * 18, -12);
           canvas.drawCircle(eyePos, 7, eyePaint);
           canvas.drawCircle(eyePos + const Offset(-2, -2), 2, glintPaint);
        }
        
        // Soft Pink Nose
        final nosePaint = Paint()
          ..shader = RadialGradient(
            colors: [Colors.pink[100]!, Colors.pink[300]!],
          ).createShader(Rect.fromCircle(center: Offset(0, 12), radius: 10));
        canvas.drawCircle(const Offset(0, 12), 10, nosePaint);
        
        // High Fidelity Whiskers (Tapered)
        final whiskerPaint = Paint()..color = Colors.black54..strokeWidth = 1.0..strokeCap = StrokeCap.round;
        for (int i = -1; i <= 1; i += 2) {
          canvas.drawLine(Offset(i * 15, 12), Offset(i * 60, 5), whiskerPaint);
          canvas.drawLine(Offset(i * 15, 18), Offset(i * 60, 25), whiskerPaint);
        }
        
        canvas.restore();
      }
    }

    // 3. Particles
    for (int i = particles.length - 1; i >= 0; i--) {
      particles[i].update();
      if (particles[i].life <= 0) {
        particles.removeAt(i);
      } else {
        canvas.drawCircle(particles[i].pos, 5, Paint()..color = particles[i].color.withOpacity(particles[i].life));
      }
    }

    // 4. Paw Animations
    for (int i = paws.length - 1; i >= 0; i--) {
      final paw = paws[i];
      paw.update();
      if (paw.life <= 0) {
        paws.removeAt(i);
      } else {
        _drawPaw(canvas, paw);
      }
    }
  }

  void _drawPaw(Canvas canvas, PawEffect paw) {
    canvas.save();
    // Aligned to middle of hole and moved slightly below
    canvas.translate(paw.pos.dx, paw.pos.dy + 15);
    
    final pawColor = Colors.orange[400]!;
    final padColor = Colors.pink[100]!;
    
    // Main Paw "Hand" - Centered vertically around (0, 0)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-40, -35, 80, 70),
        const Radius.circular(30),
      ),
      Paint()..color = pawColor,
    );
    
    // Toes
    for (int i = 0; i < 3; i++) {
      final x = (i - 1) * 35.0;
      canvas.drawCircle(Offset(x, -45), 20, Paint()..color = pawColor);
      canvas.drawCircle(Offset(x, -45), 12, Paint()..color = padColor);
    }
    
    // Main Pad
    canvas.drawCircle(const Offset(0, 0), 25, Paint()..color = padColor);
    
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class FishTankPainter extends CustomPainter {
  final Offset touch;
  final bool isTouching;
  final double time;

  static List<Fish> fish = [];
  static List<Ripple> ripples = [];
  static bool initialized = false;

  FishTankPainter(this.touch, this.isTouching, this.time);

  void _initialize(Size size) {
    if (initialized) return;
    for (int i = 0; i < 3; i++) {
      fish.add(Fish(size));
    }
    initialized = true;
  }

  static void handleTap(Offset pos) {
    ripples.add(Ripple(pos));
    SoundService().playSplash();
    HapticFeedback.mediumImpact();
    
    // Make fish dart away from tap
    for (var f in fish) {
      final dist = (f.pos - pos).distance;
      if (dist < 220) {
        final dir = (f.pos - pos).distance > 0 ? (f.pos - pos) / (f.pos - pos).distance : Offset.zero;
        f.vel += dir * 12;
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    _initialize(size);

    // 1. Water Background
    final waterColor = const Color(0xFF00ACC1);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = waterColor);
    
    // Soft caustics (moving light rays)
    final causticPaint = Paint()..color = Colors.white.withOpacity(0.04)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25);
    for(int i=0; i<6; i++) {
       final x = (math.sin(time * 0.4 + i) * 0.5 + 0.5) * size.width;
       final y = (math.cos(time * 0.2 + i) * 0.5 + 0.5) * size.height;
       canvas.drawCircle(Offset(x, y), 120 + math.sin(time) * 30, causticPaint);
    }

    // 2. Update and Draw Ripples
    for (int i = ripples.length - 1; i >= 0; i--) {
      ripples[i].update();
      if (ripples[i].life <= 0) {
        ripples.removeAt(i);
      } else {
        canvas.drawCircle(
          ripples[i].pos, 
          ripples[i].radius, 
          Paint()..color = Colors.white.withOpacity(ripples[i].life * 0.4)..style = PaintingStyle.stroke..strokeWidth = 3
        );
      }
    }

    // 3. Update and Draw Fish
    for (var f in fish) {
      f.update(size, time);
      
      canvas.save();
      canvas.translate(f.pos.dx, f.pos.dy);
      canvas.rotate(f.rotation);
      
      // Fish Body Gradient (3D look)
      final bodyRect = Rect.fromCenter(center: Offset.zero, width: 26, height: 65);
      final bodyPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            f.color.withOpacity(1.0),
            Color.lerp(f.color, Colors.black, 0.2)!,
          ],
          center: const Alignment(-0.3, -0.2),
        ).createShader(bodyRect);
      
      // Main Body Path (Tapered)
      final bodyPath = Path();
      bodyPath.moveTo(0, -32); // Head
      bodyPath.quadraticBezierTo(15, -20, 10, 10); // Right side
      bodyPath.quadraticBezierTo(5, 32, 0, 32);    // Tail base
      bodyPath.quadraticBezierTo(-5, 32, -10, 10); // Left side
      bodyPath.quadraticBezierTo(-15, -20, 0, -32); // Back to head
      canvas.drawPath(bodyPath, bodyPaint);
      
      // Fins (Translucent with rays)
      final finPaint = Paint()
        ..color = f.color.withOpacity(0.4)
        ..style = PaintingStyle.fill;
      final rayPaint = Paint()
        ..color = Colors.white.withOpacity(0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5;

      final tailWave = math.sin(time * 12 + f.id) * 12;
      
      // Detailed Tail
      final tailPath = Path();
      tailPath.moveTo(0, 30);
      tailPath.cubicTo(-20 + tailWave, 40, -15 + tailWave, 55, 0, 50 + tailWave.abs() * 0.2);
      tailPath.cubicTo(15 + tailWave, 55, 20 + tailWave, 40, 0, 30);
      canvas.drawPath(tailPath, finPaint);
      
      // Tail Rays
      for (int i = -1; i <= 1; i++) {
        canvas.drawLine(const Offset(0, 32), Offset(i * 12 + tailWave, 50), rayPaint);
      }

      // Pectoral Fins (Side fins)
      canvas.save();
      canvas.translate(-12, -5);
      canvas.rotate(-math.pi / 4);
      canvas.drawOval(const Rect.fromLTWH(0, 0, 20, 12), finPaint);
      canvas.restore();
      
      canvas.save();
      canvas.translate(12, -5);
      canvas.rotate(math.pi / 4);
      canvas.drawOval(const Rect.fromLTWH(-20, 0, 20, 12), finPaint);
      canvas.restore();

      // Realistic Eyes
      final eyeBase = Paint()..color = Colors.white;
      final pupil = Paint()..color = Colors.black;
      canvas.drawCircle(const Offset(-8, -22), 4, eyeBase);
      canvas.drawCircle(const Offset(8, -22), 4, eyeBase);
      canvas.drawCircle(const Offset(-9, -23), 2, pupil);
      canvas.drawCircle(const Offset(9, -23), 2, pupil);

      // Spots (Pattern)
      final spotPaint = Paint()..color = Colors.black.withOpacity(0.2);
      canvas.drawCircle(const Offset(4, -5), 6, spotPaint);
      canvas.drawCircle(const Offset(-3, 12), 4, spotPaint);

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class Fish {
  Offset pos;
  Offset vel;
  Color color;
  double id;
  double speedMultiplier;
  double turnFrequency;
  
  Fish(Size size) 
    : pos = Offset(math.Random().nextDouble() * size.width, math.Random().nextDouble() * size.height),
      vel = Offset(math.Random().nextDouble() - 0.5, math.Random().nextDouble() - 0.5) * 2.5,
      color = [Colors.orange[400]!, Colors.white, Colors.red[300]!][math.Random().nextInt(3)],
      id = math.Random().nextDouble() * 100,
      speedMultiplier = 0.8 + math.Random().nextDouble() * 1.5,
      turnFrequency = 0.3 + math.Random().nextDouble() * 0.8,
      rotation = 0;
  double rotation;

  void update(Size size, double time) {
    // Diversified movement patterns
    double angle = math.atan2(vel.dy, vel.dx);
    angle += math.sin(time * turnFrequency + id) * 0.025; 
    
    double speed = vel.distance;
    vel = Offset(math.cos(angle), math.sin(angle)) * speed;
    
    vel *= 0.99; // Drag
    double maxSpeed = 3.0 * speedMultiplier;
    if (speed > maxSpeed) vel = (vel / speed) * maxSpeed;
    if (speed < 1.0) vel = (vel / speed) * 1.0;
    
    pos += vel;

    // Smooth rotation interpolation
    double targetRotation = math.atan2(vel.dy, vel.dx) + math.pi / 2;
    double diff = targetRotation - rotation;
    while (diff > math.pi) diff -= 2 * math.pi;
    while (diff < -math.pi) diff += 2 * math.pi;
    rotation += diff * 0.1;
    
    // Bounce off walls
    const margin = 60.0;
    if (pos.dx < margin) vel = Offset(vel.dx.abs(), vel.dy);
    if (pos.dx > size.width - margin) vel = Offset(-vel.dx.abs(), vel.dy);
    if (pos.dy < margin) vel = Offset(vel.dx, vel.dy.abs());
    if (pos.dy > size.height - margin) vel = Offset(vel.dx, -vel.dy.abs());
  }
}

class MouseHole {
  Offset pos;
  double popState = 0; // 0 to 1
  bool isUp = false;
  int stayUpUntil = 0;
  int nextActionTime = 0;
  MouseHole(this.pos);
}

class PawEffect {
  Offset pos;
  double life = 1.0;
  PawEffect(this.pos);
  void update() => life -= 0.05;
}


