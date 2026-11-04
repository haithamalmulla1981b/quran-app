import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'audio_controller.dart';
import 'quran_data.dart';

/// App-wide state: text, audio and saved preferences.
class AppState extends ChangeNotifier {
  late final QuranData quran;
  final AudioController audio = AudioController();
  late final SharedPreferences _prefs;

  bool dark = false;
  double fontSize = 28;
  bool pageView = true; // continuous Mushaf-style text
  bool guideHomeSeen = false;
  bool guideReaderSeen = false;
  List<String> bookmarks = []; // "s:a"
  String? lastRead; // "s:a"

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    quran = await QuranData.load();
    dark = _prefs.getBool('dark') ?? false;
    fontSize = _prefs.getDouble('fontSize') ?? 28;
    pageView = _prefs.getBool('pageView') ?? true;
    guideHomeSeen = _prefs.getBool('guideHome') ?? false;
    guideReaderSeen = _prefs.getBool('guideReader') ?? false;
    bookmarks = _prefs.getStringList('bookmarks') ?? [];
    lastRead = _prefs.getString('lastRead');
    final rid = _prefs.getString('reciter');
    for (final r in kReciters) {
      if (r.id == rid) audio.reciter = r;
    }
    notifyListeners();
  }

  void toggleDark() {
    dark = !dark;
    _prefs.setBool('dark', dark);
    notifyListeners();
  }

  void markGuideHome() {
    guideHomeSeen = true;
    _prefs.setBool('guideHome', true);
  }

  void markGuideReader() {
    guideReaderSeen = true;
    _prefs.setBool('guideReader', true);
  }

  void resetGuides() {
    guideHomeSeen = false;
    guideReaderSeen = false;
    _prefs.setBool('guideHome', false);
    _prefs.setBool('guideReader', false);
  }

  void togglePageView() {
    pageView = !pageView;
    _prefs.setBool('pageView', pageView);
    notifyListeners();
  }

  void setFontSize(double v) {
    fontSize = v;
    _prefs.setDouble('fontSize', v);
    notifyListeners();
  }

  bool isBookmarked(int s, int a) => bookmarks.contains('$s:$a');

  void toggleBookmark(int s, int a) {
    final k = '$s:$a';
    if (bookmarks.contains(k)) {
      bookmarks.remove(k);
    } else {
      bookmarks.add(k);
    }
    _prefs.setStringList('bookmarks', bookmarks);
    notifyListeners();
  }

  void setLastRead(int s, int a) {
    lastRead = '$s:$a';
    _prefs.setString('lastRead', lastRead!);
    notifyListeners();
  }

  Future<void> setReciter(Reciter r) async {
    _prefs.setString('reciter', r.id);
    await audio.setReciter(r);
    notifyListeners();
  }
}

final app = AppState();
