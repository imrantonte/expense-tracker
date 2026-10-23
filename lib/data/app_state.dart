import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' hide Category;

import '../models/managed_category.dart';
import '../models/models.dart';
import '../repositories/budget_repository.dart';
import '../repositories/category_repository.dart';
import '../repositories/notification_repository.dart';
import '../repositories/transaction_repository.dart';
import '../repositories/user_repository.dart';
import '../services/reminder_service.dart';
import 'mock_data.dart' as mock;

// ─────────────────────────────────────────────────────────────────────────────
// Currency symbol table
// ─────────────────────────────────────────────────────────────────────────────

const Map<String, String> _kCurrencySymbols = {
  'BDT': '৳',
  'USD': '\$',
  'EUR': '€',
  'GBP': '£',
  'INR': '₹',
  'JPY': '¥',
};

// ─────────────────────────────────────────────────────────────────────────────
// TransactionFilter
// ─────────────────────────────────────────────────────────────────────────────

@immutable
class TransactionFilter {
  const TransactionFilter({
    this.categoryId,
    this.isIncome,
    this.searchQuery = '',
  });

  final String? categoryId;
  final bool? isIncome;
  final String searchQuery;

  bool get isActive =>
      categoryId != null || isIncome != null || searchQuery.isNotEmpty;

  TransactionFilter copyWith({
    Object? categoryId = _s,
    Object? isIncome = _s,
    String? searchQuery,
  }) =>
      TransactionFilter(
        categoryId:
            categoryId == _s ? this.categoryId : categoryId as String?,
        isIncome: isIncome == _s ? this.isIncome : isIncome as bool?,
        searchQuery: searchQuery ?? this.searchQuery,
      );

  static const Object _s = Object();
}

// ─────────────────────────────────────────────────────────────────────────────
// AppState
// ─────────────────────────────────────────────────────────────────────────────

class AppState extends ChangeNotifier {
  AppState()
      : _profile = mock.mockUser,
        _transactions = [],
        _notifications = [],
        _budget = null, // null = no budget set yet
        _managedCategories = [],
        _selectedMonth = DateTime.now().month,
        _selectedYear = DateTime.now().year,
        _selectedDay = DateTime.now(),
        _filter = const TransactionFilter();

  // ── Core data ──────────────────────────────────────────────────────────────

  UserProfile _profile;
  List<TransactionItem> _transactions;
  List<AppNotification> _notifications;
  Budget? _budget; // null means no budget configured this month
  List<ManagedCategory> _managedCategories;

  // ── Stream subscriptions ───────────────────────────────────────────────────

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _txSub;
  StreamSubscription<Budget?>? _budgetSub;
  StreamSubscription<List<AppNotification>>? _notifSub;
  StreamSubscription<List<ManagedCategory>>? _catSub;

  bool _hasPendingWrites = false;
  bool _txFirstLoadFailed = false;

  bool get hasPendingWrites => _hasPendingWrites;
  bool get txFirstLoadFailed => _txFirstLoadFailed;

  // ── View state ─────────────────────────────────────────────────────────────

  int _selectedMonth;
  int _selectedYear;
  /// Selected day for the Daily tab (defaults to today, reset when month changes).
  DateTime _selectedDay;
  TransactionFilter _filter;

  // ── Notification settings ──────────────────────────────────────────────────

  bool _expenseReminders = true;
  String _remindEvery = '2h';
  int _quietFromHour = 22;
  int _quietFromMin = 0;
  int _quietToHour = 8;
  int _quietToMin = 0;
  bool _skipIfLogged = true;
  bool _budgetAlerts = true;

  // ── Firestore save reference ───────────────────────────────────────────────
  UserRepository? _userRepo;
  String? _uid;

  // ═══════════════════════════════════════════════════════════════════════════
  // STREAM MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════════

  /// Starts all Firestore streams for [uid].  Called after sign-in.
  void subscribeAll({
    required TransactionRepository txRepo,
    required BudgetRepository budgetRepo,
    required NotificationRepository notifRepo,
    required CategoryRepository catRepo,
    required UserRepository userRepo,
    required String uid,
  }) {
    _userRepo = userRepo;
    _uid = uid;
    _subscribeToTransactions(txRepo, uid);
    subscribeToBudget(budgetRepo, uid);
    _subscribeToNotifications(notifRepo, uid);
    _subscribeToCategories(catRepo, uid);
    // Load persisted notification settings from Firestore (fire-and-forget).
    _loadNotificationSettingsFromFirestore(userRepo, uid);
  }

  /// Cancels all streams and resets transient state.  Called on sign-out.
  void cancelAll() {
    _txSub?.cancel();
    _budgetSub?.cancel();
    _notifSub?.cancel();
    _catSub?.cancel();
    _txSub = _budgetSub = _notifSub = _catSub = null;
    _userRepo = null;
    _uid = null;
    _transactions = [];
    _notifications = [];
    _budget = null;
    _managedCategories = [];
    _hasPendingWrites = false;
    _txFirstLoadFailed = false;
    // Cancel any pending reminders on sign-out.
    ReminderService.instance.cancelReminders().ignore();
    notifyListeners();
  }

  // ── Transactions stream ────────────────────────────────────────────────────

  void _subscribeToTransactions(TransactionRepository repo, String uid) {
    _txSub?.cancel();
    _txFirstLoadFailed = false;
    _txSub = repo.watchRaw(uid).listen(
      (snap) {
        _hasPendingWrites = snap.metadata.hasPendingWrites;
        _transactions = snap.docs
            .map((doc) {
              try {
                final d = doc.data();
                return TransactionItem(
                  id: doc.id,
                  title: (d['title'] as String?) ?? '',
                  note: d['note'] as String?,
                  categoryId: (d['categoryId'] as String?) ?? '',
                  amount: ((d['amount'] as num?) ?? 0).toDouble(),
                  isIncome: (d['isIncome'] as bool?) ?? false,
                  date: d['date'] is Timestamp
                      ? (d['date'] as Timestamp).toDate()
                      : DateTime.now(),
                );
              } catch (_) {
                return null;
              }
            })
            .whereType<TransactionItem>()
            .toList();
        notifyListeners();
      },
      onError: (_) {
        if (_transactions.isEmpty) {
          _txFirstLoadFailed = true;
          notifyListeners();
        }
      },
    );
  }

  // ── Budget stream ──────────────────────────────────────────────────────────

  BudgetRepository? _budgetRepo;
  String? _budgetUid;

  void subscribeToBudget(BudgetRepository repo, String uid) {
    _budgetSub?.cancel();
    _budgetRepo = repo;
    _budgetUid = uid;
    final now = DateTime.now();
    _budgetSub = repo.watchBudget(uid, now.year, now.month).listen(
      (b) {
        _budget = b;
        notifyListeners();
      },
      onError: (_) {},
    );
  }

  /// Re-subscribe to the budget for the current selected month (called when
  /// the user changes the month picker so the budget card stays in sync).
  void resubscribeBudgetForMonth(int year, int month) {
    if (_budgetRepo == null || _budgetUid == null) return;
    _budgetSub?.cancel();
    _budgetSub = _budgetRepo!.watchBudget(_budgetUid!, year, month).listen(
      (b) {
        _budget = b;
        notifyListeners();
      },
      onError: (_) {},
    );
  }

  // ── Notifications stream ───────────────────────────────────────────────────

  void _subscribeToNotifications(NotificationRepository repo, String uid) {
    _notifSub?.cancel();
    _notifSub = repo.watchNotifications(uid).listen(
      (list) {
        _notifications = list;
        notifyListeners();
      },
      onError: (_) {},
    );
  }

  // ── Managed categories stream ──────────────────────────────────────────────

  void _subscribeToCategories(CategoryRepository repo, String uid) {
    _catSub?.cancel();
    _catSub = repo.watchCategories(uid).listen(
      (list) {
        _managedCategories = list;
        notifyListeners();
      },
      onError: (_) {},
    );
  }

  // Also expose subscribe/cancel individually for AuthGate flexibility:
  void subscribeToTransactions(TransactionRepository repo, String uid) =>
      _subscribeToTransactions(repo, uid);
  void cancelTransactionStream() {
    _txSub?.cancel();
    _txSub = null;
    _transactions = [];
    _hasPendingWrites = false;
    _txFirstLoadFailed = false;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // READ-ONLY ACCESSORS
  // ═══════════════════════════════════════════════════════════════════════════

  // ── Categories (static defaults — still used for transaction category lookup)

  List<Category> get expenseCategories => mock.expenseCategories;
  List<Category> get incomeCategories => mock.incomeCategories;
  List<Category> get allCategories =>
      [...mock.expenseCategories, ...mock.incomeCategories];
  Category? findCategory(String id) => mock.categoryById[id];

  // ── Profile ────────────────────────────────────────────────────────────────

  UserProfile get profile => _profile;
  String get currencySymbol =>
      _kCurrencySymbols[_profile.currencyCode] ?? _profile.currencyCode;
  int get totalTransactionCount => _transactions.length;
  int get usedCategoryCount =>
      _transactions.map((t) => t.categoryId).toSet().length;
  int get daysSinceJoining =>
      DateTime.now().difference(_profile.joinedDate).inDays.clamp(0, 99999);

  // ── Budget ─────────────────────────────────────────────────────────────────

  /// `null` when no budget has been set for the selected month.
  Budget? get budget => _budget;

  /// `true` when a budget exists for the selected month.
  bool get hasBudget => _budget != null && _budget!.limit > 0;

  double get budgetSpent => monthSpent;
  double get budgetRemaining =>
      hasBudget ? (_budget!.limit - budgetSpent).clamp(0, double.infinity) : 0;
  double get budgetUsage =>
      hasBudget && _budget!.limit > 0 ? budgetSpent / _budget!.limit : 0;

  // ── Month selection ────────────────────────────────────────────────────────

  int get selectedMonth => _selectedMonth;
  int get selectedYear => _selectedYear;
  DateTime get selectedDay => _selectedDay;

  // ── Transactions ───────────────────────────────────────────────────────────

  List<TransactionItem> get transactions {
    return _transactions
        .where((t) =>
            t.date.month == _selectedMonth && t.date.year == _selectedYear)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  List<TransactionItem> get filteredTransactions {
    var list = transactions;
    if (_filter.isIncome != null) {
      list = list.where((t) => t.isIncome == _filter.isIncome).toList();
    }
    if (_filter.categoryId != null) {
      list = list.where((t) => t.categoryId == _filter.categoryId).toList();
    }
    if (_filter.searchQuery.isNotEmpty) {
      final q = _filter.searchQuery.toLowerCase();
      list = list
          .where((t) =>
              t.title.toLowerCase().contains(q) ||
              (t.note?.toLowerCase().contains(q) ?? false))
          .toList();
    }
    return list;
  }

  TransactionFilter get filter => _filter;

  // ── Month summary ──────────────────────────────────────────────────────────

  double get monthEarned =>
      transactions.where((t) => t.isIncome).fold(0.0, (s, t) => s + t.amount);

  double get monthSpent => transactions
      .where((t) => !t.isIncome)
      .fold(0.0, (s, t) => s + t.amount);

  double get monthLeft => monthEarned - monthSpent;

  Map<String, double> get categoryBreakdown {
    final map = <String, double>{};
    for (final t in transactions.where((t) => !t.isIncome)) {
      map[t.categoryId] = (map[t.categoryId] ?? 0) + t.amount;
    }
    return map;
  }

  Map<String, double> get categoryPercent {
    final breakdown = categoryBreakdown;
    final total = breakdown.values.fold(0.0, (s, v) => s + v);
    if (total == 0) return {};
    return breakdown
        .map((k, v) => MapEntry(k, (v / total * 100).roundToDouble()));
  }

  List<double> get weeklyIncome => _weeklyTotals(isIncome: true);
  List<double> get weeklyExpenses => _weeklyTotals(isIncome: false);

  List<double> _weeklyTotals({required bool isIncome}) {
    final result = [0.0, 0.0, 0.0, 0.0];
    for (final t in transactions.where((t) => t.isIncome == isIncome)) {
      final weekIdx = ((t.date.day - 1) ~/ 7).clamp(0, 3);
      result[weekIdx] += t.amount;
    }
    return result;
  }

  // ── Daily-tab helpers ──────────────────────────────────────────────────────

  /// Transactions that fall on [selectedDay].
  List<TransactionItem> get dailyTransactions => _transactions
      .where((t) =>
          t.date.year == _selectedDay.year &&
          t.date.month == _selectedDay.month &&
          t.date.day == _selectedDay.day)
      .toList();

  double get dailyEarned =>
      dailyTransactions.where((t) => t.isIncome).fold(0.0, (s, t) => s + t.amount);
  double get dailySpent =>
      dailyTransactions.where((t) => !t.isIncome).fold(0.0, (s, t) => s + t.amount);

  /// Per-block (6-hour) totals for the selected day.
  /// Blocks: 0 = midnight–5:59, 1 = 6am–11:59, 2 = noon–17:59, 3 = 6pm–23:59
  List<double> dailyBlockTotals({required bool isIncome}) {
    final result = [0.0, 0.0, 0.0, 0.0];
    for (final t in dailyTransactions.where((t) => t.isIncome == isIncome)) {
      final block = (t.date.hour ~/ 6).clamp(0, 3);
      result[block] += t.amount;
    }
    return result;
  }

  Map<String, double> get dailyCategoryBreakdown {
    final map = <String, double>{};
    for (final t in dailyTransactions.where((t) => !t.isIncome)) {
      map[t.categoryId] = (map[t.categoryId] ?? 0) + t.amount;
    }
    return map;
  }

  // ── Weekly-tab helpers ─────────────────────────────────────────────────────

  /// Monday of the ISO week containing [_selectedDay].
  DateTime get _weekMonday {
    final d = _selectedDay;
    return d.subtract(Duration(days: d.weekday - 1));
  }

  /// Transactions in the ISO week containing [_selectedDay].
  List<TransactionItem> get weeklyTransactions {
    final monday = _weekMonday;
    final sunday = monday.add(const Duration(days: 6));
    return _transactions.where((t) {
      final d = t.date;
      final day = DateTime(d.year, d.month, d.day);
      return !day.isBefore(monday) && !day.isAfter(sunday);
    }).toList();
  }

  double get weeklyEarned =>
      weeklyTransactions.where((t) => t.isIncome).fold(0.0, (s, t) => s + t.amount);
  double get weeklySpent =>
      weeklyTransactions.where((t) => !t.isIncome).fold(0.0, (s, t) => s + t.amount);

  /// Per-day-of-week totals (Mon=0 … Sun=6).
  List<double> weekDayTotals({required bool isIncome}) {
    final result = List<double>.filled(7, 0.0);
    for (final t in weeklyTransactions.where((t) => t.isIncome == isIncome)) {
      result[t.date.weekday - 1] += t.amount;
    }
    return result;
  }

  Map<String, double> get weeklyCategoryBreakdown {
    final map = <String, double>{};
    for (final t in weeklyTransactions.where((t) => !t.isIncome)) {
      map[t.categoryId] = (map[t.categoryId] ?? 0) + t.amount;
    }
    return map;
  }

  // ── Notifications ──────────────────────────────────────────────────────────

  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((n) => n.unread).length;

  // ── Notification settings ──────────────────────────────────────────────────

  bool get expenseReminders => _expenseReminders;
  String get remindEvery => _remindEvery;
  int get quietFromHour => _quietFromHour;
  int get quietFromMin => _quietFromMin;
  int get quietToHour => _quietToHour;
  int get quietToMin => _quietToMin;
  bool get skipIfLogged => _skipIfLogged;
  bool get budgetAlerts => _budgetAlerts;

  // ── Managed categories ─────────────────────────────────────────────────────

  List<ManagedCategory> get managedCategories =>
      List.unmodifiable(_managedCategories);

  // ═══════════════════════════════════════════════════════════════════════════
  // MUTATION METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  // ── Budget ─────────────────────────────────────────────────────────────────

  /// Immediately replaces the in-memory budget (Firestore write is done in the
  /// repository — the stream will confirm shortly after).
  void setBudget(Budget newBudget) {
    _budget = newBudget;
    notifyListeners();
  }

  // ── Currency / Profile ─────────────────────────────────────────────────────

  void setCurrency(String currencyCode) {
    if (_profile.currencyCode == currencyCode) return;
    _profile = _profile.copyWith(currencyCode: currencyCode);
    notifyListeners();
  }

  void updateProfile(UserProfile updated) {
    _profile = updated;
    notifyListeners();
  }

  void applyProfileSnapshot(UserProfile updated) {
    _profile = updated;
    notifyListeners();
  }

  // ── Notifications (local mirrors of Firestore) ─────────────────────────────

  void markNotificationRead(String id) {
    final i = _notifications.indexWhere((n) => n.id == id);
    if (i != -1 && _notifications[i].unread) {
      _notifications = List.from(_notifications);
      _notifications[i] = _notifications[i].copyWith(unread: false);
      notifyListeners();
    }
  }

  void markAllNotificationsRead() {
    final updated = _notifications.map((n) => n.copyWith(unread: false)).toList();
    if (updated.any((n) => n.unread == false) != _notifications.any((n) => n.unread)) {
      _notifications = updated;
      notifyListeners();
    }
  }

  // ── Month selection ────────────────────────────────────────────────────────

  void setSelectedMonth(int month, int year) {
    assert(month >= 1 && month <= 12);
    if (_selectedMonth == month && _selectedYear == year) return;
    _selectedMonth = month;
    _selectedYear = year;
    // Reset selected day to the 1st of the new month (or today if same month).
    final now = DateTime.now();
    _selectedDay = (month == now.month && year == now.year)
        ? now
        : DateTime(year, month, 1);
    resubscribeBudgetForMonth(year, month);
    notifyListeners();
  }

  void setSelectedDay(DateTime day) {
    if (_selectedDay.year == day.year &&
        _selectedDay.month == day.month &&
        _selectedDay.day == day.day) {
      return;
    }
    _selectedDay = day;
    notifyListeners();
  }

  // ── Filter ─────────────────────────────────────────────────────────────────

  void setFilterCategory(String? categoryId) {
    _filter = _filter.copyWith(categoryId: categoryId);
    notifyListeners();
  }

  void setFilterType(bool? isIncome) {
    _filter = _filter.copyWith(isIncome: isIncome);
    notifyListeners();
  }

  void setSearchQuery(String query) {
    if (_filter.searchQuery == query) return;
    _filter = _filter.copyWith(searchQuery: query);
    notifyListeners();
  }

  void clearFilters() {
    if (!_filter.isActive) return;
    _filter = const TransactionFilter();
    notifyListeners();
  }

  // ── Notification settings ──────────────────────────────────────────────────

  /// Hydrate notification settings from a Firestore settings map.
  ///
  /// Keys: expenseReminders, remindEvery, quietFromHour, quietFromMin,
  ///       quietToHour, quietToMin, skipIfLogged, budgetAlerts.
  void loadNotificationSettings(Map<String, dynamic> s) {
    _expenseReminders = (s['expenseReminders'] as bool?) ?? _expenseReminders;
    _remindEvery = (s['remindEvery'] as String?) ?? _remindEvery;
    _quietFromHour = (s['quietFromHour'] as int?) ?? _quietFromHour;
    _quietFromMin = (s['quietFromMin'] as int?) ?? _quietFromMin;
    _quietToHour = (s['quietToHour'] as int?) ?? _quietToHour;
    _quietToMin = (s['quietToMin'] as int?) ?? _quietToMin;
    _skipIfLogged = (s['skipIfLogged'] as bool?) ?? _skipIfLogged;
    _budgetAlerts = (s['budgetAlerts'] as bool?) ?? _budgetAlerts;
    notifyListeners();
    // Restore reminder schedule on login / new device.
    if (_expenseReminders) {
      _scheduleReminders();
    } else {
      ReminderService.instance.cancelReminders().ignore();
    }
  }

  /// Load notification settings from Firestore on login.
  Future<void> _loadNotificationSettingsFromFirestore(
      UserRepository repo, String uid) async {
    try {
      final doc = await repo.fetchRawSettings(uid);
      if (doc != null) loadNotificationSettings(doc);
    } catch (_) {
      // Non-fatal: keep defaults.
    }
  }

  /// Persist current notification settings to Firestore.
  void _saveNotificationSettings() {
    if (_userRepo == null || _uid == null) return;
    _userRepo!.updateSettings(_uid!, {
      'settings': {
        'expenseReminders': _expenseReminders,
        'remindEvery': _remindEvery,
        'quietFromHour': _quietFromHour,
        'quietFromMin': _quietFromMin,
        'quietToHour': _quietToHour,
        'quietToMin': _quietToMin,
        'skipIfLogged': _skipIfLogged,
        'budgetAlerts': _budgetAlerts,
      },
    }).catchError((_) {}); // fire-and-forget
  }

  void setExpenseReminders(bool v) {
    _expenseReminders = v;
    notifyListeners();
    _saveNotificationSettings();
    if (v) {
      _scheduleReminders();
    } else {
      ReminderService.instance.cancelReminders().ignore();
    }
  }

  void setRemindEvery(String v) {
    _remindEvery = v;
    notifyListeners();
    _saveNotificationSettings();
    if (_expenseReminders) _scheduleReminders();
  }

  void setQuietFrom(int hour, int min) {
    _quietFromHour = hour;
    _quietFromMin = min;
    notifyListeners();
    _saveNotificationSettings();
    if (_expenseReminders) _scheduleReminders();
  }

  void setQuietTo(int hour, int min) {
    _quietToHour = hour;
    _quietToMin = min;
    notifyListeners();
    _saveNotificationSettings();
    if (_expenseReminders) _scheduleReminders();
  }

  void setSkipIfLogged(bool v) {
    _skipIfLogged = v;
    notifyListeners();
    _saveNotificationSettings();
    // If skip-if-logged is now ON, the reminder will be deferred next time
    // a transaction is saved (handled in rescheduleAfterTransaction).
  }

  void setBudgetAlerts(bool v) {
    _budgetAlerts = v;
    notifyListeners();
    _saveNotificationSettings();
  }

  // ── Reminder scheduling helpers ───────────────────────────────────────────

  /// Schedules the next batch of reminders using current settings.
  void _scheduleReminders({DateTime? startFrom}) {
    ReminderService.instance.scheduleReminders(
      intervalKey: _remindEvery,
      quietFromHour: _quietFromHour,
      quietFromMin: _quietFromMin,
      quietToHour: _quietToHour,
      quietToMin: _quietToMin,
      startFrom: startFrom,
    ).ignore();
  }

  /// Call this after successfully saving a transaction.
  ///
  /// If [skipIfLogged] is enabled, the next reminder is pushed out by the
  /// full interval from *now*; otherwise the existing schedule is kept.
  void rescheduleAfterTransaction() {
    if (!_expenseReminders) return;
    if (_skipIfLogged) {
      _scheduleReminders(); // restarts the countdown from now
    }
    // If skip-if-logged is OFF, do nothing — the existing queued
    // notifications continue on their original schedule.
  }

  // ── Managed categories (local-only helpers — actual writes go via repo) ────

  void addManagedCategory(ManagedCategory cat) {
    _managedCategories = [..._managedCategories, cat];
    notifyListeners();
  }

  void updateManagedCategory(ManagedCategory cat) {
    _managedCategories = [
      for (final c in _managedCategories) c.id == cat.id ? cat : c,
    ];
    notifyListeners();
  }

  void removeManagedCategory(String id) {
    _managedCategories =
        _managedCategories.where((c) => c.id != id).toList();
    notifyListeners();
  }

  @override
  void dispose() {
    _txSub?.cancel();
    _budgetSub?.cancel();
    _notifSub?.cancel();
    _catSub?.cancel();
    super.dispose();
  }
}
