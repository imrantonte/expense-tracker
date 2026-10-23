import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

// ─────────────────────────────────────────────────────────────────────────────
// ReminderService
// ─────────────────────────────────────────────────────────────────────────────

/// Manages all local push notifications for the app.
///
/// - Initialises [FlutterLocalNotificationsPlugin] once in [init].
/// - [scheduleReminders] cancels existing reminders then schedules the next
///   N occurrences (up to [_lookaheadCount]) skipping quiet-hour windows.
/// - [cancelReminders] removes every pending notification.
/// - [requestPermission] prompts the user on Android 13+ (API 33+).
///
/// All methods are fire-and-forget safe — they never throw externally.
class ReminderService {
  ReminderService._();
  static final ReminderService instance = ReminderService._();

  // ── IDs ──────────────────────────────────────────────────────────────────

  /// Notification channel / notification IDs start here.
  static const int _baseId = 100;

  /// How many upcoming reminders to pre-schedule so they survive process death.
  static const int _lookaheadCount = 8;

  static const String _channelId = 'expense_reminders';
  static const String _channelName = 'Expense Reminders';
  static const String _channelDesc =
      'Nudges you to log what you spent.';

  // ── Plugin ───────────────────────────────────────────────────────────────

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialised = false;

  // ── Public API ────────────────────────────────────────────────────────────

  /// Call once from [main] before [runApp].
  Future<void> init() async {
    if (_initialised) return;

    // Initialise timezone database.
    tz_data.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(initSettings);
    _initialised = true;
    debugPrint('[ReminderService] Initialised.');
  }

  /// Requests the POST_NOTIFICATIONS runtime permission (Android 13+).
  ///
  /// Returns `true` if the permission was granted or is not required.
  Future<bool> requestPermission() async {
    try {
      final impl =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (impl == null) return true; // Not Android
      final granted = await impl.requestNotificationsPermission();
      return granted ?? false;
    } catch (e) {
      debugPrint('[ReminderService] requestPermission error: $e');
      return false;
    }
  }

  /// Returns `true` if the POST_NOTIFICATIONS permission is currently granted.
  Future<bool> hasPermission() async {
    try {
      final impl =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (impl == null) return true;
      final granted = await impl.areNotificationsEnabled();
      return granted ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Cancels all pending reminders then schedules the next [_lookaheadCount]
  /// occurrences of the reminder, honouring quiet hours.
  ///
  /// Parameters:
  /// - [intervalKey]   : '2h' | '3h' | '4h' | '1d'
  /// - [quietFromHour] / [quietFromMin] : start of quiet window (24-h)
  /// - [quietToHour]   / [quietToMin]  : end of quiet window (24-h)
  /// - [startFrom]     : schedule first reminder **at or after** this moment
  ///                     (default = now). Use to postpone after a tx is saved.
  Future<void> scheduleReminders({
    required String intervalKey,
    required int quietFromHour,
    required int quietFromMin,
    required int quietToHour,
    required int quietToMin,
    DateTime? startFrom,
  }) async {
    if (!_initialised) await init();

    await cancelReminders();

    final intervalMinutes = _intervalMinutes(intervalKey);
    final now = startFrom ?? DateTime.now();

    // Build the message body that matches the preview card.
    final intervalLabel = switch (intervalKey) {
      '2h' => 'last 2 hours',
      '3h' => 'last 3 hours',
      '4h' => 'last 4 hours',
      '1d' => 'today',
      _ => 'a while',
    };
    final body =
        'Spent anything in the $intervalLabel? Log it in 10 seconds.';

    var candidate = now.add(Duration(minutes: intervalMinutes));

    for (int i = 0; i < _lookaheadCount; i++) {
      // Skip any time that falls inside the quiet window.
      candidate = _skipQuietHours(
        candidate,
        quietFromHour: quietFromHour,
        quietFromMin: quietFromMin,
        quietToHour: quietToHour,
        quietToMin: quietToMin,
        intervalMinutes: intervalMinutes,
      );

      final tzTime = tz.TZDateTime.from(candidate, tz.local);

      try {
        await _plugin.zonedSchedule(
          _baseId + i,
          'Where Did It Go?',
          body,
          tzTime,
          _buildNotificationDetails(),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: 'reminder',
        );
        debugPrint('[ReminderService] Scheduled #$i at $tzTime');
      } catch (e) {
        debugPrint('[ReminderService] Schedule error: $e');
      }

      candidate = candidate.add(Duration(minutes: intervalMinutes));
    }
  }

  /// Cancels all pending reminder notifications.
  Future<void> cancelReminders() async {
    if (!_initialised) return;
    try {
      for (int i = 0; i < _lookaheadCount; i++) {
        await _plugin.cancel(_baseId + i);
      }
      debugPrint('[ReminderService] All reminders cancelled.');
    } catch (e) {
      debugPrint('[ReminderService] Cancel error: $e');
    }
  }

  // ── Internals ─────────────────────────────────────────────────────────────

  NotificationDetails _buildNotificationDetails() {
    const android = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      // Use the app's launcher icon as the small icon; replace with a
      // monochrome 24dp white-on-transparent icon for production.
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
    );
    return const NotificationDetails(android: android);
  }

  /// Convert an interval key to minutes.
  static int _intervalMinutes(String key) => switch (key) {
        '3h' => 180,
        '4h' => 240,
        '1d' => 1440,
        _ => 120, // default: 2h
      };

  /// Advance [time] forward until it is outside the quiet-hours window.
  ///
  /// Quiet hours are represented as a single window that may span midnight
  /// (e.g. 22:00 → 08:00). When [time] falls inside that window, we jump
  /// directly to the window's end time, then re-apply the interval so the
  /// cadence stays consistent.
  static DateTime _skipQuietHours(
    DateTime time, {
    required int quietFromHour,
    required int quietFromMin,
    required int quietToHour,
    required int quietToMin,
    required int intervalMinutes,
  }) {
    // Quick exit: no quiet hours configured (both times are the same).
    if (quietFromHour == quietToHour && quietFromMin == quietToMin) {
      return time;
    }

    int iterations = 0;
    while (_isInQuietHours(
      time,
      fromHour: quietFromHour,
      fromMin: quietFromMin,
      toHour: quietToHour,
      toMin: quietToMin,
    )) {
      // Jump to the end of the quiet window today (or tomorrow if past midnight).
      final todayEnd = DateTime(
          time.year, time.month, time.day, quietToHour, quietToMin);
      final tomorrowEnd = todayEnd.add(const Duration(days: 1));

      time = time.isBefore(todayEnd) ? todayEnd : tomorrowEnd;

      // Safety valve: should never loop more than twice.
      if (++iterations > 4) break;
    }
    return time;
  }

  /// Returns `true` when [time] falls inside the quiet-hours window.
  static bool _isInQuietHours(
    DateTime time, {
    required int fromHour,
    required int fromMin,
    required int toHour,
    required int toMin,
  }) {
    final timeMinutes = time.hour * 60 + time.minute;
    final fromMinutes = fromHour * 60 + fromMin;
    final toMinutes = toHour * 60 + toMin;

    if (fromMinutes < toMinutes) {
      // Simple window: e.g. 08:00 → 10:00
      return timeMinutes >= fromMinutes && timeMinutes < toMinutes;
    } else {
      // Wraps midnight: e.g. 22:00 → 08:00
      return timeMinutes >= fromMinutes || timeMinutes < toMinutes;
    }
  }
}
