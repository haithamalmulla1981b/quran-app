import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_state.dart';
import 'home_screen.dart';
import 'theme.dart';

/// Animated intro shown at launch while the Quran text loads.
class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..forward();
  late final Future<void> _ready = app.init();
  bool _left = false;

  @override
  void initState() {
    super.initState();
    Future.wait([_ready, Future.delayed(const Duration(milliseconds: 2900))]).then((_) => _go());
  }

  void _go() {
    if (_left || !mounted) return;
    _left = true;
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (_, __, ___) => const HomeScreen(),
      transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
    ));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Animation<double> _seg(double a, double b, [Curve curve = Curves.easeOutCubic]) =>
      CurvedAnimation(parent: _c, curve: Interval(a, b, curve: curve));

  @override
  Widget build(BuildContext context) {
    final star = _seg(0.0, 0.55, Curves.easeOutBack);
    final title = _seg(0.30, 0.70);
    final sub = _seg(0.50, 0.85);
    final credit = _seg(0.70, 1.0);
    return Scaffold(
      backgroundColor: kGreen,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _ready.then((_) => _go()), // tap to skip
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => Stack(children: [
            Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Transform.rotate(
                  angle: (1 - star.value) * -math.pi / 2,
                  child: Transform.scale(
                    scale: 0.4 + 0.6 * star.value,
                    child: Opacity(
                      opacity: star.value.clamp(0.0, 1.0),
                      child: const SizedBox(width: 150, height: 150, child: CustomPaint(painter: _StarPainter())),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Opacity(
                  opacity: title.value,
                  child: Transform.translate(
                    offset: Offset(0, 24 * (1 - title.value)),
                    child: Text('القرآن الكريم',
                        style: GoogleFonts.amiri(fontSize: 44, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 6),
                Opacity(
                  opacity: sub.value,
                  child: Text('اقرأ · استمع · احفظ',
                      style: GoogleFonts.amiri(fontSize: 20, color: const Color(0xFFE9D9AE))),
                ),
              ]),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 40,
              child: Opacity(
                opacity: credit.value,
                child: Text('Developed By: H.M.Al-Mulla',
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.ltr,
                    style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.75), letterSpacing: 0.5)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Eight-pointed star (two overlapping squares) in gold, with an inner ring.
class _StarPainter extends CustomPainter {
  const _StarPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final side = r * 1.38;
    final fill = Paint()..color = const Color(0x22E9D9AE);
    final stroke = Paint()
      ..color = kGold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    for (final angle in [0.0, math.pi / 4]) {
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(angle);
      final rect = Rect.fromCenter(center: Offset.zero, width: side, height: side);
      canvas.drawRect(rect, fill);
      canvas.drawRect(rect, stroke);
      canvas.restore();
    }
    canvas.drawCircle(c, r * 0.42, stroke);
    canvas.drawCircle(c, r * 0.30, Paint()..color = const Color(0xFFE9D9AE));
    canvas.drawCircle(c, r * 0.30, stroke..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
