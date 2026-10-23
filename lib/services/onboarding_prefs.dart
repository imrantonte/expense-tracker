import 'package:shared_preferences/shared_preferences.dart';

/// Persists the "onboarding seen" flag using [SharedPreferences].
///
/// Keeps all prefs keys in one place so they stay consistent app-wide.
class OnboardingPrefs {
  static const _kSeen = 'onboarding_seen';

  /// Returns `true` when the user has already completed onboarding.
  static Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kSeen) ?? false;
  }

  /// Marks onboarding as completed. Call once after the user taps
  /// "Get Started" or "Skip" on the onboarding flow.
  static Future<void> markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSeen, true);
  }
}
