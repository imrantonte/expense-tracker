import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'core/theme_controller.dart';
import 'data/app_state.dart';
import 'firebase_options.dart';
import 'repositories/category_repository.dart';
import 'repositories/transaction_repository.dart';
import 'repositories/user_repository.dart';
import 'screens/splash/splash_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase.
  final firebaseApp = await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // TODO(debug): remove before production.
  // ignore: avoid_print
  debugPrint('[Firebase] Initialized app: ${firebaseApp.name}');

  // Enable Firestore offline persistence (unlimited cache size).
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

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
        // Services — created once, injected wherever needed.
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<UserRepository>(create: (_) => UserRepository()),
        Provider<TransactionRepository>(
            create: (_) => TransactionRepository()),
        Provider<CategoryRepository>(create: (_) => CategoryRepository()),
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
      // Flow: SplashScreen → AuthGate → (AppShell | OnboardingScreen | LoginScreen)
      home: const SplashScreen(),
    );
  }
}
