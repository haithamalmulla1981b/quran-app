import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter/services.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import 'app_state.dart';
import 'coach_marks.dart';
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
  final Map<int, TapGestureRecognizer> _taps = {};
  final _viewKey = GlobalKey(), _downloadKey = GlobalKey(), _fontKey = GlobalKey();
  final _bodyKey = GlobalKey(), _playKey = GlobalKey(), _repeatKey = GlobalKey();

  // Page view: one continuous text; each ayah's rosette carries a key so the
  // page can scroll to the ayah being recited.
  final _pageScroll = ScrollController();
  final Map<int, GlobalKey> _marks = {};
  GlobalKey _mark(int a) => _marks.putIfAbsent(a, () => GlobalKey());
  Timer? _pageSaveTimer;

  int get s => widget.surah;

  @override
  void initState() {
    super.initState();
    app.audio.addListener(_followAudio);
    _positions.itemPositions.addListener(_onScroll);
    if (!app.guideReaderSeen) {
      Future.delayed(const Duration(milliseconds: 800), _showGuide);
    }
    if (app.pageView && widget.initialAyah != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _marks[widget.initialAyah!]?.currentContext;
        if (ctx != null) Scrollable.ensureVisible(ctx, alignment: 0.35);
      });
    }
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
    _pageSaveTimer?.cancel();
    _pageScroll.dispose();
    app.audio.removeListener(_followAudio);
    _positions.itemPositions.removeListener(_onScroll);
    for (final t in _taps.values) {
      t.dispose();
    }
    super.dispose();
  }

  Future<void> _showGuide() async {
    if (!mounted) return;
    app.markGuideReader();
    await showCoachMarks(context, [
      CoachStep(_bodyKey, 'الآيات', 'اضغط على أي آية للاستماع منها، أو لإضافة علامة، أو لنسخها.'),
      CoachStep(_playKey, 'التشغيل', 'استمع إلى التلاوة. تُظلَّل الآية المقروءة، ويستمر الصوت في الخلفية مع إشعار للتحكم.'),
      CoachStep(_repeatKey, 'التكرار', 'اضغط لتكرار الآية أو السورة، وهو مفيد للحفظ. وبجانبه زر سرعة التلاوة.'),
      CoachStep(_viewKey, 'طريقة العرض', 'بدّل بين عرض المصحف المتصل وعرض كل آية في بطاقة.'),
      CoachStep(_downloadKey, 'تنزيل السورة', 'احفظ تلاوة السورة كاملة للاستماع دون إنترنت.'),
      CoachStep(_fontKey, 'حجم الخط', 'كبّر الخط أو صغّره بما يريح عينيك.'),
    ]);
  }

  DateTime _userScrolledAt = DateTime.fromMillisecondsSinceEpoch(0);

  /// Keeps the ayah being recited on screen. Scrolls only when it has left
  /// the visible area, and never while the reader is scrolling by hand.
  void _followAudio() {
    final a = app.audio;
    if (a.surah != s || a.currentAyah == null || a.currentAyah == _followed) return;
    _followed = a.currentAyah;
    if (DateTime.now().difference(_userScrolledAt) < const Duration(seconds: 5)) return;
    if (app.pageView) {
      _followPage(a.currentAyah!);
      return;
    }
    if (!_scroll.isAttached) return;
    final index = a.currentAyah!; // index 0 is the surah header
    for (final p in _positions.itemPositions.value) {
      if (p.index != index) continue;
      // Already comfortably visible: leave the page still.
      if (p.itemLeadingEdge >= 0 && p.itemLeadingEdge < 0.6 && (app.pageView || p.itemTrailingEdge <= 0.85)) {
        return;
      }
    }
    _scroll.scrollTo(
      index: index,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      alignment: 0.08,
    );
  }

  /// Page view: scroll only when the recited ayah's marker leaves the
  /// comfortable reading band of the screen.
  void _followPage(int ayah) {
    final ctx = _marks[ayah]?.currentContext;
    final box = ctx?.findRenderObject();
    if (ctx == null || box is! RenderBox || !box.attached) return;
    final y = box.localToGlobal(Offset.zero).dy;
    final h = MediaQuery.of(context).size.height;
    if (y > h * 0.2 && y < h * 0.72) return;
    Scrollable.ensureVisible(ctx,
        alignment: 0.45, duration: const Duration(milliseconds: 600), curve: Curves.easeOutCubic);
  }

  /// Page view: remembers the first ayah whose marker is below the top bar.
  void _savePagePosition() {
    _pageSaveTimer?.cancel();
    _pageSaveTimer = Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      final top = MediaQuery.of(context).padding.top + kToolbarHeight + 8;
      for (var a = 1; a <= _view.ayahs.length; a++) {
        final box = _marks[a]?.currentContext?.findRenderObject();
        if (box is RenderBox && box.attached && box.localToGlobal(Offset.zero).dy > top) {
          app.setLastRead(s, a);
          return;
        }
      }
    });
  }

  bool _onUserScroll(UserScrollNotification n) {
    if (n.direction != ScrollDirection.idle) _userScrolledAt = DateTime.now();
    return false;
  }

  /// Remembers the first visible ayah as "last read".
  void _onScroll() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 900), () {
      final visible = _positions.itemPositions.value.where((p) => p.itemTrailingEdge > 0.1);
      if (visible.isEmpty || !mounted) return;
      final first = visible.map((p) => p.index).reduce((x, y) => x < y ? x : y);
      final ayah = first < 1 ? 1 : first;
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
            key: _viewKey,
            tooltip: app.pageView ? 'عرض الآيات منفصلة' : 'عرض المصحف',
            onPressed: app.togglePageView,
            icon: Icon(app.pageView ? Icons.view_agenda_outlined : Icons.menu_book_rounded),
          ),
          KeyedSubtree(key: _downloadKey, child: _DownloadButton(surah: s)),
          IconButton(key: _fontKey, tooltip: 'حجم الخط', onPressed: _showFontSize, icon: const Icon(Icons.text_fields_rounded)),
        ],
      ),
      body: ListenableBuilder(
        key: _bodyKey,
        listenable: Listenable.merge([app, app.audio]),
        builder: (context, _) => NotificationListener<UserScrollNotification>(
          onNotification: _onUserScroll,
          child: app.pageView
              ? NotificationListener<ScrollEndNotification>(
                  onNotification: (_) {
                    _savePagePosition();
                    return false;
                  },
                  child: SingleChildScrollView(
                    controller: _pageScroll,
                    padding: const EdgeInsets.only(bottom: 24),
                    child: _page(context),
                  ),
                )
              : ScrollablePositionedList.builder(
          itemScrollController: _scroll,
          itemPositionsListener: _positions,
          initialScrollIndex: widget.initialAyah ?? 0,
          initialAlignment: widget.initialAyah != null ? 0.1 : 0,
          padding: const EdgeInsets.only(bottom: 24),
          itemCount: _view.ayahs.length + 1,
          itemBuilder: (context, i) => i == 0 ? _header(context) : _ayah(context, i),
          ),
        ),
      ),
      bottomNavigationBar: PlayerBar(surah: s, full: true, playKey: _playKey, repeatKey: _repeatKey),
    ));
  }

  Widget _header(BuildContext context) {
    final p = paletteOf(context);
    return FrameSlice(
      first: true,
      last: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Column(children: [
          SurahCartouche(s),
          if (_view.basmala != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_view.basmala!,
                  textAlign: TextAlign.center, style: quranStyle(app.fontSize * 0.95, p.ink)),
            ),
        ]),
      ),
    );
  }

  /// Page view: the whole surah as one continuous, justified text inside the
  /// illuminated frame. The recited ayah is highlighted in place.
  Widget? _pageCache;
  String _pageSig = '';

  Widget _page(BuildContext context) {
    final p = paletteOf(context);
    // Rebuild the long text only when something visible changed.
    final cur = app.audio.surah == s ? app.audio.currentAyah : null;
    final sig = '$cur|$_flash|${app.fontSize}|${app.dark}|${app.bookmarks.length}|${app.bookmarks.join(',')}';
    if (_pageCache != null && sig == _pageSig) return _pageCache!;
    _pageSig = sig;
    final base = quranStyle(app.fontSize, p.ink);
    final spans = <InlineSpan>[];
    for (var a = 1; a <= _view.ayahs.length; a++) {
      final playing = app.audio.surah == s && app.audio.currentAyah == a;
      final bg = playing || _flash == a ? p.highlight : null;
      final tap = _taps.putIfAbsent(a, () => TapGestureRecognizer()..onTap = () => _showAyahActions(a));
      spans.add(TextSpan(text: _view.ayahs[a - 1], style: base.copyWith(backgroundColor: bg), recognizer: tap));
      final ayah = a;
      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: GestureDetector(
          key: _mark(ayah),
          onTap: () => _showAyahActions(ayah),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Rosette(ayah, size: app.fontSize * 1.1, active: playing || app.isBookmarked(s, ayah)),
          ),
        ),
      ));
      spans.add(TextSpan(text: ' ', style: base));
    }
    return _pageCache = FrameSlice(
      first: true,
      last: true,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SurahCartouche(s),
        if (_view.basmala != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_view.basmala!, textAlign: TextAlign.center, style: quranStyle(app.fontSize * 0.95, p.ink)),
          ),
        const SizedBox(height: 6),
        Text.rich(TextSpan(children: spans), textAlign: TextAlign.justify),
      ]),
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
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Rosette(a, size: app.fontSize * 1.1, active: playingThis || bookmarked),
                    ),
                  ),
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
              child: CircularProgressIndicator(value: progress, strokeWidth: 3, color: kCreamGold),
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
                icon: Icon(Icons.download_done_rounded, color: kCreamGold),
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
