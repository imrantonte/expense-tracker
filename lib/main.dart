import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'core/theme_controller.dart';
import 'data/app_state.dart';
import 'firebase_options.dart';
import 'repositories/budget_repository.dart';
import 'repositories/category_repository.dart';
import 'repositories/notification_repository.dart';
import 'repositories/transaction_repository.dart';
import 'repositories/user_repository.dart';
import 'screens/splash/splash_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final firebaseApp = await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint('[Firebase] Initialized: ${firebaseApp.name}');

  // Enable offline persistence with unlimited cache.
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // Load persisted theme BEFORE runApp so there is never a theme flash.
  final themeController = await ThemeController.load();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    MultiProvider(
      providers: [
        // Provide the pre-loaded ThemeController instance.
        ChangeNotifierProvider<ThemeController>.value(value: themeController),
        ChangeNotifierProvider(create: (_) => AppState()),
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<UserRepository>(create: (_) => UserRepository()),
        Provider<TransactionRepository>(
            create: (_) => TransactionRepository()),
        Provider<BudgetRepository>(create: (_) => BudgetRepository()),
        Provider<NotificationRepository>(
            create: (_) => NotificationRepository()),
        Provider<CategoryRepository>(create: (_) => CategoryRepository()),
      ],
      child: const WhereDidItGoApp(),
    ),
  );
}

class WhereDidItGoApp extends StatelessWidget {
  const WhereDidItGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeCtrl = context.watch<ThemeController>();

    // Keep the status-bar icons in sync with the resolved theme.
    final brightness = themeCtrl.isSystem
        ? WidgetsBinding.instance.platformDispatcher.platformBrightness
        : (themeCtrl.isDark ? Brightness.dark : Brightness.light);
    final isDark = brightness == Brightness.dark;
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
    ));

    return MaterialApp(
      title: 'Where Did It Go?',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeCtrl.themeMode,
      home: const SplashScreen(),
    );
  }
}
