import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Controls the app's [ThemeMode] and persists the choice to
/// [SharedPreferences] so the correct theme is applied before the first frame
/// (no flash of wrong theme).
///
/// Create with [ThemeController.load()] in `main()` before `runApp()`.
class ThemeController extends ChangeNotifier {
  ThemeController._(this._themeMode, this._prefs);

  final SharedPreferences _prefs;
  ThemeMode _themeMode;

  static const _key = 'theme_mode';

  /// Loads the persisted mode from [SharedPreferences].
  ///
  /// Falls back to [ThemeMode.system] if nothing is stored.
  static Future<ThemeController> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    final mode = _fromString(raw) ?? ThemeMode.system;
    return ThemeController._(mode, prefs);
  }

  /// Current theme mode.
  ThemeMode get themeMode => _themeMode;

  bool get isDark => _themeMode == ThemeMode.dark;
  bool get isLight => _themeMode == ThemeMode.light;
  bool get isSystem => _themeMode == ThemeMode.system;

  /// Explicitly set a given [ThemeMode] and persist it.
  Future<void> setMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    await _prefs.setString(_key, _toString(mode));
    notifyListeners();
  }

  /// Toggle between [ThemeMode.light] and [ThemeMode.dark].
  Future<void> toggle() async {
    await setMode(_themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static String _toString(ThemeMode mode) => switch (mode) {
        ThemeMode.dark => 'dark',
        ThemeMode.light => 'light',
        ThemeMode.system => 'system',
      };

  static ThemeMode? _fromString(String? s) => switch (s) {
        'dark' => ThemeMode.dark,
        'light' => ThemeMode.light,
        'system' => ThemeMode.system,
        _ => null,
      };
}
