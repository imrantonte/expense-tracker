import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' hide Category;

import '../models/managed_category.dart';
import '../models/models.dart';
import '../repositories/transaction_repository.dart';
import 'mock_data.dart' as mock;

// ─────────────────────────────────────────────────────────────────────────────
// Currency symbol table
// ─────────────────────────────────────────────────────────────────────────────

/// Supported currency codes → display symbols.
/// Changing the active currency only swaps the symbol — no conversion occurs.
const Map<String, String> _kCurrencySymbols = {
  'BDT': '৳',
  'USD': '\$',
  'EUR': '€',
  'GBP': '£',
  'INR': '₹',
  'JPY': '¥',
};

// ─────────────────────────────────────────────────────────────────────────────
// Transaction filter state
// ─────────────────────────────────────────────────────────────────────────────

/// Holds the current filter configuration for the Transactions screen.
@immutable
class TransactionFilter {
  const TransactionFilter({
    this.categoryId,
    this.isIncome,
    this.searchQuery = '',
  });

  /// `null` → show all categories.
  final String? categoryId;

  /// `null` → show income + expenses; `true` → income only; `false` → expenses only.
  final bool? isIncome;

  /// Case-insensitive title/note search. Empty string → no filter.
  final String searchQuery;

  bool get isActive =>
      categoryId != null || isIncome != null || searchQuery.isNotEmpty;

  TransactionFilter copyWith({
    Object? categoryId = _s,
    Object? isIncome = _s,
    String? searchQuery,
  }) {
    return TransactionFilter(
      categoryId: categoryId == _s ? this.categoryId : categoryId as String?,
      isIncome: isIncome == _s ? this.isIncome : isIncome as bool?,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  // Sentinel object used to distinguish "not provided" from explicit null.
  static const Object _s = Object();
}

// ─────────────────────────────────────────────────────────────────────────────
// AppState
// ─────────────────────────────────────────────────────────────────────────────

/// Central application state, provided at the widget-tree root via Provider.
///
/// Profile data is synced from Firestore via [UserRepository.profileStream].
/// Transaction data is synced from Firestore via [TransactionRepository.watchTransactions].
/// Totals and breakdowns are computed live from real data.
///
/// ```dart
/// // Subscribe to rebuilds:
/// final state = context.watch<AppState>();
///
/// // Read without rebuilding:
/// final state = context.read<AppState>();
/// ```
class AppState extends ChangeNotifier {
  AppState()
      : _profile = mock.mockUser,
        _transactions = [],
        _notifications = List.from(mock.mockNotifications),
        _budget = mock.mockBudget,
        _managedCategories = List.from(mock.mockManagedCategories),
        _selectedMonth = DateTime.now().month,
        _selectedYear = DateTime.now().year,
        _filter = const TransactionFilter();

  // ── Core data ──────────────────────────────────────────────────────────────

  UserProfile _profile;
  List<TransactionItem> _transactions; // live from Firestore
  final List<AppNotification> _notifications;
  Budget _budget;
  // ignore: prefer_final_fields — mutated by index in updateManagedCategory
  List<ManagedCategory> _managedCategories;

  // ── Firestore stream subscription ──────────────────────────────────────────

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _txSub;
  bool _hasPendingWrites = false;
  bool _txFirstLoadFailed = false;

  /// `true` when Firestore has local writes that haven't synced to the server.
  bool get hasPendingWrites => _hasPendingWrites;

  /// `true` when the initial transaction fetch failed (no cache + no network).
  bool get txFirstLoadFailed => _txFirstLoadFailed;

  // ── View state ─────────────────────────────────────────────────────────────

  int _selectedMonth; // 1–12
  int _selectedYear;
  TransactionFilter _filter;

  // ── Notification settings (auto-saved, no backend) ─────────────────────────

  bool _expenseReminders = true;
  String _remindEvery = '2h'; // '2h' | '3h' | '4h' | '1d' | 'custom'
  int _quietFromHour = 22; // 10 PM
  int _quietFromMin = 0;
  int _quietToHour = 8; // 8 AM
  int _quietToMin = 0;
  bool _skipIfLogged = true;
  bool _budgetAlerts = true;

  // ═══════════════════════════════════════════════════════════════════════════
  // STREAM MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════════

  /// Call this after sign-in to start receiving live Firestore transactions.
  void subscribeToTransactions(TransactionRepository repo, String uid) {
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
        // If first load already received data, keep what we have.
        // If never received data, mark as failed for the UI.
        if (_transactions.isEmpty) {
          _txFirstLoadFailed = true;
          notifyListeners();
        }
      },
    );
  }

  /// Call this on sign-out to stop receiving updates and clear all data.
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

  // ── Categories (static — never changes at runtime) ─────────────────────────

  List<Category> get expenseCategories => mock.expenseCategories;
  List<Category> get incomeCategories => mock.incomeCategories;
  List<Category> get allCategories =>
      [...mock.expenseCategories, ...mock.incomeCategories];

  /// Looks up a [Category] by [id]. Returns `null` if not found.
  Category? findCategory(String id) => mock.categoryById[id];

  // ── User profile ───────────────────────────────────────────────────────────

  UserProfile get profile => _profile;

  /// Currency symbol derived from [profile.currencyCode].
  String get currencySymbol =>
      _kCurrencySymbols[_profile.currencyCode] ?? _profile.currencyCode;

  /// Total number of transactions across all months (for "Your journey" stats).
  int get totalTransactionCount => _transactions.length;

  /// Number of unique categories used across all transactions.
  int get usedCategoryCount =>
      _transactions.map((t) => t.categoryId).toSet().length;

  /// Days since the user joined, based on the Firestore joinedAt date.
  int get daysSinceJoining {
    final joined = _profile.joinedDate;
    return DateTime.now().difference(joined).inDays.clamp(0, 99999);
  }

  // ── Budget ─────────────────────────────────────────────────────────────────

  Budget get budget => _budget;

  /// Amount spent against the budget this month — computed from real data.
  double get budgetSpent => monthSpent;

  /// Remaining budget, clamped to 0 if over-budget.
  double get budgetRemaining =>
      (_budget.limit - budgetSpent).clamp(0, double.infinity);

  /// Usage fraction 0–1 (may exceed 1 if over budget).
  double get budgetUsage =>
      _budget.limit > 0 ? budgetSpent / _budget.limit : 0;

  // ── Month selection ────────────────────────────────────────────────────────

  int get selectedMonth => _selectedMonth;
  int get selectedYear => _selectedYear;

  // ── Transactions ───────────────────────────────────────────────────────────

  /// All transactions for the selected month/year, newest first.
  List<TransactionItem> get transactions {
    return _transactions
        .where((t) =>
            t.date.month == _selectedMonth && t.date.year == _selectedYear)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Transactions after applying the active [filter], newest first.
  List<TransactionItem> get filteredTransactions {
    var list = transactions;

    if (_filter.isIncome != null) {
      list = list.where((t) => t.isIncome == _filter.isIncome).toList();
    }
    if (_filter.categoryId != null) {
      list =
          list.where((t) => t.categoryId == _filter.categoryId).toList();
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

  // ── Month summary — computed from real data ────────────────────────────────

  /// Total income for the selected month.
  double get monthEarned {
    return transactions
        .where((t) => t.isIncome)
        .fold(0.0, (s, t) => s + t.amount);
  }

  /// Total expenses for the selected month.
  double get monthSpent {
    return transactions
        .where((t) => !t.isIncome)
        .fold(0.0, (s, t) => s + t.amount);
  }

  /// Income minus expenses for the selected month.
  double get monthLeft => monthEarned - monthSpent;

  /// Category spending breakdown — categoryId → amount (expenses only).
  Map<String, double> get categoryBreakdown {
    final map = <String, double>{};
    for (final t in transactions.where((t) => !t.isIncome)) {
      map[t.categoryId] = (map[t.categoryId] ?? 0) + t.amount;
    }
    return map;
  }

  /// Category breakdown as percentages (0–100).
  Map<String, double> get categoryPercent {
    final breakdown = categoryBreakdown;
    final total = breakdown.values.fold(0.0, (s, v) => s + v);
    if (total == 0) return {};
    return breakdown
        .map((k, v) => MapEntry(k, (v / total * 100).roundToDouble()));
  }

  /// Weekly income figures — 4 data points (weeks 1–4 of selected month).
  List<double> get weeklyIncome => _weeklyTotals(isIncome: true);

  /// Weekly expense figures — 4 data points (weeks 1–4 of selected month).
  List<double> get weeklyExpenses => _weeklyTotals(isIncome: false);

  List<double> _weeklyTotals({required bool isIncome}) {
    final result = [0.0, 0.0, 0.0, 0.0];
    for (final t in transactions.where((t) => t.isIncome == isIncome)) {
      // Week index: days 1–7 → 0, 8–14 → 1, 15–21 → 2, 22+ → 3
      final weekIdx = ((t.date.day - 1) ~/ 7).clamp(0, 3);
      result[weekIdx] += t.amount;
    }
    return result;
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

  // ── Transactions ───────────────────────────────────────────────────────────
  // These in-memory methods are kept for callers that need an immediate local
  // echo before the Firestore stream confirms. They are NOT called for
  // Firestore writes—use TransactionRepository directly from the screen.

  /// Inserts [item] at the front of the in-memory transaction list.
  void addTransactionLocal(TransactionItem item) {
    _transactions.insert(0, item);
    notifyListeners();
  }

  /// Replaces the transaction with the same [TransactionItem.id] in memory.
  void updateTransactionLocal(TransactionItem item) {
    final i = _transactions.indexWhere((t) => t.id == item.id);
    if (i != -1) {
      _transactions[i] = item;
      notifyListeners();
    }
  }

  /// Removes the transaction with [id] from memory.
  void deleteTransactionLocal(String id) {
    _transactions.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  // ── Budget ─────────────────────────────────────────────────────────────────

  /// Replaces the active [Budget].
  void setBudget(Budget newBudget) {
    _budget = newBudget;
    notifyListeners();
  }

  // ── Currency ───────────────────────────────────────────────────────────────

  /// Switches the displayed currency symbol.
  ///
  /// No amount conversion is applied — only the symbol changes.
  /// [currencyCode] should be one of: BDT, USD, EUR, GBP, INR, JPY.
  void setCurrency(String currencyCode) {
    if (_profile.currencyCode == currencyCode) return;
    _profile = _profile.copyWith(currencyCode: currencyCode);
    notifyListeners();
  }

  // ── Profile ────────────────────────────────────────────────────────────────

  /// Replaces the user profile.
  void updateProfile(UserProfile updated) {
    _profile = updated;
    notifyListeners();
  }

  /// Called by [AuthGate] (or a stream listener) when Firestore emits a new
  /// profile snapshot. This is the single source of truth for profile data.
  ///
  /// Identical to [updateProfile] but named distinctly so call-sites are clear.
  void applyProfileSnapshot(UserProfile updated) {
    _profile = updated;
    notifyListeners();
  }

  // ── Notifications ──────────────────────────────────────────────────────────

  /// Marks a single notification as read by [id].
  void markNotificationRead(String id) {
    final i = _notifications.indexWhere((n) => n.id == id);
    if (i != -1 && _notifications[i].unread) {
      _notifications[i] = _notifications[i].copyWith(unread: false);
      notifyListeners();
    }
  }

  /// Marks every notification as read.
  void markAllNotificationsRead() {
    var changed = false;
    for (var i = 0; i < _notifications.length; i++) {
      if (_notifications[i].unread) {
        _notifications[i] = _notifications[i].copyWith(unread: false);
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  // ── Month selection ────────────────────────────────────────────────────────

  /// Changes the active month/year for all month-scoped views.
  void setSelectedMonth(int month, int year) {
    assert(month >= 1 && month <= 12, 'month must be 1–12');
    if (_selectedMonth == month && _selectedYear == year) return;
    _selectedMonth = month;
    _selectedYear = year;
    notifyListeners();
  }

  // ── Filter ─────────────────────────────────────────────────────────────────

  /// Filters by category id. Pass `null` to clear.
  void setFilterCategory(String? categoryId) {
    _filter = _filter.copyWith(categoryId: categoryId);
    notifyListeners();
  }

  /// Filters by type: `true` = income, `false` = expense, `null` = both.
  void setFilterType(bool? isIncome) {
    _filter = _filter.copyWith(isIncome: isIncome);
    notifyListeners();
  }

  /// Filters by [query] against title and note fields.
  void setSearchQuery(String query) {
    if (_filter.searchQuery == query) return;
    _filter = _filter.copyWith(searchQuery: query);
    notifyListeners();
  }

  /// Resets all filters to defaults.
  void clearFilters() {
    if (!_filter.isActive) return;
    _filter = const TransactionFilter();
    notifyListeners();
  }

  // ── Notification settings ──────────────────────────────────────────────────

  void setExpenseReminders(bool v) {
    _expenseReminders = v;
    notifyListeners();
  }

  void setRemindEvery(String v) {
    _remindEvery = v;
    notifyListeners();
  }

  void setQuietFrom(int hour, int min) {
    _quietFromHour = hour;
    _quietFromMin = min;
    notifyListeners();
  }

  void setQuietTo(int hour, int min) {
    _quietToHour = hour;
    _quietToMin = min;
    notifyListeners();
  }

  void setSkipIfLogged(bool v) {
    _skipIfLogged = v;
    notifyListeners();
  }

  void setBudgetAlerts(bool v) {
    _budgetAlerts = v;
    notifyListeners();
  }

  // ── Managed categories ─────────────────────────────────────────────────────

  /// Appends [cat] to the managed-category list.
  void addManagedCategory(ManagedCategory cat) {
    _managedCategories.add(cat);
    notifyListeners();
  }

  /// Replaces the managed category with the same [ManagedCategory.id].
  void updateManagedCategory(ManagedCategory cat) {
    final i = _managedCategories.indexWhere((c) => c.id == cat.id);
    if (i != -1) {
      _managedCategories[i] = cat;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _txSub?.cancel();
    super.dispose();
  }
}
