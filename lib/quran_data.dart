import 'package:flutter/services.dart' show rootBundle;

/// Surah index: [arabic name, transliteration, ayah count].
const List<List<Object>> kSurahs = [
  ['الفاتحة', 'Al-Fatihah', 7], ['البقرة', 'Al-Baqarah', 286], ['آل عمران', 'Al-Imran', 200], ['النساء', 'An-Nisa', 176],
  ['المائدة', "Al-Ma'idah", 120], ['الأنعام', "Al-An'am", 165], ['الأعراف', "Al-A'raf", 206], ['الأنفال', 'Al-Anfal', 75],
  ['التوبة', 'At-Tawbah', 129], ['يونس', 'Yunus', 109], ['هود', 'Hud', 123], ['يوسف', 'Yusuf', 111],
  ['الرعد', "Ar-Ra'd", 43], ['إبراهيم', 'Ibrahim', 52], ['الحجر', 'Al-Hijr', 99], ['النحل', 'An-Nahl', 128],
  ['الإسراء', 'Al-Isra', 111], ['الكهف', 'Al-Kahf', 110], ['مريم', 'Maryam', 98], ['طه', 'Taha', 135],
  ['الأنبياء', 'Al-Anbiya', 112], ['الحج', 'Al-Hajj', 78], ['المؤمنون', "Al-Mu'minun", 118], ['النور', 'An-Nur', 64],
  ['الفرقان', 'Al-Furqan', 77], ['الشعراء', "Ash-Shu'ara", 227], ['النمل', 'An-Naml', 93], ['القصص', 'Al-Qasas', 88],
  ['العنكبوت', 'Al-Ankabut', 69], ['الروم', 'Ar-Rum', 60], ['لقمان', 'Luqman', 34], ['السجدة', 'As-Sajdah', 30],
  ['الأحزاب', 'Al-Ahzab', 73], ['سبأ', 'Saba', 54], ['فاطر', 'Fatir', 45], ['يس', 'Ya-Sin', 83],
  ['الصافات', 'As-Saffat', 182], ['ص', 'Sad', 88], ['الزمر', 'Az-Zumar', 75], ['غافر', 'Ghafir', 85],
  ['فصلت', 'Fussilat', 54], ['الشورى', 'Ash-Shura', 53], ['الزخرف', 'Az-Zukhruf', 89], ['الدخان', 'Ad-Dukhan', 59],
  ['الجاثية', 'Al-Jathiyah', 37], ['الأحقاف', 'Al-Ahqaf', 35], ['محمد', 'Muhammad', 38], ['الفتح', 'Al-Fath', 29],
  ['الحجرات', 'Al-Hujurat', 18], ['ق', 'Qaf', 45], ['الذاريات', 'Adh-Dhariyat', 60], ['الطور', 'At-Tur', 49],
  ['النجم', 'An-Najm', 62], ['القمر', 'Al-Qamar', 55], ['الرحمن', 'Ar-Rahman', 78], ['الواقعة', "Al-Waqi'ah", 96],
  ['الحديد', 'Al-Hadid', 29], ['المجادلة', 'Al-Mujadilah', 22], ['الحشر', 'Al-Hashr', 24], ['الممتحنة', 'Al-Mumtahanah', 13],
  ['الصف', 'As-Saff', 14], ['الجمعة', "Al-Jumu'ah", 11], ['المنافقون', 'Al-Munafiqun', 11], ['التغابن', 'At-Taghabun', 18],
  ['الطلاق', 'At-Talaq', 12], ['التحريم', 'At-Tahrim', 12], ['الملك', 'Al-Mulk', 30], ['القلم', 'Al-Qalam', 52],
  ['الحاقة', 'Al-Haqqah', 52], ['المعارج', "Al-Ma'arij", 44], ['نوح', 'Nuh', 28], ['الجن', 'Al-Jinn', 28],
  ['المزمل', 'Al-Muzzammil', 20], ['المدثر', 'Al-Muddaththir', 56], ['القيامة', 'Al-Qiyamah', 40], ['الإنسان', 'Al-Insan', 31],
  ['المرسلات', 'Al-Mursalat', 50], ['النبأ', 'An-Naba', 40], ['النازعات', "An-Nazi'at", 46], ['عبس', 'Abasa', 42],
  ['التكوير', 'At-Takwir', 29], ['الانفطار', 'Al-Infitar', 19], ['المطففين', 'Al-Mutaffifin', 36], ['الانشقاق', 'Al-Inshiqaq', 25],
  ['البروج', 'Al-Buruj', 22], ['الطارق', 'At-Tariq', 17], ['الأعلى', "Al-A'la", 19], ['الغاشية', 'Al-Ghashiyah', 26],
  ['الفجر', 'Al-Fajr', 30], ['البلد', 'Al-Balad', 20], ['الشمس', 'Ash-Shams', 15], ['الليل', 'Al-Layl', 21],
  ['الضحى', 'Ad-Duha', 11], ['الشرح', 'Ash-Sharh', 8], ['التين', 'At-Tin', 8], ['العلق', 'Al-Alaq', 19],
  ['القدر', 'Al-Qadr', 5], ['البينة', 'Al-Bayyinah', 8], ['الزلزلة', 'Az-Zalzalah', 8], ['العاديات', 'Al-Adiyat', 11],
  ['القارعة', "Al-Qari'ah", 11], ['التكاثر', 'At-Takathur', 8], ['العصر', 'Al-Asr', 3], ['الهمزة', 'Al-Humazah', 9],
  ['الفيل', 'Al-Fil', 5], ['قريش', 'Quraysh', 4], ['الماعون', "Al-Ma'un", 7], ['الكوثر', 'Al-Kawthar', 3],
  ['الكافرون', 'Al-Kafirun', 6], ['النصر', 'An-Nasr', 3], ['المسد', 'Al-Masad', 5], ['الإخلاص', 'Al-Ikhlas', 4],
  ['الفلق', 'Al-Falaq', 5], ['الناس', 'An-Nas', 6],
];

String surahNameAr(int s) => kSurahs[s - 1][0] as String;
String surahNameEn(int s) => kSurahs[s - 1][1] as String;
int ayahCount(int s) => kSurahs[s - 1][2] as int;

const _arDigits = '٠١٢٣٤٥٦٧٨٩';
String arNum(int n) =>
    n.toString().split('').map((d) => _arDigits[int.parse(d)]).join();

final _marks = RegExp(r'[ؐ-ًؚ-ٰٟۖ-ۭـ]');

/// Diacritic-insensitive form of Arabic text, used only for searching.
String normalizeArabic(String s) => s
    .replaceAll(_marks, '')
    .replaceAll(RegExp('[ٱأإآ]'), 'ا')
    .replaceAll('ى', 'ي')
    .replaceAll('ة', 'ه')
    .replaceAll('ؤ', 'و')
    .replaceAll('ئ', 'ي')
    .toLowerCase();

class SurahView {
  final String? basmala;
  final List<String> ayahs;
  SurahView(this.basmala, this.ayahs);
}

class SearchHit {
  final int surah, ayah;
  final String text;
  SearchHit(this.surah, this.ayah, this.text);
}

/// Quran text loaded verbatim from the Tanzil file in assets.
class QuranData {
  final List<List<String>> _text; // [surah-1][ayah-1], verbatim
  final List<List<String>> _norm;
  QuranData._(this._text, this._norm);

  static Future<QuranData> load() async {
    final raw = await rootBundle.loadString('assets/quran-uthmani.txt');
    final text = List.generate(114, (_) => <String>[]);
    for (final line in raw.split('\n')) {
      final l = line.trimRight();
      if (l.isEmpty || l.startsWith('#')) continue;
      final p1 = l.indexOf('|');
      final p2 = l.indexOf('|', p1 + 1);
      if (p1 < 0 || p2 < 0) continue;
      final s = int.parse(l.substring(0, p1));
      text[s - 1].add(l.substring(p2 + 1));
    }
    final norm = [for (final s in text) [for (final a in s) normalizeArabic(a)]];
    return QuranData._(text, norm);
  }

  /// For every surah except 1 and 9, the Tanzil text begins ayah 1 with the
  /// basmala. It is shown as a header (display only; the text is unchanged).
  SurahView view(int s) {
    final ayahs = List<String>.from(_text[s - 1]);
    String? basmala;
    if (s != 1 && s != 9) {
      final w = ayahs[0].split(' ');
      basmala = w.take(4).join(' ');
      ayahs[0] = w.skip(4).join(' ');
    }
    return SurahView(basmala, ayahs);
  }

  String ayah(int s, int a) => view(s).ayahs[a - 1];

  List<SearchHit> search(String query, {int limit = 60}) {
    final q = normalizeArabic(query.trim());
    final hits = <SearchHit>[];
    if (q.length < 2) return hits;
    for (var s = 1; s <= 114 && hits.length < limit; s++) {
      final n = _norm[s - 1];
      for (var a = 0; a < n.length && hits.length < limit; a++) {
        if (n[a].contains(q)) hits.add(SearchHit(s, a + 1, _text[s - 1][a]));
      }
    }
    return hits;
  }
}
