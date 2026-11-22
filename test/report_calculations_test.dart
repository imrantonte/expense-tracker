import 'package:flutter_test/flutter_test.dart';
import 'package:where_did_it_go/models/transaction_item.dart';
import 'package:where_did_it_go/models/budget.dart';
import 'package:where_did_it_go/services/report_calculations.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Test helpers
// ─────────────────────────────────────────────────────────────────────────────

TransactionItem _tx({
  required String id,
  required double amount,
  required bool isIncome,
  required DateTime date,
  String categoryId = 'food',
  String title = 'Test',
}) =>
    TransactionItem(
      id: id,
      title: title,
      categoryId: categoryId,
      amount: amount,
      date: date,
      isIncome: isIncome,
    );

final _nov1  = DateTime(2026, 11, 1);
final _nov30 = DateTime(2026, 11, 30);
final _dec1  = DateTime(2026, 12, 1);

final _sampleTxns = [
  _tx(id: '1', amount: 10000, isIncome: true,  date: _nov1,  categoryId: 'salary'),
  _tx(id: '2', amount: 1000,  isIncome: false, date: _nov1,  categoryId: 'food',      title: 'Lunch'),
  _tx(id: '3', amount: 500,   isIncome: false, date: _nov15, categoryId: 'transport', title: 'Bus'),
  _tx(id: '4', amount: 200,   isIncome: false, date: _dec1,  categoryId: 'food',      title: 'Dec expense'),
];

DateTime get _nov15 => DateTime(2026, 11, 15);

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('ReportCalculations.filterByRange', () {
    test('includes transactions exactly on start and end date', () {
      final result = ReportCalculations.filterByRange(_sampleTxns, _nov1, _nov30);
      final ids = result.map((t) => t.id).toSet();
      expect(ids, containsAll(['1', '2', '3']));
      expect(ids, isNot(contains('4'))); // Dec 1 outside range
    });

    test('excludes all when range is in the future', () {
      final future = DateTime(2030, 1, 1);
      expect(ReportCalculations.filterByRange(_sampleTxns, future, future), isEmpty);
    });

    test('single-day filter returns only that day', () {
      final result = ReportCalculations.filterByRange(_sampleTxns, _nov1, _nov1);
      expect(result.map((t) => t.id).toSet(), {'1', '2'});
    });
  });

  group('ReportCalculations.buildCategoryRows', () {
    final txns = ReportCalculations.filterByRange(_sampleTxns, _nov1, _nov30);

    test('only expenses are included in category rows', () {
      final rows = ReportCalculations.buildCategoryRows(txns, (id) => id);
      expect(rows.any((r) => r.name == 'salary'), isFalse);
    });

    test('rows sorted by amount desc', () {
      final rows = ReportCalculations.buildCategoryRows(txns, (id) => id);
      expect(rows.first.name, 'food'); // 1000 > 500
      expect(rows.last.name, 'transport');
    });

    test('share percentages sum to 100', () {
      final rows = ReportCalculations.buildCategoryRows(txns, (id) => id);
      final total = rows.fold(0.0, (s, r) => s + r.sharePct);
      expect(total, closeTo(100.0, 0.5));
    });

    test('transaction count is correct', () {
      final rows = ReportCalculations.buildCategoryRows(txns, (id) => id);
      final food = rows.firstWhere((r) => r.name == 'food');
      expect(food.transactionCount, 1);
    });
  });

  group('ReportCalculations.budgetStatus', () {
    final budget80 = const Budget(limit: 10000, alertThreshold: 0.8);

    test('on track when below alert threshold', () {
      final status = ReportCalculations.budgetStatus(
        rangeStart: _nov1, rangeEnd: _nov30, budget: budget80, spent: 5000,
      );
      expect(status, BudgetStatus.onTrack);
    });

    test('near limit when >= alert threshold and <= 100%', () {
      final status = ReportCalculations.budgetStatus(
        rangeStart: _nov1, rangeEnd: _nov30, budget: budget80, spent: 8500,
      );
      expect(status, BudgetStatus.nearLimit);
    });

    test('over budget when spent > limit', () {
      final status = ReportCalculations.budgetStatus(
        rangeStart: _nov1, rangeEnd: _nov30, budget: budget80, spent: 12000,
      );
      expect(status, BudgetStatus.overBudget);
    });

    test('multiMonth when range spans two months', () {
      final status = ReportCalculations.budgetStatus(
        rangeStart: _nov1, rangeEnd: _dec1, budget: budget80, spent: 100,
      );
      expect(status, BudgetStatus.multiMonth);
    });

    test('nobudget when budget is null', () {
      final status = ReportCalculations.budgetStatus(
        rangeStart: _nov1, rangeEnd: _nov30, budget: null, spent: 100,
      );
      expect(status, BudgetStatus.nobudget);
    });
  });

  group('ReportCalculations.compute', () {
    test('totals are correct', () {
      final data = ReportCalculations.compute(
        allTransactions: _sampleTxns,
        rangeStart: _nov1,
        rangeEnd: _nov30,
        budget: null,
        categoryName: (id) => id,
      );
      expect(data.totalIncome, 10000);
      expect(data.totalExpenses, 1500);
      expect(data.net, 8500);
      expect(data.transactionCount, 3);
    });

    test('savings rate is correct', () {
      final data = ReportCalculations.compute(
        allTransactions: _sampleTxns,
        rangeStart: _nov1,
        rangeEnd: _nov30,
        budget: null,
        categoryName: (id) => id,
      );
      // net=8500, income=10000 → 85%
      expect(data.savingsRatePct, closeTo(85.0, 0.1));
    });

    test('savings rate is null when no income', () {
      final noIncome = _sampleTxns.where((t) => !t.isIncome).toList();
      final data = ReportCalculations.compute(
        allTransactions: noIncome,
        rangeStart: _nov1,
        rangeEnd: _nov30,
        budget: null,
        categoryName: (id) => id,
      );
      expect(data.savingsRatePct, isNull);
    });

    test('largest expense is identified', () {
      final data = ReportCalculations.compute(
        allTransactions: _sampleTxns,
        rangeStart: _nov1,
        rangeEnd: _nov30,
        budget: null,
        categoryName: (id) => id,
      );
      expect(data.largestExpense?.amount, 1000);
      expect(data.largestExpense?.title, 'Lunch');
    });

    test('empty range returns zero totals', () {
      final data = ReportCalculations.compute(
        allTransactions: _sampleTxns,
        rangeStart: DateTime(2020, 1, 1),
        rangeEnd: DateTime(2020, 1, 31),
        budget: null,
        categoryName: (id) => id,
      );
      expect(data.totalIncome, 0);
      expect(data.totalExpenses, 0);
      expect(data.transactionCount, 0);
    });
  });

  group('ReportCalculations.buildBucketRows', () {
    test('day range <= 14 produces per-day rows', () {
      final txns = ReportCalculations.filterByRange(_sampleTxns, _nov1, _nov30.subtract(const Duration(days: 17)));
      final rows = ReportCalculations.buildBucketRows(txns, _nov1, DateTime(2026, 11, 7));
      expect(rows.length, 7); // 7 days
    });

    test('month range produces 4 weekly rows', () {
      final txns = ReportCalculations.filterByRange(_sampleTxns, _nov1, _nov30);
      final rows = ReportCalculations.buildBucketRows(txns, _nov1, _nov30);
      expect(rows.length, 4);
      expect(rows.first.label, 'Wk 1');
    });
  });
}
