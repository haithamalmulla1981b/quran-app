import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_state.dart';
import 'home_screen.dart';
import 'theme.dart';

// Al-Ahzab 33:23, exactly as in the Tanzil text.
const _ayah = '\u0645\u0651\u0650\u0646\u064e \u0671\u0644\u0652\u0645\u064f\u0624\u0652\u0645\u0650\u0646\u065'
    '0\u064a\u0646\u064e \u0631\u0650\u062c\u064e\u0627\u0644\u064c \u0635\u064e\u062f\u064e\u0642\u0'
    '64f\u0648\u0627\u06df \u0645\u064e\u0627 \u0639\u064e\u0640\u0670\u0647\u064e\u062f\u064f\u0648\'
    'u0627\u06df \u0671\u0644\u0644\u0651\u064e\u0647\u064e \u0639\u064e\u0644\u064e\u064a\u0652\u064'
    '7\u0650 \u06d6 \u0641\u064e\u0645\u0650\u0646\u0652\u0647\u064f\u0645 \u0645\u0651\u064e\u0646 \'
    'u0642\u064e\u0636\u064e\u0649\u0670 \u0646\u064e\u062d\u0652\u0628\u064e\u0647\u064f\u06e5 \u064'
    '8\u064e\u0645\u0650\u0646\u0652\u0647\u064f\u0645 \u0645\u0651\u064e\u0646 \u064a\u064e\u0646\u0'
    '62a\u064e\u0638\u0650\u0631\u064f \u06d6 \u0648\u064e\u0645\u064e\u0627 \u0628\u064e\u062f\u0651'
    '\u064e\u0644\u064f\u0648\u0627\u06df \u062a\u064e\u0628\u0652\u062f\u0650\u064a\u0644\u064b\u062'
    '7';

/// Animated intro: star, title, then the ayah typed letter by letter.
class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> with TickerProviderStateMixin {
  // Star, title and subtitle over the first 3.6 s.
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 3600))..forward();
  late final AnimationController _credit =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
  late final Future<void> _ready = app.init();
  // Each letter keeps its diacritics while typing.
  final List<String> _letters = _ayah.characters.toList();
  int _typed = 0;
  bool _cursorOn = true;
  final List<Timer> _timers = [];
  bool _left = false;

  @override
  void initState() {
    super.initState();
    _ready; // start loading the Quran text now
    _timers.add(Timer(const Duration(milliseconds: 3600), _startTyping));
    _timers.add(Timer.periodic(const Duration(milliseconds: 450), (_) {
      if (mounted) setState(() => _cursorOn = !_cursorOn);
    }));
  }

  void _startTyping() {
    _timers.add(Timer.periodic(const Duration(milliseconds: 60), (t) {
      if (!mounted) return;
      if (_typed >= _letters.length) {
        t.cancel();
        _timers.add(Timer(const Duration(milliseconds: 600), () {
          if (mounted) _credit.forward();
        }));
        _timers.add(Timer(const Duration(milliseconds: 3000), () => _ready.then((_) => _go())));
        return;
      }
      setState(() => _typed++);
    }));
  }

  void _go() {
    if (_left || !mounted) return;
    _left = true;
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 600),
      pageBuilder: (_, __, ___) => const HomeScreen(),
      transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
    ));
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    _c.dispose();
    _credit.dispose();
    super.dispose();
  }

  Animation<double> _seg(double a, double b, [Curve curve = Curves.easeOutCubic]) =>
      CurvedAnimation(parent: _c, curve: Interval(a, b, curve: curve));

  @override
  Widget build(BuildContext context) {
    final star = _seg(0.0, 0.56, Curves.easeOutBack);
    final title = _seg(0.44, 0.72);
    final sub = _seg(0.72, 1.0);
    return Scaffold(
      backgroundColor: kPrimary,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _ready.then((_) => _go()), // tap to skip
        child: AnimatedBuilder(
          animation: Listenable.merge([_c, _credit]),
          builder: (context, _) => Stack(children: [
            Positioned.fill(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Center(
                    child: Transform.rotate(
                      angle: (1 - star.value) * -math.pi / 2,
                      child: Transform.scale(
                        scale: 0.4 + 0.6 * star.value,
                        child: Opacity(
                          opacity: star.value.clamp(0.0, 1.0),
                          child: const SizedBox(width: 120, height: 120, child: CustomPaint(painter: _StarPainter())),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),
                  Opacity(
                    opacity: title.value,
                    child: Transform.translate(
                      offset: Offset(0, 22 * (1 - title.value)),
                      child: Text('القرآن الكريم',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.amiri(fontSize: 44, fontWeight: FontWeight.w700, color: kCreamGold)),
                    ),
                  ),
                  Opacity(
                    opacity: sub.value,
                    child: Text('اقرأ · استمع · احفظ',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.amiri(fontSize: 20, color: const Color(0xFFE9D9AE))),
                  ),
                  const SizedBox(height: 22),
                  // Fixed height so nothing moves while the ayah is typed.
                  SizedBox(
                    height: 200,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: Text.rich(
                        TextSpan(children: [
                          TextSpan(
                            text: _letters.take(_typed).join(),
                            // Single-colour font so every mark shows in white.
                            style: GoogleFonts.amiri(fontSize: 22, height: 1.9, color: Colors.white),
                          ),
                          if (_typed > 0 || _c.isCompleted)
                            WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: Opacity(
                                opacity: _cursorOn ? 1 : 0,
                                child: Container(
                                  width: 2,
                                  height: 26,
                                  margin: const EdgeInsets.symmetric(horizontal: 2),
                                  color: kGoldLight,
                                ),
                              ),
                            ),
                        ]),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: 60),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 28,
              child: Opacity(
                opacity: _credit.value,
                child: const DeveloperCredit(color: kCreamGold, size: 26),
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
