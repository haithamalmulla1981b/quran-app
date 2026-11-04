import 'package:flutter/material.dart';

import 'app_state.dart';
import 'player_bar.dart';
import 'quran_data.dart';
import 'reader_screen.dart';
import 'settings_screen.dart';
import 'theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _open(int s, [int? a]) {
    FocusScope.of(context).unfocus();
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => ReaderScreen(surah: s, initialAyah: a)));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(listenable: app, builder: (context, _) => _build(context));
  }

  Widget _build(BuildContext context) {
    final p = paletteOf(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('القرآن الكريم'),
          leading: IconButton(
            tooltip: 'الوضع الليلي',
            onPressed: app.toggleDark,
            icon: Icon(app.dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
          ),
          actions: [
            IconButton(
              tooltip: 'الإعدادات',
              icon: const Icon(Icons.settings_rounded),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
              child: TextField(
                controller: _search,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'ابحث عن سورة أو آية…',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => setState(() {
                            _search.clear();
                            _query = '';
                          }),
                        ),
                  filled: true,
                  fillColor: p.page,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: p.line)),
                  enabledBorder:
                      OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: p.line)),
                ),
              ),
            ),
            if (_query.trim().isEmpty) ...[
              TabBar(
                labelColor: p.accent,
                indicatorColor: p.accent,
                labelStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                tabs: const [Tab(text: 'السور'), Tab(text: 'العلامات')],
              ),
              Expanded(child: TabBarView(children: [_surahList(), _bookmarks()])),
            ] else
              Expanded(child: _results()),
          ],
        ),
        bottomNavigationBar: const PlayerBar(),
      ),
    );
  }

  Widget _surahList() {
    final last = app.lastRead?.split(':').map(int.parse).toList();
    return ListView.builder(
      padding: const EdgeInsets.only(top: 6, bottom: 16),
      itemCount: 114 + (last != null ? 1 : 0),
      itemBuilder: (context, i) {
        if (last != null && i == 0) return _continueCard(last[0], last[1]);
        return _surahTile(i + (last != null ? 0 : 1));
      },
    );
  }

  Widget _continueCard(int s, int a) {
    final p = paletteOf(context);
    return PageCard(
      color: p.accent.withValues(alpha: 0.12),
      child: ListTile(
        onTap: () => _open(s, a),
        leading: Icon(Icons.menu_book_rounded, color: p.accent, size: 30),
        title: const Text('متابعة القراءة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        subtitle: Text('سورة ${surahNameAr(s)} · آية ${arNum(a)}', style: TextStyle(color: p.muted, fontSize: 15)),
        trailing: Icon(Icons.chevron_left_rounded, color: p.muted),
      ),
    );
  }

  Widget _surahTile(int s) {
    final p = paletteOf(context);
    return PageCard(
      margin: const EdgeInsets.fromLTRB(12, 3, 12, 3),
      child: ListTile(
        onTap: () => _open(s),
        leading: _NumberBadge(s),
        title: Text('سورة ${surahNameAr(s)}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: p.ink)),
        subtitle: Text('${surahNameEn(s)} · ${arNum(ayahCount(s))} آية', style: TextStyle(color: p.muted, fontSize: 14)),
        trailing: IconButton(
          tooltip: 'استماع',
          icon: Icon(Icons.play_circle_outline_rounded, color: p.accent),
          onPressed: () => app.audio.playSurah(s),
        ),
      ),
    );
  }

  Widget _bookmarks() {
    final p = paletteOf(context);
    if (app.bookmarks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('لا توجد علامات بعد.\nاضغط على أي آية لإضافة علامة.',
              textAlign: TextAlign.center, style: TextStyle(color: p.muted, fontSize: 17)),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 6),
      children: [
        for (final k in app.bookmarks.reversed)
          Builder(builder: (context) {
            final parts = k.split(':').map(int.parse).toList();
            return _ayahResult(parts[0], parts[1], onDelete: () => app.toggleBookmark(parts[0], parts[1]));
          }),
      ],
    );
  }

  Widget _results() {
    final p = paletteOf(context);
    final q = normalizeArabic(_query.trim());
    final lq = _query.trim().toLowerCase();
    final surahs = [
      for (var s = 1; s <= 114; s++)
        if (normalizeArabic(surahNameAr(s)).contains(q) ||
            surahNameEn(s).toLowerCase().contains(lq) ||
            s.toString() == lq)
          s,
    ];
    final hits = app.quran.search(_query);
    if (surahs.isEmpty && hits.isEmpty) {
      return Center(
        child: Text('لا توجد نتائج', style: TextStyle(color: p.muted, fontSize: 17)),
      );
    }
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 6),
      children: [
        for (final s in surahs.take(20)) _surahTile(s),
        if (hits.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
            child: Text(
              hits.length >= 60 ? 'أول ٦٠ آية مطابقة' : '${arNum(hits.length)} آية مطابقة',
              style: TextStyle(color: p.muted, fontSize: 14),
            ),
          ),
        for (final h in hits) _ayahResult(h.surah, h.ayah),
      ],
    );
  }

  Widget _ayahResult(int s, int a, {VoidCallback? onDelete}) {
    final p = paletteOf(context);
    return PageCard(
      margin: const EdgeInsets.fromLTRB(12, 3, 12, 3),
      child: InkWell(
        onTap: () => _open(s, a),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('سورة ${surahNameAr(s)} · آية ${arNum(a)}',
                        style: const TextStyle(color: kGold, fontSize: 14, fontWeight: FontWeight.w700)),
                    Text(app.quran.ayah(s, a),
                        maxLines: 3, overflow: TextOverflow.ellipsis, style: quranStyle(22, p.ink)),
                  ],
                ),
              ),
              if (onDelete != null)
                IconButton(
                  tooltip: 'إزالة',
                  icon: Icon(Icons.bookmark_remove_outlined, color: p.muted),
                  onPressed: onDelete,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NumberBadge extends StatelessWidget {
  final int n;
  const _NumberBadge(this.n);

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    return Transform.rotate(
      angle: 0.785398,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: p.accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(9),
        ),
        alignment: Alignment.center,
        child: Transform.rotate(
          angle: -0.785398,
          child: Text(arNum(n), style: TextStyle(color: p.accent, fontWeight: FontWeight.w700, fontSize: 16)),
        ),
      ),
    );
  }
}
