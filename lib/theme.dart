import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const kGreen = Color(0xFF1F5E4A);
const kGold = Color(0xFFB08A3E);

class Palette {
  final Color bg, page, ink, muted, accent, line, highlight;
  const Palette(this.bg, this.page, this.ink, this.muted, this.accent, this.line, this.highlight);
}

const lightPalette = Palette(Color(0xFFF6F1E4), Color(0xFFFFFAF0), Color(0xFF2B2A26),
    Color(0xFF7A7466), kGreen, Color(0xFFE6DCC4), Color(0xFFFFF1C9));
const darkPalette = Palette(Color(0xFF12160F), Color(0xFF1A1F17), Color(0xFFECE6D6),
    Color(0xFF9A9483), Color(0xFF7FC4A6), Color(0xFF2E3427), Color(0xFF3A3420));

Palette paletteOf(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark ? darkPalette : lightPalette;

ThemeData buildTheme(bool dark) {
  final p = dark ? darkPalette : lightPalette;
  final base = ThemeData(
    useMaterial3: true,
    brightness: dark ? Brightness.dark : Brightness.light,
    colorSchemeSeed: kGreen,
  );
  return base.copyWith(
    scaffoldBackgroundColor: p.bg,
    textTheme: GoogleFonts.amiriTextTheme(base.textTheme),
    appBarTheme: AppBarTheme(
      backgroundColor: dark ? const Color(0xFF0D2A20) : kGreen,
      foregroundColor: Colors.white,
      centerTitle: true,
      titleTextStyle: GoogleFonts.amiri(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
    ),
    dividerColor: p.line,
  );
}

/// Cream "page" panel used for lists and the reader.
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

/// Style for Quran text. Uses Amiri Quran, falling back to Amiri.
TextStyle quranStyle(double size, Color color) {
  try {
    return GoogleFonts.getFont('Amiri Quran', fontSize: size, height: 2.1, color: color);
  } catch (_) {
    return GoogleFonts.amiri(fontSize: size, height: 2.1, color: color);
  }
}
