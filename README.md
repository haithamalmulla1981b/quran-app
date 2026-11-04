# القرآن الكريم — Quran App (Flutter)

Arabic-only Quran reader with recitation that downloads on demand and is kept for offline listening.

## Features
- Full Quran text (Tanzil, Uthmani script, verbatim), basmala shown as a surah header
- Search by surah name or ayah text (ignores diacritics)
- Recitation per ayah from EveryAyah.com — streamed on first play, saved on the device, then offline
- "Download surah" button for full offline use
- Highlights and follows the ayah being recited
- Repeat ayah / repeat surah, speed 0.75x–1.5x, 6 reciters
- Bookmarks, continue reading, font size, night mode

## Build
Push to `main` on GitHub: the workflow in `.github/workflows/build.yml` builds the APK and
publishes it under **Releases**. Locally: `flutter create --platforms=android .` then
add the INTERNET permission and `android:usesCleartextTraffic="true"` to the manifest
(see the workflow), then `flutter build apk`.

## Credits
- Quran text: Tanzil Project — https://tanzil.net (CC BY 3.0, text must not be changed)
- Recitations: https://everyayah.com

Developed By: H.M.Al-Mulla
