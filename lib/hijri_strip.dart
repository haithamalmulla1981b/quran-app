import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';

import 'app_state.dart';
import 'quran_data.dart';
import 'theme.dart';

const _hijriMonths = [
  'محرم', 'صفر', 'ربيع الأول', 'ربيع الآخر', 'جمادى الأولى', 'جمادى الآخرة',
  'رجب', 'شعبان', 'رمضان', 'شوال', 'ذو القعدة', 'ذو الحجة',
];
const _gregMonths = [
  'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
  'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
];
const _weekdays = ['الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];

/// Hijri date (Umm al-Qura), shifted by the user's adjustment in days.
String hijriDateText(DateTime now, int adjust) {
  final h = HijriCalendar.fromDate(now.add(Duration(days: adjust)));
  return '${arNum(h.hDay)} ${_hijriMonths[h.hMonth - 1]} ${arNum(h.hYear)} هـ';
}

/// One-line date strip: weekday · Hijri date · Gregorian day and month.
class HijriStrip extends StatelessWidget {
  const HijriStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    final now = DateTime.now();
    final dot = Text(' · ', style: TextStyle(color: kGold, fontSize: 16));
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 2, 12, 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(
        color: p.page,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kGold),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(_weekdays[now.weekday - 1], style: const TextStyle(fontSize: 15, color: kTurquoise)),
          dot,
          Text(hijriDateText(now, app.hijriAdjust),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: p.accent)),
          dot,
          Text('${arNum(now.day)} ${_gregMonths[now.month - 1]}', style: TextStyle(fontSize: 14, color: p.muted)),
        ]),
      ),
    );
  }
}
