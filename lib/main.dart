import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'app_state.dart';
import 'intro_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Background playback with a media notification (play / pause / next / previous).
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.hmalmulla.quran_app.audio',
    androidNotificationChannelName: 'تلاوة القرآن',
    androidNotificationOngoing: true,
  );
  runApp(const QuranApp());
}

class QuranApp extends StatelessWidget {
  const QuranApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) => MaterialApp(
        title: 'القرآن الكريم',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(false),
        darkTheme: buildTheme(true),
        themeMode: app.dark ? ThemeMode.dark : ThemeMode.light,
        builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
        home: const IntroScreen(),
      ),
    );
  }
}
