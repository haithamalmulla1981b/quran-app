import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

import 'quran_data.dart';

class Reciter {
  final String id; // EveryAyah data folder
  final String nameAr;
  const Reciter(this.id, this.nameAr);
}

const kReciters = [
  Reciter('Alafasy_64kbps', 'مشاري العفاسي'),
  Reciter('Husary_64kbps', 'محمود خليل الحصري'),
  Reciter('Abdul_Basit_Murattal_64kbps', 'عبد الباسط عبد الصمد'),
  Reciter('Minshawy_Murattal_128kbps', 'محمد صديق المنشاوي'),
  Reciter('Abdurrahmaan_As-Sudais_64kbps', 'عبد الرحمن السديس'),
  Reciter('Maher_AlMuaiqly_64kbps', 'ماهر المعيقلي'),
];

enum RepeatMode { off, ayah, surah }

/// Plays per-ayah recitations. Each file is streamed from EveryAyah the first
/// time and saved on the device, so it plays offline from then on.
class AudioController extends ChangeNotifier {
  final AudioPlayer player = AudioPlayer();
  Reciter reciter = kReciters.first;

  int? surah; // surah loaded in the player
  bool _hasBasmala = false; // playlist index 0 is the basmala
  int? currentAyah; // 1-based; null while the basmala plays
  bool loading = false;
  int? loadingSurah;
  String? error;
  RepeatMode repeat = RepeatMode.off;
  double speed = 1.0;

  /// Surah -> download progress (0..1) while a full download runs.
  final Map<int, double> downloading = {};

  AudioController() {
    player.currentIndexStream.listen((i) {
      if (i == null) return;
      currentAyah = _hasBasmala ? (i == 0 ? null : i) : i + 1;
      notifyListeners();
    });
    player.playerStateStream.listen((st) {
      if (st.processingState == ProcessingState.completed) {
        player.pause();
        player.seek(Duration.zero, index: 0);
      }
      notifyListeners();
    });
  }

  bool get playing => player.playing;

  static String fileName(int s, int a) =>
      '${s.toString().padLeft(3, '0')}${a.toString().padLeft(3, '0')}.mp3';

  Uri _url(int s, int a) =>
      Uri.parse('https://everyayah.com/data/${reciter.id}/${fileName(s, a)}');

  Future<Directory> _dir([Reciter? r]) async {
    final base = await getApplicationDocumentsDirectory();
    final d = Directory('${base.path}/audio/${(r ?? reciter).id}');
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  Future<AudioSource> _source(Directory dir, int s, int a) async {
    final f = File('${dir.path}/${fileName(s, a)}');
    if (await f.exists() && await f.length() > 0) {
      return AudioSource.file(f.path);
    }
    // Streams now and writes the file to the cache when fully received.
    return LockCachingAudioSource(_url(s, a), cacheFile: f);
  }

  Future<void> setReciter(Reciter r) async {
    if (r.id == reciter.id) return;
    final wasSurah = surah;
    final wasAyah = currentAyah ?? 1;
    final wasPlaying = playing;
    reciter = r;
    await player.stop();
    surah = null;
    currentAyah = null;
    notifyListeners();
    if (wasSurah != null && wasPlaying) {
      await playSurah(wasSurah, fromAyah: wasAyah);
    }
  }

  Future<void> playSurah(int s, {int fromAyah = 1}) async {
    loading = true;
    loadingSurah = s;
    error = null;
    notifyListeners();
    try {
      final dir = await _dir();
      final children = <AudioSource>[];
      _hasBasmala = s != 1 && s != 9;
      if (_hasBasmala) children.add(await _source(dir, 1, 1));
      for (var a = 1; a <= ayahCount(s); a++) {
        children.add(await _source(dir, s, a));
      }
      final start = _hasBasmala ? (fromAyah <= 1 ? 0 : fromAyah) : fromAyah - 1;
      await player.setAudioSource(
        ConcatenatingAudioSource(children: children),
        initialIndex: start,
      );
      surah = s;
      await _applyLoop();
      await player.setSpeed(speed);
      loading = false;
      notifyListeners();
      unawaited(player.play());
    } catch (e) {
      loading = false;
      error = 'تعذر تشغيل التلاوة. تحقق من الاتصال بالإنترنت.';
      notifyListeners();
    }
  }

  Future<void> togglePlay(int s) async {
    if (surah != s) return playSurah(s);
    if (playing) {
      await player.pause();
    } else {
      unawaited(player.play());
    }
  }

  Future<void> next() => player.hasNext ? player.seekToNext() : Future<void>.value();
  Future<void> previous() =>
      player.hasPrevious ? player.seekToPrevious() : Future<void>.value();

  Future<void> cycleRepeat() async {
    repeat = RepeatMode.values[(repeat.index + 1) % RepeatMode.values.length];
    await _applyLoop();
    notifyListeners();
  }

  Future<void> _applyLoop() => player.setLoopMode(switch (repeat) {
        RepeatMode.off => LoopMode.off,
        RepeatMode.ayah => LoopMode.one,
        RepeatMode.surah => LoopMode.all,
      });

  Future<void> cycleSpeed() async {
    const speeds = [0.75, 1.0, 1.25, 1.5];
    speed = speeds[(speeds.indexOf(speed) + 1) % speeds.length];
    await player.setSpeed(speed);
    notifyListeners();
  }

  // ---------- Offline downloads ----------

  /// Number of this surah's ayah files already saved for the current reciter.
  Future<int> savedCount(int s) async {
    final dir = await _dir();
    final prefix = s.toString().padLeft(3, '0');
    var n = 0;
    await for (final e in dir.list()) {
      final name = e.uri.pathSegments.last;
      if (name.length == 10 && name.startsWith(prefix) && name.endsWith('.mp3')) n++;
    }
    return n;
  }

  Future<bool> isSaved(int s) async => await savedCount(s) >= ayahCount(s);

  /// Downloads every ayah of the surah (plus the basmala) for offline use.
  Future<bool> downloadSurah(int s) async {
    if (downloading.containsKey(s)) return false;
    downloading[s] = 0;
    notifyListeners();
    final dir = await _dir();
    final items = <List<int>>[
      if (s != 1 && s != 9) [1, 1],
      for (var a = 1; a <= ayahCount(s); a++) [s, a],
    ];
    final client = http.Client();
    var ok = true;
    try {
      for (var i = 0; i < items.length; i++) {
        final f = File('${dir.path}/${fileName(items[i][0], items[i][1])}');
        if (!(await f.exists() && await f.length() > 0)) {
          final res = await client.get(_url(items[i][0], items[i][1]));
          if (res.statusCode != 200) throw HttpException('HTTP ${res.statusCode}');
          final tmp = File('${f.path}.tmp');
          await tmp.writeAsBytes(res.bodyBytes, flush: true);
          await tmp.rename(f.path);
        }
        downloading[s] = (i + 1) / items.length;
        notifyListeners();
      }
    } catch (_) {
      ok = false;
    } finally {
      client.close();
      downloading.remove(s);
      notifyListeners();
    }
    return ok;
  }

  /// Total size of saved audio for all reciters, in MB.
  Future<double> savedSizeMb() async {
    final base = await getApplicationDocumentsDirectory();
    final d = Directory('${base.path}/audio');
    if (!await d.exists()) return 0;
    var bytes = 0;
    await for (final e in d.list(recursive: true)) {
      if (e is File) bytes += await e.length();
    }
    return bytes / (1024 * 1024);
  }

  Future<void> deleteAll() async {
    await player.stop();
    surah = null;
    currentAyah = null;
    final base = await getApplicationDocumentsDirectory();
    final d = Directory('${base.path}/audio');
    if (await d.exists()) await d.delete(recursive: true);
    notifyListeners();
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }
}
