import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import 'app_state.dart';
import 'player_bar.dart';
import 'quran_data.dart';
import 'theme.dart';

class ReaderScreen extends StatefulWidget {
  final int surah;
  final int? initialAyah;
  const ReaderScreen({super.key, required this.surah, this.initialAyah});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  final _scroll = ItemScrollController();
  final _positions = ItemPositionsListener.create();
  late final SurahView _view = app.quran.view(widget.surah);
  int? _followed;
  int? _flash;
  Timer? _saveTimer;
  late final List<List<int>> _chunks = _buildChunks(); // page view: ayah numbers per paragraph
  late final List<int> _chunkOf = _buildChunkIndex(); // ayah -> list index
  final Map<int, TapGestureRecognizer> _taps = {};

  /// Splits the surah into paragraphs of roughly equal length so the list
  /// can scroll to the ayah being recited.
  List<List<int>> _buildChunks() {
    final out = <List<int>>[];
    var cur = <int>[];
    var len = 0;
    for (var a = 1; a <= _view.ayahs.length; a++) {
      cur.add(a);
      len += _view.ayahs[a - 1].length;
      if (len >= 420) {
        out.add(cur);
        cur = <int>[];
        len = 0;
      }
    }
    if (cur.isNotEmpty) out.add(cur);
    return out;
  }

  List<int> _buildChunkIndex() {
    final idx = List<int>.filled(_view.ayahs.length + 1, 0);
    for (var c = 0; c < _chunks.length; c++) {
      for (final a in _chunks[c]) {
        idx[a] = c + 1; // list index 0 is the header
      }
    }
    return idx;
  }

  /// List index that holds this ayah in the current layout.
  int _indexOf(int a) => app.pageView ? _chunkOf[a] : a;

  int get s => widget.surah;

  @override
  void initState() {
    super.initState();
    app.audio.addListener(_followAudio);
    _positions.itemPositions.addListener(_onScroll);
    if (widget.initialAyah != null) {
      _flash = widget.initialAyah;
      Future.delayed(const Duration(milliseconds: 1600), () {
        if (mounted) setState(() => _flash = null);
      });
    }
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    app.audio.removeListener(_followAudio);
    _positions.itemPositions.removeListener(_onScroll);
    for (final t in _taps.values) {
      t.dispose();
    }
    super.dispose();
  }

  /// Keeps the ayah being recited on screen.
  void _followAudio() {
    final a = app.audio;
    if (a.surah != s || a.currentAyah == null || a.currentAyah == _followed) return;
    _followed = a.currentAyah;
    if (_scroll.isAttached) {
      _scroll.scrollTo(
        index: _indexOf(a.currentAyah!), // index 0 is the surah header
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
        alignment: 0.15,
      );
    }
  }

  /// Remembers the first visible ayah as "last read".
  void _onScroll() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 900), () {
      final visible = _positions.itemPositions.value.where((p) => p.itemTrailingEdge > 0.1);
      if (visible.isEmpty || !mounted) return;
      final first = visible.map((p) => p.index).reduce((x, y) => x < y ? x : y);
      final ayah = first < 1 ? 1 : (app.pageView ? _chunks[first - 1].first : first);
      app.setLastRead(s, ayah);
    });
  }

  void _showAyahActions(int a) {
    final p = paletteOf(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: p.page,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Text('سورة ${surahNameAr(s)} · آية ${arNum(a)}',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: p.accent)),
            ),
            ListTile(
              leading: const Icon(Icons.play_circle_outline_rounded),
              title: const Text('الاستماع من هذه الآية'),
              onTap: () {
                Navigator.pop(ctx);
                app.audio.playSurah(s, fromAyah: a);
              },
            ),
            ListTile(
              leading: Icon(app.isBookmarked(s, a) ? Icons.bookmark_remove_outlined : Icons.bookmark_add_outlined),
              title: Text(app.isBookmarked(s, a) ? 'إزالة العلامة' : 'إضافة علامة'),
              onTap: () {
                Navigator.pop(ctx);
                app.toggleBookmark(s, a);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy_rounded),
              title: const Text('نسخ الآية'),
              onTap: () async {
                Navigator.pop(ctx);
                await Clipboard.setData(ClipboardData(
                    text: '${_view.ayahs[a - 1]} ﴿${arNum(a)}﴾\n[سورة ${surahNameAr(s)}: ${arNum(a)}]'));
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم النسخ')));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showFontSize() {
    showModalBottomSheet(
      context: context,
      backgroundColor: paletteOf(context).page,
      builder: (ctx) => ListenableBuilder(
        listenable: app,
        builder: (ctx, _) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('حجم الخط', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              Slider(
                value: app.fontSize,
                min: 20,
                max: 44,
                divisions: 12,
                label: app.fontSize.round().toString(),
                onChanged: app.setFontSize,
              ),
            ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(listenable: app, builder: (context, _) => Scaffold(
      appBar: AppBar(
        title: Text('سورة ${surahNameAr(s)}'),
        actions: [
          IconButton(
            tooltip: app.pageView ? 'عرض الآيات منفصلة' : 'عرض المصحف',
            onPressed: app.togglePageView,
            icon: Icon(app.pageView ? Icons.view_agenda_outlined : Icons.menu_book_rounded),
          ),
          _DownloadButton(surah: s),
          IconButton(tooltip: 'حجم الخط', onPressed: _showFontSize, icon: const Icon(Icons.text_fields_rounded)),
        ],
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([app, app.audio]),
        builder: (context, _) => ScrollablePositionedList.builder(
          itemScrollController: _scroll,
          itemPositionsListener: _positions,
          initialScrollIndex: widget.initialAyah == null ? 0 : _indexOf(widget.initialAyah!),
          initialAlignment: widget.initialAyah != null ? 0.1 : 0,
          padding: const EdgeInsets.only(bottom: 24),
          itemCount: (app.pageView ? _chunks.length : _view.ayahs.length) + 1,
          itemBuilder: (context, i) => i == 0
              ? _header(context)
              : (app.pageView ? _paragraph(context, i - 1) : _ayah(context, i)),
        ),
      ),
      bottomNavigationBar: PlayerBar(surah: s, full: true),
    ));
  }

  Widget _header(BuildContext context) {
    final p = paletteOf(context);
    return PageCard(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: kGold, width: 2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(children: [
              Text('سورة ${surahNameAr(s)}',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: p.accent)),
              Text('${surahNameEn(s)} · ${arNum(ayahCount(s))} آية',
                  style: TextStyle(fontSize: 14, color: p.muted)),
            ]),
          ),
          if (_view.basmala != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(_view.basmala!,
                  textAlign: TextAlign.center, style: quranStyle(app.fontSize * 0.95, p.ink)),
            ),
        ]),
      ),
    );
  }

  /// Page view: ayahs flow together; the recited ayah is highlighted in place.
  Widget _paragraph(BuildContext context, int c) {
    final p = paletteOf(context);
    final first = c == 0, last = c == _chunks.length - 1;
    final base = quranStyle(app.fontSize, p.ink);
    final spans = <InlineSpan>[];
    for (final a in _chunks[c]) {
      final playing = app.audio.surah == s && app.audio.currentAyah == a;
      final hl = playing || _flash == a;
      final bg = hl ? p.highlight : null;
      final tap = _taps.putIfAbsent(a, () => TapGestureRecognizer()..onTap = () => _showAyahActions(a));
      spans.add(TextSpan(
        text: _view.ayahs[a - 1],
        style: base.copyWith(backgroundColor: bg),
        recognizer: tap,
      ));
      spans.add(TextSpan(
        text: '\u00A0﴿${arNum(a)}﴾',
        style: quranStyle(app.fontSize * 0.85, app.isBookmarked(s, a) ? p.accent : kGold)
            .copyWith(backgroundColor: bg),
        recognizer: tap,
      ));
      spans.add(TextSpan(text: ' ', style: base));
    }
    return Container(
      margin: EdgeInsets.fromLTRB(12, first ? 4 : 0, 12, last ? 8 : 0),
      padding: EdgeInsets.fromLTRB(16, first ? 12 : 0, 16, last ? 14 : 0),
      decoration: BoxDecoration(
        color: p.page,
        border: Border(
          left: BorderSide(color: p.line),
          right: BorderSide(color: p.line),
          top: first ? BorderSide(color: p.line) : BorderSide.none,
          bottom: last ? BorderSide(color: p.line) : BorderSide.none,
        ),
      ),
      child: Text.rich(TextSpan(children: spans), textAlign: TextAlign.justify),
    );
  }

  Widget _ayah(BuildContext context, int a) {
    final p = paletteOf(context);
    final playingThis = app.audio.surah == s && app.audio.currentAyah == a;
    final bookmarked = app.isBookmarked(s, a);
    final bg = playingThis || _flash == a ? p.highlight : p.page;
    return PageCard(
      color: bg,
      child: InkWell(
        onTap: () => _showAyahActions(a),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text.rich(
                TextSpan(children: [
                  TextSpan(text: _view.ayahs[a - 1], style: quranStyle(app.fontSize, p.ink)),
                  TextSpan(text: ' ﴿${arNum(a)}﴾', style: quranStyle(app.fontSize * 0.85, kGold)),
                ]),
                textAlign: TextAlign.start,
              ),
              Row(children: [
                Text('${arNum(s)}:${arNum(a)}', style: const TextStyle(fontSize: 13, color: kGold)),
                const Spacer(),
                if (bookmarked) const Icon(Icons.bookmark_rounded, size: 18, color: kGold),
                if (playingThis) Icon(Icons.graphic_eq_rounded, size: 18, color: p.accent),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

/// Saves the whole surah's audio for offline listening.
class _DownloadButton extends StatefulWidget {
  final int surah;
  const _DownloadButton({required this.surah});

  @override
  State<_DownloadButton> createState() => _DownloadButtonState();
}

class _DownloadButtonState extends State<_DownloadButton> {
  late Future<bool> _saved = app.audio.isSaved(widget.surah);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app.audio,
      builder: (context, _) {
        final progress = app.audio.downloading[widget.surah];
        if (progress != null) {
          return Padding(
            padding: const EdgeInsets.all(14),
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(value: progress, strokeWidth: 3, color: Colors.white),
            ),
          );
        }
        return FutureBuilder<bool>(
          future: _saved,
          builder: (context, snap) {
            if (snap.data == true) {
              return const IconButton(
                tooltip: 'محفوظة للاستماع دون إنترنت',
                onPressed: null,
                icon: Icon(Icons.download_done_rounded, color: Colors.white),
              );
            }
            return IconButton(
              tooltip: 'تنزيل السورة',
              icon: const Icon(Icons.download_rounded),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final ok = await app.audio.downloadSurah(widget.surah);
                messenger.showSnackBar(SnackBar(
                  content: Text(ok ? 'تم حفظ السورة للاستماع دون إنترنت' : 'تعذر التنزيل. تحقق من الاتصال.'),
                ));
                if (mounted) {
                  setState(() {
                    _saved = app.audio.isSaved(widget.surah);
                  });
                }
              },
            );
          },
        );
      },
    );
  }
}
