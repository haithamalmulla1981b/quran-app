import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'quran_data.dart';

// Persian Mushaf palette: lapis, turquoise and gold on cream.
const kPrimary = Color(0xFF1B3A6B); // lapis
const kGreen = kPrimary; // kept for older references
const kTurquoise = Color(0xFF2E8B9A);
const kGold = Color(0xFFB8892E);
const kGoldLight = Color(0xFFD9B55F);
const kPetal = Color(0xFFF6E3A8);
const kCreamGold = Color(0xFFF3E3B5);

class Palette {
  final Color bg, page, ink, muted, accent, line, highlight, band;
  const Palette(this.bg, this.page, this.ink, this.muted, this.accent, this.line, this.highlight, this.band);
}

const lightPalette = Palette(Color(0xFFF4ECD8), Color(0xFFFBF6E9), Color(0xFF22201C), Color(0xFF8A7A55),
    kPrimary, Color(0xFFE3D6B4), Color(0xFFF6E3A8), kPrimary);
const darkPalette = Palette(Color(0xFF0E1626), Color(0xFF152038), Color(0xFFECE3CC), Color(0xFF9A9070),
    Color(0xFF8FB4E8), Color(0xFF2A3A5C), Color(0xFF4A3F1E), Color(0xFF2A4F8F));

Palette paletteOf(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark ? darkPalette : lightPalette;

ThemeData buildTheme(bool dark) {
  final p = dark ? darkPalette : lightPalette;
  final base = ThemeData(
    useMaterial3: true,
    brightness: dark ? Brightness.dark : Brightness.light,
    colorSchemeSeed: kPrimary,
  );
  return base.copyWith(
    scaffoldBackgroundColor: p.bg,
    textTheme: GoogleFonts.amiriTextTheme(base.textTheme),
    appBarTheme: AppBarTheme(
      backgroundColor: dark ? const Color(0xFF0B1730) : kPrimary,
      foregroundColor: kCreamGold,
      centerTitle: true,
      titleTextStyle: GoogleFonts.amiri(fontSize: 22, fontWeight: FontWeight.w700, color: kCreamGold),
    ),
    dividerColor: p.line,
  );
}

/// Style for Quran text. Uses Amiri Quran, falling back to Amiri.
TextStyle quranStyle(double size, Color color) {
  try {
    return GoogleFonts.getFont('Amiri Quran', fontSize: size, height: 2.1, color: color);
  } catch (_) {
    return GoogleFonts.amiri(fontSize: size, height: 2.1, color: color);
  }
}

/// Persian calligraphic (Nastaliq) style, used for the developer credit.
TextStyle nastaliqStyle(double size, Color color) {
  try {
    return GoogleFonts.getFont('Noto Nastaliq Urdu', fontSize: size, color: color, height: 1.9);
  } catch (_) {
    return GoogleFonts.amiri(fontSize: size, color: color);
  }
}

/// "Developed by" credit with the name in Nastaliq.
class DeveloperCredit extends StatelessWidget {
  final Color color;
  final double size;
  const DeveloperCredit({super.key, required this.color, this.size = 22});

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text('Developed by',
          textDirection: TextDirection.ltr,
          style: TextStyle(fontSize: size * 0.55, color: color, letterSpacing: 1)),
      Text('هيثم محمد الملا', textAlign: TextAlign.center, style: nastaliqStyle(size, color)),
    ]);
  }
}

/// Cream "page" panel used for lists.
class PageCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry margin;
  final Color? color;
  const PageCard({super.key, required this.child, this.margin = const EdgeInsets.fromLTRB(12, 6, 12, 6), this.color});

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? p.page,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

/// One horizontal slice of the illuminated page frame (gold · lapis · gold).
/// Consecutive slices join seamlessly; [first] and [last] close the frame.
class FrameSlice extends StatelessWidget {
  final Widget child;
  final bool first, last;
  final Color? fill;
  const FrameSlice({super.key, required this.child, this.first = false, this.last = false, this.fill});

  Border _b(Color c, double w) => Border(
        left: BorderSide(color: c, width: w),
        right: BorderSide(color: c, width: w),
        top: first ? BorderSide(color: c, width: w) : BorderSide.none,
        bottom: last ? BorderSide(color: c, width: w) : BorderSide.none,
      );

  EdgeInsets _pad(double side, double end) =>
      EdgeInsets.fromLTRB(side, first ? end : 0, side, last ? end : 0);

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    return Container(
      margin: EdgeInsets.fromLTRB(10, first ? 10 : 0, 10, last ? 12 : 0),
      padding: _pad(3, 3),
      decoration: BoxDecoration(color: p.page, border: _b(kGold, 1.5)),
      child: Container(
        color: p.band,
        padding: _pad(5, 5),
        child: Container(
          padding: _pad(3, 3),
          color: p.page,
          child: Container(
            padding: _pad(12, 10),
            decoration: BoxDecoration(color: fill ?? p.page, border: _b(kGold, 1)),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Gold eight-petal rosette with the ayah (or surah) number.
class Rosette extends StatelessWidget {
  final int number;
  final double size;
  final bool active;
  const Rosette(this.number, {super.key, this.size = 30, this.active = false});

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    final digits = arNum(number);
    final fs = size * (digits.length >= 3 ? 0.24 : digits.length == 2 ? 0.30 : 0.36);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(alignment: Alignment.center, children: [
        CustomPaint(size: Size.square(size), painter: _RosettePainter(p, active)),
        Text(digits,
            textAlign: TextAlign.center,
            style: GoogleFonts.amiri(fontSize: fs, height: 1.0, fontWeight: FontWeight.w700, color: p.accent)),
      ]),
    );
  }
}

class _RosettePainter extends CustomPainter {
  final Palette p;
  final bool active;
  _RosettePainter(this.p, this.active);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 26; // designed on a 26-unit grid
    final c = size.center(Offset.zero);
    final petal = Paint()..color = active ? kGoldLight : kPetal;
    final edge = Paint()
      ..color = kGold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7 * s;
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      canvas.save();
      canvas.translate(c.dx + 7 * s * math.cos(a), c.dy + 7 * s * math.sin(a));
      canvas.rotate(a);
      final r = Rect.fromCenter(center: Offset.zero, width: 10 * s, height: 6 * s);
      canvas.drawOval(r, petal);
      canvas.drawOval(r, edge);
      canvas.restore();
    }
    canvas.drawCircle(c, 7.5 * s, Paint()..color = p.page);
    canvas.drawCircle(
        c,
        7.5 * s,
        Paint()
          ..color = p.accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2 * s);
  }

  @override
  bool shouldRepaint(covariant _RosettePainter old) => old.active != active || old.p != p;
}

/// Persian-style surah title: lapis panel, cream medallion (toranj) and
/// turquoise roundels with the surah number and ayah count.
class SurahCartouche extends StatelessWidget {
  final int surah;
  const SurahCartouche(this.surah, {super.key});

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    return AspectRatio(
      aspectRatio: 340 / 74,
      child: LayoutBuilder(builder: (context, box) {
        final k = box.maxWidth / 340;
        final n = ayahCount(surah);
        return Stack(children: [
          Positioned.fill(child: CustomPaint(painter: _CartouchePainter(p))),
          Align(
            alignment: Alignment.center,
            child: Text('سورة ${surahNameAr(surah)}',
                style: GoogleFonts.amiri(fontSize: 24 * k, height: 1.2, fontWeight: FontWeight.w700, color: kPrimary)),
          ),
          Align(
            alignment: const Alignment(0.788, 0),
            child: Text(arNum(surah),
                style: GoogleFonts.amiri(fontSize: 16 * k, height: 1.1, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
          Align(
            alignment: const Alignment(-0.788, 0),
            child: SizedBox(
              width: 32 * k,
              child: Text('${arNum(n)}\n${ayahWord(n)}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.amiri(fontSize: 10 * k, height: 1.05, color: Colors.white)),
            ),
          ),
        ]);
      }),
    );
  }
}

class _CartouchePainter extends CustomPainter {
  final Palette p;
  _CartouchePainter(this.p);

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 340;
    Offset o(double x, double y) => Offset(x * k, y * k);
    final gold = Paint()
      ..color = kGold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * k;

    final panel = RRect.fromRectAndRadius(Rect.fromLTWH(1 * k, 1 * k, 338 * k, 72 * k), Radius.circular(3 * k));
    canvas.drawRRect(panel, Paint()..color = p.band);
    canvas.drawRRect(panel, gold);

    // Dotted inner rule
    final dot = Paint()..color = kGoldLight;
    for (double x = 8; x <= 332; x += 5) {
      canvas.drawCircle(o(x, 6), 0.9 * k, dot);
      canvas.drawCircle(o(x, 68), 0.9 * k, dot);
    }
    for (double y = 11; y <= 63; y += 5) {
      canvas.drawCircle(o(6, y), 0.9 * k, dot);
      canvas.drawCircle(o(334, y), 0.9 * k, dot);
    }

    // Toranj (central medallion)
    Path toranj(double inset) => Path()
      ..moveTo((70 + inset) * k, 37 * k)
      ..quadraticBezierTo(120 * k, (6 + inset) * k, 170 * k, (8 + inset) * k)
      ..quadraticBezierTo(220 * k, (6 + inset) * k, (270 - inset) * k, 37 * k)
      ..quadraticBezierTo(220 * k, (68 - inset) * k, 170 * k, (66 - inset) * k)
      ..quadraticBezierTo(120 * k, (68 - inset) * k, (70 + inset) * k, 37 * k)
      ..close();
    canvas.drawPath(toranj(0), Paint()..color = const Color(0xFFFBF6E9));
    canvas.drawPath(toranj(0), gold);
    canvas.drawPath(
        toranj(7),
        Paint()
          ..color = kTurquoise
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1 * k);

    // Side roundels
    for (final x in [36.0, 304.0]) {
      canvas.drawCircle(o(x, 37), 17 * k, Paint()..color = kTurquoise);
      canvas.drawCircle(
          o(x, 37),
          17 * k,
          Paint()
            ..color = kGoldLight
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2 * k);
    }
  }

  @override
  bool shouldRepaint(covariant _CartouchePainter old) => old.p != p;
}
