import '../models/transaction_item.dart';
import '../models/budget.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Period type
// ─────────────────────────────────────────────────────────────────────────────

enum ReportPeriodType { day, week, month, custom }

// ─────────────────────────────────────────────────────────────────────────────
// Budget status
// ─────────────────────────────────────────────────────────────────────────────

enum BudgetStatus { onTrack, nearLimit, overBudget, nobudget, multiMonth }

// ─────────────────────────────────────────────────────────────────────────────
// Time-bucket row (for income vs expenses breakdown table)
// ─────────────────────────────────────────────────────────────────────────────

class BucketRow {
  const BucketRow({
    required this.label,
    required this.income,
    required this.expenses,
  });

  final String label;
  final double income;
  final double expenses;

  double get net => income - expenses;
}

// ─────────────────────────────────────────────────────────────────────────────
// Category summary row
// ─────────────────────────────────────────────────────────────────────────────

class CategoryRow {
  const CategoryRow({
    required this.name,
    required this.transactionCount,
    required this.amount,
    required this.sharePct,
  });

  final String name;
  final int transactionCount;
  final double amount;
  final double sharePct; // 0–100
}

// ─────────────────────────────────────────────────────────────────────────────
// Full report calculation result
// ─────────────────────────────────────────────────────────────────────────────

class ReportData {
  const ReportData({
    required this.transactions,
    required this.totalIncome,
    required this.totalExpenses,
    required this.net,
    required this.transactionCount,
    required this.topCategory,
    required this.topCategoryAmount,
    required this.topCategorySharePct,
    required this.largestExpense,
    required this.avgSpendingPerDay,
    required this.savingsRatePct,
    required this.categoryRows,
    required this.bucketRows,
    required this.budgetStatus,
    required this.budgetLimit,
    required this.budgetSpent,
    required this.budgetRemaining,
    required this.budgetUsagePct,
    required this.budgetAlertThreshold,
  });

  final List<TransactionItem> transactions;
  final double totalIncome;
  final double totalExpenses;
  final double net;
  final int transactionCount;

  // Insight fields
  final String? topCategory;
  final double topCategoryAmount;
  final double topCategorySharePct;
  final TransactionItem? largestExpense;
  final double avgSpendingPerDay;
  final double? savingsRatePct; // null when no income

  // Category breakdown
  final List<CategoryRow> categoryRows;

  // Income vs Expenses time buckets
  final List<BucketRow> bucketRows;

  // Budget
  final BudgetStatus budgetStatus;
  final double budgetLimit;
  final double budgetSpent;
  final double budgetRemaining;
  final double budgetUsagePct; // 0–100+
  final double budgetAlertThreshold; // 0–1
}

// ─────────────────────────────────────────────────────────────────────────────
// Pure calculation helper (no Flutter / Firebase dependencies)
// ─────────────────────────────────────────────────────────────────────────────

class ReportCalculations {
  /// Filters [allTransactions] to those whose date falls within
  /// [rangeStart]..[rangeEnd] (inclusive, date-only comparison).
  static List<TransactionItem> filterByRange(
    List<TransactionItem> allTransactions,
    DateTime rangeStart,
    DateTime rangeEnd,
  ) {
    final start = DateTime(rangeStart.year, rangeStart.month, rangeStart.day);
    final end = DateTime(rangeEnd.year, rangeEnd.month, rangeEnd.day, 23, 59, 59);
    return allTransactions
        .where((t) => !t.date.isBefore(start) && !t.date.isAfter(end))
        .toList();
  }

  /// Builds category rows sorted by amount desc.
  static List<CategoryRow> buildCategoryRows(
    List<TransactionItem> transactions,
    String Function(String categoryId) categoryName,
  ) {
    final map = <String, List<TransactionItem>>{};
    for (final t in transactions.where((t) => !t.isIncome)) {
      map.putIfAbsent(t.categoryId, () => []).add(t);
    }
    final total = map.values
        .expand((l) => l)
        .fold(0.0, (s, t) => s + t.amount);
    final rows = map.entries.map((e) {
      final amount = e.value.fold(0.0, (s, t) => s + t.amount);
      return CategoryRow(
        name: categoryName(e.key),
        transactionCount: e.value.length,
        amount: amount,
        sharePct: total > 0 ? (amount / total * 100) : 0,
      );
    }).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
    return rows;
  }

  /// Builds time-bucket rows.
  /// - Day / Week (≤ 14 days): one row per day.
  /// - Month (≤ 60 days): one row per week of month (Wk 1…4).
  /// - Longer: one row per calendar month.
  static List<BucketRow> buildBucketRows(
    List<TransactionItem> transactions,
    DateTime rangeStart,
    DateTime rangeEnd,
  ) {
    final days = rangeEnd.difference(rangeStart).inDays + 1;
    if (days <= 14) {
      return _byDay(transactions, rangeStart, rangeEnd);
    } else if (days <= 60) {
      return _byWeekOfMonth(transactions, rangeStart);
    } else {
      return _byMonth(transactions, rangeStart, rangeEnd);
    }
  }

  static List<BucketRow> _byDay(
    List<TransactionItem> txns,
    DateTime start,
    DateTime end,
  ) {
    final rows = <BucketRow>[];
    var d = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);
    while (!d.isAfter(endDay)) {
      final dayTxns = txns.where((t) =>
          t.date.year == d.year &&
          t.date.month == d.month &&
          t.date.day == d.day);
      rows.add(BucketRow(
        label: '${d.day}/${d.month}',
        income: dayTxns.where((t) => t.isIncome).fold(0.0, (s, t) => s + t.amount),
        expenses: dayTxns.where((t) => !t.isIncome).fold(0.0, (s, t) => s + t.amount),
      ));
      d = d.add(const Duration(days: 1));
    }
    return rows;
  }

  static List<BucketRow> _byWeekOfMonth(
    List<TransactionItem> txns,
    DateTime start,
  ) {
    final result = [
      _MutableBucket('Wk 1'),
      _MutableBucket('Wk 2'),
      _MutableBucket('Wk 3'),
      _MutableBucket('Wk 4'),
    ];
    for (final t in txns) {
      final wk = ((t.date.day - 1) ~/ 7).clamp(0, 3);
      if (t.isIncome) {
        result[wk].income += t.amount;
      } else {
        result[wk].expenses += t.amount;
      }
    }
    return result.map((b) => BucketRow(label: b.label, income: b.income, expenses: b.expenses)).toList();
  }

  static List<BucketRow> _byMonth(
    List<TransactionItem> txns,
    DateTime start,
    DateTime end,
  ) {
    final map = <String, _MutableBucket>{};
    for (final t in txns) {
      final key = '${t.date.year}-${t.date.month.toString().padLeft(2, '0')}';
      map.putIfAbsent(key, () => _MutableBucket(_monthLabel(t.date)));
      if (t.isIncome) {
        map[key]!.income += t.amount;
      } else {
        map[key]!.expenses += t.amount;
      }
    }
    final keys = map.keys.toList()..sort();
    return keys.map((k) => BucketRow(
      label: map[k]!.label,
      income: map[k]!.income,
      expenses: map[k]!.expenses,
    )).toList();
  }

  static String _monthLabel(DateTime d) {
    const names = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${names[d.month - 1]} ${d.year}';
  }

  /// Determines budget status for a single-month range.
  /// Returns [BudgetStatus.multiMonth] when the range spans multiple months.
  static BudgetStatus budgetStatus({
    required DateTime rangeStart,
    required DateTime rangeEnd,
    required Budget? budget,
    required double spent,
  }) {
    // Check if range spans multiple months.
    if (rangeStart.year != rangeEnd.year || rangeStart.month != rangeEnd.month) {
      return BudgetStatus.multiMonth;
    }
    if (budget == null || budget.limit <= 0) return BudgetStatus.nobudget;
    final usage = spent / budget.limit;
    if (usage > 1.0) return BudgetStatus.overBudget;
    if (usage >= budget.alertThreshold) return BudgetStatus.nearLimit;
    return BudgetStatus.onTrack;
  }

  /// Main entry point: computes the full [ReportData] from raw inputs.
  static ReportData compute({
    required List<TransactionItem> allTransactions,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    required Budget? budget,
    required String Function(String categoryId) categoryName,
  }) {
    final txns = filterByRange(allTransactions, rangeStart, rangeEnd)
      ..sort((a, b) => b.date.compareTo(a.date));

    final income = txns.where((t) => t.isIncome).fold(0.0, (s, t) => s + t.amount);
    final expenses = txns.where((t) => !t.isIncome).fold(0.0, (s, t) => s + t.amount);
    final net = income - expenses;

    final categoryRows = buildCategoryRows(txns, categoryName);
    final bucketRows = buildBucketRows(txns, rangeStart, rangeEnd);

    final String? topCat = categoryRows.isEmpty ? null : categoryRows.first.name;
    final double topCatAmount = categoryRows.isEmpty ? 0 : categoryRows.first.amount;
    final double topCatPct = categoryRows.isEmpty ? 0 : categoryRows.first.sharePct;

    final expenses_ = txns.where((t) => !t.isIncome).toList();
    TransactionItem? largest;
    if (expenses_.isNotEmpty) {
      largest = expenses_.reduce((a, b) => a.amount >= b.amount ? a : b);
    }

    final days = rangeEnd.difference(rangeStart).inDays + 1;
    final avg = days > 0 ? expenses / days : 0.0;
    final savingsRate = income > 0 ? (net / income * 100) : null;

    final bStatus = budgetStatus(
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
      budget: budget,
      spent: expenses,
    );
    final bLimit = budget?.limit ?? 0.0;
    final bSpent = expenses;
    final bRemaining = bLimit > 0 ? (bLimit - bSpent).clamp(0.0, double.infinity) : 0.0;
    final bUsagePct = bLimit > 0 ? (bSpent / bLimit * 100) : 0.0;

    return ReportData(
      transactions: txns,
      totalIncome: income,
      totalExpenses: expenses,
      net: net,
      transactionCount: txns.length,
      topCategory: topCat,
      topCategoryAmount: topCatAmount,
      topCategorySharePct: topCatPct,
      largestExpense: largest,
      avgSpendingPerDay: avg,
      savingsRatePct: savingsRate,
      categoryRows: categoryRows,
      bucketRows: bucketRows,
      budgetStatus: bStatus,
      budgetLimit: bLimit,
      budgetSpent: bSpent,
      budgetRemaining: bRemaining,
      budgetUsagePct: bUsagePct.toDouble(),
      budgetAlertThreshold: budget?.alertThreshold ?? 0.8,
    );
  }
}

class _MutableBucket {
  _MutableBucket(this.label);
  final String label;
  double income = 0;
  double expenses = 0;
}
