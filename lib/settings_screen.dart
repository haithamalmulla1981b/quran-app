import 'package:flutter/material.dart';

import 'app_state.dart';
import 'audio_controller.dart';
import 'hijri_strip.dart';
import 'quran_data.dart';
import 'theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Future<double> _size = app.audio.savedSizeMb();

  Future<void> _confirmDelete() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف التلاوات المحفوظة؟'),
        content: const Text('سيتم حذف جميع ملفات الصوت من الجهاز. يمكن تنزيلها مرة أخرى عند الاستماع.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف')),
        ],
      ),
    );
    if (yes == true) {
      await app.audio.deleteAll();
      setState(() {
        _size = app.audio.savedSizeMb();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final p = paletteOf(context);
        TextStyle head = TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: p.accent);
        return Scaffold(
          appBar: AppBar(title: const Text('الإعدادات')),
          body: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              Padding(padding: const EdgeInsets.fromLTRB(20, 12, 20, 4), child: Text('القارئ', style: head)),
              PageCard(
                child: Column(children: [
                  for (final r in kReciters)
                    ListTile(
                      title: Text(r.nameAr, style: const TextStyle(fontSize: 18)),
                      trailing: app.audio.reciter.id == r.id
                          ? Icon(Icons.check_circle_rounded, color: p.accent)
                          : Icon(Icons.circle_outlined, color: p.line),
                      onTap: () => app.setReciter(r),
                    ),
                ]),
              ),
              Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 4), child: Text('العرض', style: head)),
              PageCard(
                child: Column(children: [
                  SwitchListTile(
                    title: const Text('الوضع الليلي', style: TextStyle(fontSize: 18)),
                    value: app.dark,
                    onChanged: (_) => app.toggleDark(),
                  ),
                  ListTile(
                    title: const Text('حجم الخط', style: TextStyle(fontSize: 18)),
                    subtitle: Slider(
                      value: app.fontSize,
                      min: 20,
                      max: 44,
                      divisions: 12,
                      onChanged: app.setFontSize,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Text('بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
                        textAlign: TextAlign.center, style: quranStyle(app.fontSize, p.ink)),
                  ),
                ]),
              ),
              Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 4), child: Text('التاريخ الهجري', style: head)),
              PageCard(
                child: ListTile(
                  title: const Text('تعديل التاريخ الهجري', style: TextStyle(fontSize: 18)),
                  subtitle: Text(hijriDateText(DateTime.now(), app.hijriAdjust)),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(
                      onPressed: app.hijriAdjust < 2 ? () => app.setHijriAdjust(app.hijriAdjust + 1) : null,
                      icon: const Icon(Icons.add_circle_outline_rounded),
                    ),
                    Text(app.hijriAdjust == 0
                        ? '٠'
                        : '${app.hijriAdjust > 0 ? '+' : '−'}${arNum(app.hijriAdjust.abs())}',
                        style: const TextStyle(fontSize: 18)),
                    IconButton(
                      onPressed: app.hijriAdjust > -2 ? () => app.setHijriAdjust(app.hijriAdjust - 1) : null,
                      icon: const Icon(Icons.remove_circle_outline_rounded),
                    ),
                  ]),
                ),
              ),
              Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 4), child: Text('التخزين', style: head)),
              PageCard(
                child: FutureBuilder<double>(
                  future: _size,
                  builder: (context, snap) => ListTile(
                    title: const Text('التلاوات المحفوظة', style: TextStyle(fontSize: 18)),
                    subtitle: Text(snap.hasData ? '${snap.data!.toStringAsFixed(1)} MB' : '…'),
                    trailing: TextButton(onPressed: _confirmDelete, child: const Text('حذف الكل')),
                  ),
                ),
              ),
              PageCard(
                child: ListTile(
                  leading: Icon(Icons.help_outline_rounded, color: p.accent),
                  title: const Text('عرض الدليل', style: TextStyle(fontSize: 18)),
                  subtitle: const Text('شرح سريع لأهم الأزرار'),
                  onTap: () {
                    app.resetGuides();
                    Navigator.of(context).pop('guide');
                  },
                ),
              ),
              const SizedBox(height: 28),
              DeveloperCredit(color: p.muted),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}
