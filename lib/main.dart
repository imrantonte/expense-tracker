import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'core/theme_controller.dart';
import 'data/app_state.dart';
import 'screens/splash/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Portrait-only lock.
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Transparent status bar — per-screen brightness set via AnnotatedRegion.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeController()),
        ChangeNotifierProvider(create: (_) => AppState()),
      ],
      child: const WhereDidItGoApp(),
    ),
  );
}

/// Root application widget for "Where Did It Go?".
class WhereDidItGoApp extends StatelessWidget {
  const WhereDidItGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeCtrl = context.watch<ThemeController>();

    return MaterialApp(
      title: 'Where Did It Go?',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeCtrl.themeMode,
      // Flow: SplashScreen → OnboardingScreen → AppShell (home)
      home: const SplashScreen(),
    );
  }
}
