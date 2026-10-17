import 'package:flutter/material.dart';

/// Controls the app's [ThemeMode] and exposes it to the widget tree via
/// [ChangeNotifier].
///
/// Provide this at the root with `ChangeNotifierProvider(create: (_) => ThemeController())`.
/// Consume with `context.watch<ThemeController>().themeMode`.
class ThemeController extends ChangeNotifier {
  ThemeController() : _themeMode = ThemeMode.light;

  ThemeMode _themeMode;

  /// Current theme mode.
  ThemeMode get themeMode => _themeMode;

  bool get isDark => _themeMode == ThemeMode.dark;

  /// Toggle between [ThemeMode.light] and [ThemeMode.dark].
  void toggle() {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  /// Explicitly set to a given [ThemeMode].
  void setMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
  }
}
