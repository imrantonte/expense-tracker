import 'package:flutter/foundation.dart' hide Category;
import '../models/expense.dart';

/// Legacy expense state holder — superseded by [AppState].
///
/// Kept as a stub so any stale import paths continue to resolve.
/// New code should use [AppState] exclusively.
class ExpenseProvider extends ChangeNotifier {
  ExpenseProvider() : _expenses = [];

  final List<Expense> _expenses;

  List<Expense> get expenses => List.unmodifiable(_expenses);

  double get totalSpent =>
      _expenses.fold(0.0, (sum, e) => sum + e.amount);

  void addExpense(Expense expense) {
    _expenses.insert(0, expense);
    notifyListeners();
  }

  void removeExpense(String id) {
    _expenses.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  void updateExpense(Expense updated) {
    final index = _expenses.indexWhere((e) => e.id == updated.id);
    if (index != -1) {
      _expenses[index] = updated;
      notifyListeners();
    }
  }
}
