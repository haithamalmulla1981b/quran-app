import 'package:flutter/material.dart';

import 'app_state.dart';
import 'audio_controller.dart';
import 'quran_data.dart';
import 'theme.dart';

/// Bottom player. In the reader ([surah] set, [full] true) it controls that
/// surah; on the home screen it shows whatever is playing.
class PlayerBar extends StatelessWidget {
  final int? surah;
  final bool full;
  final GlobalKey? playKey, repeatKey; // targets for the first-run guide
  const PlayerBar({super.key, this.surah, this.full = false, this.playKey, this.repeatKey});

  @override
  Widget build(BuildContext context) {
    final audio = app.audio;
    return ListenableBuilder(
      listenable: audio,
      builder: (context, _) {
        if (!full && audio.surah == null) return const SizedBox.shrink();
        final p = paletteOf(context);
        final target = surah ?? audio.surah!;
        final active = audio.surah == target;
        final isPlaying = active && audio.playing;

        String info;
        if (active) {
          info = audio.currentAyah == null
              ? 'سورة ${surahNameAr(target)} · البسملة'
              : 'سورة ${surahNameAr(target)} · آية ${arNum(audio.currentAyah!)}';
        } else {
          info = 'استمع إلى سورة ${surahNameAr(target)}';
        }

        final repeatIcon = audio.repeat == RepeatMode.ayah ? Icons.repeat_one_rounded : Icons.repeat_rounded;
        final repeatLabel = switch (audio.repeat) {
          RepeatMode.off => 'التكرار متوقف',
          RepeatMode.ayah => 'تكرار الآية',
          RepeatMode.surah => 'تكرار السورة',
        };

        return Material(
          color: p.page,
          elevation: 8,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (audio.error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(audio.error!, style: const TextStyle(color: Colors.redAccent, fontSize: 14)),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(info,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: p.ink)),
                            Text(audio.reciter.nameAr,
                                maxLines: 1, style: TextStyle(fontSize: 13, color: p.muted)),
                          ],
                        ),
                      ),
                      if (full) ...[
                        TextButton(
                          onPressed: audio.cycleSpeed,
                          child: Text('${audio.speed}x', style: TextStyle(color: p.accent, fontSize: 14)),
                        ),
                        KeyedSubtree(
                          key: repeatKey,
                          child: IconButton(
                            tooltip: repeatLabel,
                            onPressed: audio.cycleRepeat,
                            icon: Icon(repeatIcon, color: audio.repeat == RepeatMode.off ? p.muted : kGold),
                          ),
                        ),
                      ],
                      IconButton(
                        tooltip: 'الآية السابقة',
                        onPressed: active ? audio.previous : null,
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                      ),
                      SizedBox(
                        key: playKey,
                        width: 52,
                        height: 52,
                        child: audio.loading && audio.loadingSurah == target
                            ? Padding(
                                padding: const EdgeInsets.all(12),
                                child: CircularProgressIndicator(strokeWidth: 3, color: p.accent),
                              )
                            : IconButton.filled(
                                style: IconButton.styleFrom(backgroundColor: kPrimary, foregroundColor: kCreamGold),
                                tooltip: isPlaying ? 'إيقاف مؤقت' : 'تشغيل',
                                onPressed: () => audio.togglePlay(target),
                                icon: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 30),
                              ),
                      ),
                      IconButton(
                        tooltip: 'الآية التالية',
                        onPressed: active ? audio.next : null,
                        icon: const Icon(Icons.arrow_forward_ios_rounded, size: 20),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
