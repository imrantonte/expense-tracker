import 'package:flutter/foundation.dart' hide Category;

import '../models/managed_category.dart';
import '../models/models.dart';
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
/// All other data is currently in-memory (mock).
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
        _transactions = List.from(mock.mockTransactions),
        _notifications = List.from(mock.mockNotifications),
        _budget = mock.mockBudget,
        _managedCategories = List.from(mock.mockManagedCategories),
        _selectedMonth = 10,
        _selectedYear = 2026,
        _filter = const TransactionFilter();

  // ── Core data ──────────────────────────────────────────────────────────────

  UserProfile _profile;
  final List<TransactionItem> _transactions;
  final List<AppNotification> _notifications;
  Budget _budget;
  // ignore: prefer_final_fields — mutated by index in updateManagedCategory
  List<ManagedCategory> _managedCategories;

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

  /// Amount spent against the budget this month (from mock constant).
  double get budgetSpent => mock.mockMonthSpent;

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
    final list = _transactions
        .where((t) =>
            t.date.month == _selectedMonth && t.date.year == _selectedYear)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return list;
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

  // ── Month summary constants ─────────────────────────────────────────────────
  //
  // Fixed demo values representing the full October 2026 picture.
  // Kept separate from the 6 seed rows so the UI shows realistic totals.

  double get monthEarned => mock.mockMonthEarned;
  double get monthSpent => mock.mockMonthSpent;
  double get monthLeft => mock.mockMonthLeft;

  /// Category spending breakdown — categoryId → taka amount.
  Map<String, double> get categoryBreakdown => mock.mockCategoryBreakdown;

  /// Category spending as percentages — categoryId → 0–100.
  Map<String, double> get categoryPercent => mock.mockCategoryPercent;

  /// Weekly income figures (4 data points, weeks 1–4).
  List<double> get weeklyIncome => mock.mockWeeklyIncome;

  /// Weekly expense figures (4 data points, weeks 1–4).
  List<double> get weeklyExpenses => mock.mockWeeklyExpenses;

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

  /// Inserts [item] at the front of the transaction list.
  void addTransaction(TransactionItem item) {
    _transactions.insert(0, item);
    notifyListeners();
  }

  /// Replaces the transaction with the same [TransactionItem.id].
  void updateTransaction(TransactionItem item) {
    final i = _transactions.indexWhere((t) => t.id == item.id);
    if (i != -1) {
      _transactions[i] = item;
      notifyListeners();
    }
  }

  /// Removes the transaction with [id].
  void deleteTransaction(String id) {
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
}
