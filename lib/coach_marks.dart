import 'dart:async';

import 'package:flutter/material.dart';

import 'quran_data.dart';
import 'theme.dart';

class CoachStep {
  final GlobalKey target;
  final String title;
  final String body;
  const CoachStep(this.target, this.title, this.body);
}

/// Shows a step-by-step guide that dims the screen and highlights one button
/// at a time with an Arabic explanation. Completes when finished or skipped.
Future<void> showCoachMarks(BuildContext context, List<CoachStep> steps) {
  final ready = steps.where((s) => s.target.currentContext != null).toList();
  final done = Completer<void>();
  if (ready.isEmpty) {
    done.complete();
    return done.future;
  }
  final overlay = Overlay.of(context);
  var i = 0;
  late OverlayEntry entry;
  void finish() {
    entry.remove();
    if (!done.isCompleted) done.complete();
  }

  void next() {
    if (i < ready.length - 1) {
      i++;
      entry.markNeedsBuild();
    } else {
      finish();
    }
  }

  entry = OverlayEntry(
    builder: (_) => _CoachView(step: ready[i], index: i, count: ready.length, onNext: next, onSkip: finish),
  );
  overlay.insert(entry);
  return done.future;
}

class _CoachView extends StatelessWidget {
  final CoachStep step;
  final int index, count;
  final VoidCallback onNext, onSkip;
  const _CoachView({required this.step, required this.index, required this.count, required this.onNext, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    final screen = MediaQuery.of(context).size;
    Rect hole = Rect.zero;
    final ro = step.target.currentContext?.findRenderObject();
    if (ro is RenderBox && ro.hasSize) {
      hole = (ro.localToGlobal(Offset.zero) & ro.size).inflate(6);
    }
    final isLast = index == count - 1;
    final big = hole.height > screen.height * 0.45;
    final below = hole.center.dy < screen.height / 2;

    final bubble = Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      decoration: BoxDecoration(
        color: p.page,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kGold, width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(step.title, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: p.accent)),
          const SizedBox(height: 4),
          Text(step.body, style: TextStyle(fontSize: 16, height: 1.6, color: p.ink)),
          const SizedBox(height: 6),
          Row(children: [
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: kPrimary, foregroundColor: kCreamGold),
              onPressed: onNext,
              child: Text(isLast ? 'ابدأ' : 'التالي', style: const TextStyle(fontSize: 16)),
            ),
            const Spacer(),
            Text('${arNum(index + 1)} من ${arNum(count)}', style: TextStyle(color: p.muted, fontSize: 14)),
            if (!isLast)
              TextButton(onPressed: onSkip, child: Text('تخطي', style: TextStyle(color: p.muted, fontSize: 15))),
          ]),
        ],
      ),
    );

    return Material(
      type: MaterialType.transparency,
      child: Stack(children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: onNext,
            child: CustomPaint(painter: _HolePainter(hole)),
          ),
        ),
        if (big)
          Positioned(left: 20, right: 20, top: screen.height * 0.35, child: bubble)
        else if (below)
          Positioned(left: 16, right: 16, top: hole.bottom + 12, child: bubble)
        else
          Positioned(left: 16, right: 16, bottom: screen.height - hole.top + 12, child: bubble),
      ]),
    );
  }
}

class _HolePainter extends CustomPainter {
  final Rect hole;
  _HolePainter(this.hole);

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(hole, const Radius.circular(12));
    final shade = Path.combine(
      PathOperation.difference,
      Path()..addRect(Offset.zero & size),
      Path()..addRRect(r),
    );
    canvas.drawPath(shade, Paint()..color = const Color(0xB30A1428));
    if (!hole.isEmpty) {
      canvas.drawRRect(
          r,
          Paint()
            ..color = kGoldLight
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5);
    }
  }

  @override
  bool shouldRepaint(covariant _HolePainter old) => old.hole != hole;
}
