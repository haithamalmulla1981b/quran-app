# نشر تطبيق «القرآن الكريم» على Google Play
# Publishing the Quran app on Google Play

## 1. الملفات / Files
| | |
|---|---|
| Signed bundle | `quran-app-1.0.0-signed.aab` |
| Upload key | `quran-app-upload.jks` + `UPLOAD_KEY_KEEP_SAFE.txt` (keep private, back up) |
| Icon 512×512 | `icon-512.png` |
| Feature graphic | `feature-graphic-1024x500.png` |
| Privacy policy URL | https://github.com/haithamalmulla1981b/quran-app/blob/main/PRIVACY.md |

Package `com.hmalmulla.quran_app` · version 1.0.0 (code 1) · targets Android 16 (API 36).

## 2. Create app
App name **القرآن الكريم** · Default language **Arabic – ar** · App · Free.

## 3. Store listing (Arabic, default)
**اسم التطبيق** (30 max): `القرآن الكريم - تلاوة وقراءة`

**الوصف المختصر** (80 max):
`مصحف بالرسم العثماني وتلاوات بأصوات كبار القرّاء، تعمل دون إنترنت بعد التنزيل`

**الوصف الكامل:**
```
تطبيق «القرآن الكريم» مصحف كامل بالرسم العثماني بتصميم فارسي أنيق بالأزرق اللازوردي والذهبي، مع تلاوات بأصوات كبار القرّاء.

📖 القراءة
• المصحف كاملًا بالرسم العثماني، بنص متصل كالمصحف المطبوع
• علامات نهاية الآيات المزخرفة وعناوين السور بإطار فارسي
• عرض المصحف أو عرض كل آية في بطاقة
• تكبير الخط وتصغيره، والوضع الليلي
• متابعة القراءة من حيث توقفت، وحفظ العلامات

🎧 الاستماع
• تلاوات بأصوات: مشاري العفاسي، محمود خليل الحصري، عبد الباسط عبد الصمد، محمد صديق المنشاوي، عبد الرحمن السديس، ماهر المعيقلي
• تظليل الآية المقروءة ومتابعة التلاوة تلقائيًا
• التشغيل في الخلفية مع إشعار للتحكم (تشغيل، إيقاف، الآية التالية والسابقة)
• تكرار الآية أو السورة للحفظ، والتحكم في سرعة التلاوة
• تُحفظ التلاوة على الجهاز بعد أول استماع، وتعمل بعدها دون إنترنت

🔎 البحث والتاريخ
• البحث في السور والآيات دون الحاجة إلى كتابة التشكيل
• التاريخ الهجري والميلادي مع إمكانية تعديل التاريخ الهجري

🔒 الخصوصية
بلا إعلانات، وبلا تسجيل دخول، ولا يجمع أي بيانات.

النص القرآني: مشروع تنزيل (tanzil.net) — التلاوات: EveryAyah.com
تطوير: هيثم محمد الملا
```

**English listing (add translation → English United States):**
- Title: `Quran Kareem: Read & Listen`
- Short: `Full Uthmani Mushaf with famous reciters, ayah highlighting and offline audio`
- Full: translate the Arabic text above; keep the credits line:
  `Quran text: Tanzil Project (tanzil.net) — Recitations: EveryAyah.com — Developed by H.M.Al-Mulla`

**Graphics:** icon-512.png · feature-graphic-1024x500.png · 2–8 phone screenshots taken on your phone:
intro (logo), home with Hijri date, Mushaf page with an ayah highlighted while playing, surah header,
the playback notification, settings (reciters).

**Category:** Books & Reference · **Tags:** Books, Education · **Contact email:** your developer email.

## 4. App content
| Section | Answer |
|---|---|
| Privacy policy | URL above |
| Ads | No |
| App access | All functionality available without special access |
| Content rating | Category **Reference, News, or Educational** → No to all questions → Everyone / PEGI 3 |
| Target audience | 13 and over (selecting under 13 adds the Families policy requirements) |
| Data safety | **No data collected, no data shared**; data encrypted in transit: Yes |
| **Foreground service permissions** | Select **Media playback**. Description: *"Plays Quran recitation audio when the user leaves the app or locks the screen, with play/pause/next controls in a media notification. Started only when the user presses play."* Video link: record your screen (press play → home button → show the notification and controls), upload to YouTube as **Unlisted**, paste the link |
| Financial features | None |
| Health | None |
| Government / News | No / No |

**Content rights:** the app streams recitations from EveryAyah.com. Play may ask whether you have rights
to third-party content. Check EveryAyah's terms (or ask them) before production, and keep the credit
in the description. The Quran text is from Tanzil (CC BY 3.0, unmodified, credit required: kept in the
store description).

## 5. Release
Internal testing first, then Production → Create release → Play App Signing (Google-generated key) →
upload `quran-app-1.0.0-signed.aab` → release name `1.0.0` → notes:
```
<ar>
الإصدار الأول: المصحف كاملًا بالرسم العثماني، تلاوات بأصوات كبار القرّاء مع تظليل الآيات، التشغيل في الخلفية، العلامات، والتاريخ الهجري.
</ar>
<en-US>
First release: full Uthmani Mushaf, famous reciters with ayah highlighting, background playback, bookmarks and Hijri date.
</en-US>
```
New personal developer accounts (created after Nov 2023) need a closed test with 12 testers for 14 days
before production.

## 6. Updates
Raise `version:` in `pubspec.yaml` (e.g. `1.0.1+2`), push, download `app-release.aab` from the new
GitHub release, then sign with the same key:
`zip -d app-release.aab 'META-INF/*.SF' 'META-INF/*.RSA' 'META-INF/MANIFEST.MF'` and
`jarsigner -keystore quran-app-upload.jks app-release.aab upload`.
