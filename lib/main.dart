import 'package:flutter/material.dart';

import 'app_state.dart';
import 'home_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await app.init();
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
        home: const HomeScreen(),
      ),
    );
  }
}
