import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme_ext.dart';
import '../../core/constants.dart';
import '../../data/app_state.dart';
import '../../models/category.dart';
import '../../models/transaction_item.dart';
import '../../widgets/app_card.dart';
import '../../widgets/primary_button.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AddTransactionScreen
// ─────────────────────────────────────────────────────────────────────────────

/// Full-page form for adding **or editing** a transaction.
///
/// Pass [prefilled] to enter Edit mode.
/// Pass [initialIsExpense] to pre-select the type toggle.
class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({
    super.key,
    this.prefilled,
    this.initialIsExpense = true,
  });

  /// When non-null the form is in Edit mode, pre-populating all fields.
  final TransactionItem? prefilled;

  /// Which tab is active when opening a blank form (default: Expense).
  final bool initialIsExpense;

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  late bool _isExpense;
  String? _selectedCategoryId;
  late DateTime _selectedDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.prefilled != null) {
      final tx = widget.prefilled!;
      _isExpense = !tx.isIncome;
      final v = tx.amount;
      _amountCtrl.text =
          v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);
      _selectedCategoryId = tx.categoryId;
      _selectedDate = tx.date;
      _noteCtrl.text = tx.note ?? '';
    } else {
      _isExpense = widget.initialIsExpense;
      _selectedDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  List<Category> _categories(AppState state) =>
      _isExpense ? state.expenseCategories : state.incomeCategories;

  String _formatDate(DateTime d) {
    final today = DateTime.now();
    final isToday =
        d.day == today.day && d.month == today.month && d.year == today.year;
    final label = DateFormat('d MMM yyyy').format(d);
    return isToday ? 'Today, $label' : label;
  }

  // ── Save ────────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    final amtText = _amountCtrl.text.trim();
    final amount = double.tryParse(amtText) ?? 0;

    if (amount <= 0) {
      _snack('Please enter an amount greater than zero.');
      return;
    }
    if (_selectedCategoryId == null) {
      _snack('Please select a category.');
      return;
    }

    setState(() => _saving = true);

    final state = context.read<AppState>();
    final isEditing = widget.prefilled != null;
    final noteText = _noteCtrl.text.trim();
    final cat = state.findCategory(_selectedCategoryId!);

    final tx = TransactionItem(
      id: isEditing
          ? widget.prefilled!.id
          : 'tx_${DateTime.now().millisecondsSinceEpoch}',
      title: noteText.isEmpty ? (cat?.name ?? _selectedCategoryId!) : noteText,
      note: noteText.isEmpty ? null : noteText,
      categoryId: _selectedCategoryId!,
      amount: amount,
      date: _selectedDate,
      isIncome: !_isExpense,
    );

    if (isEditing) {
      state.updateTransaction(tx);
    } else {
      state.addTransaction(tx);
    }

    if (!mounted) return;

    // Check budget exceeded (expenses only)
    if (_isExpense && !_isOverBudget(state)) {
      _snack(isEditing ? 'Transaction updated.' : 'Expense saved.');
      Navigator.pop(context);
      return;
    }

    if (_isExpense && _isOverBudget(state)) {
      setState(() => _saving = false);
      await _showBudgetExceededDialog(state);
    } else {
      _snack(isEditing ? 'Transaction updated.' : 'Income saved.');
      Navigator.pop(context);
    }
  }

  bool _isOverBudget(AppState state) {
    // Compute live total from actual transactions
    final spent = state.transactions
        .where((t) => !t.isIncome)
        .fold(0.0, (s, t) => s + t.amount);
    return spent > state.budget.limit;
  }

  double _overAmount(AppState state) {
    final spent = state.transactions
        .where((t) => !t.isIncome)
        .fold(0.0, (s, t) => s + t.amount);
    return (spent - state.budget.limit).clamp(0, double.infinity);
  }

  double _totalSpent(AppState state) => state.transactions
      .where((t) => !t.isIncome)
      .fold(0.0, (s, t) => s + t.amount);

  Future<void> _showBudgetExceededDialog(AppState state) async {
    final sym = state.currencySymbol;
    final over = _overAmount(state);
    final total = _totalSpent(state);
    final month = DateFormat('MMMM').format(
      DateTime(state.selectedYear, state.selectedMonth),
    );

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _BudgetExceededDialog(
        sym: sym,
        overAmount: over,
        total: total,
        month: month,
        onOk: () {
          Navigator.of(ctx).pop();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── Date picker ─────────────────────────────────────────────────────────────

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030, 12, 31),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExt>()!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final state = context.watch<AppState>();
    final sym = state.currencySymbol;
    final cats = _categories(state);
    final isEditing = widget.prefilled != null;

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(
          isEditing ? 'Edit Transaction' : 'Add Transaction',
          style: tt.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: kFontScreenTitle,
            color: ext.textPrimary,
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: ext.textPrimary,
      ),
      body: SingleChildScrollView(
        padding:
            const EdgeInsets.fromLTRB(kSp16, kSp16, kSp16, kSp16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Expense / Income toggle ─────────────────────────────────
            _TypeToggle(
              isExpense: _isExpense,
              onChanged: (v) => setState(() {
                _isExpense = v;
                _selectedCategoryId = null;
              }),
            ),
            const SizedBox(height: kSp16),

            // ── Amount card ─────────────────────────────────────────────
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Amount',
                    style: tt.bodySmall?.copyWith(color: ext.textSecondary),
                  ),
                  const SizedBox(height: kSp8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        sym,
                        style: TextStyle(
                          color: cs.primary,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: kSp4),
                      Expanded(
                        child: TextField(
                          controller: _amountCtrl,
                          keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d{0,2}')),
                          ],
                          style: TextStyle(
                            color: ext.textPrimary,
                            fontSize: kFontAmountLg,
                            fontWeight: FontWeight.w800,
                          ),
                          decoration: InputDecoration(
                            hintText: '0',
                            hintStyle: TextStyle(
                              color:
                                  ext.textSecondary.withAlpha(120),
                              fontSize: kFontAmountLg,
                              fontWeight: FontWeight.w800,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      Text(
                        '.00',
                        style: TextStyle(
                          color: ext.textSecondary,
                          fontSize: 28,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: kSp20),

            // ── Category label ─────────────────────────────────────────
            Text(
              'Category',
              style: tt.titleSmall?.copyWith(
                color: ext.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: kSp12),

            // ── Category grid (3 columns) ──────────────────────────────
            GridView.count(
              crossAxisCount: 3,
              crossAxisSpacing: kSp10,
              mainAxisSpacing: kSp10,
              childAspectRatio: 0.95,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: cats.map((cat) {
                final selected = _selectedCategoryId == cat.id;
                return _CategoryChip(
                  category: cat,
                  isSelected: selected,
                  onTap: () =>
                      setState(() => _selectedCategoryId = cat.id),
                );
              }).toList(),
            ),
            const SizedBox(height: kSp20),

            // ── Date field ─────────────────────────────────────────────
            GestureDetector(
              onTap: _pickDate,
              child: AppCard(
                child: Row(
                  children: [
                    Icon(Icons.calendar_month_outlined,
                        color: cs.primary, size: 20),
                    const SizedBox(width: kSp12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Date',
                              style: tt.bodySmall
                                  ?.copyWith(color: ext.textSecondary)),
                          const SizedBox(height: kSp2),
                          Text(_formatDate(_selectedDate),
                              style: tt.bodyMedium
                                  ?.copyWith(color: ext.textPrimary)),
                        ],
                      ),
                    ),
                    Icon(Icons.keyboard_arrow_down_rounded,
                        color: ext.textSecondary, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: kSp12),

            // ── Note field ─────────────────────────────────────────────
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Note (optional)',
                      style: tt.bodySmall
                          ?.copyWith(color: ext.textSecondary)),
                  const SizedBox(height: kSp4),
                  TextField(
                    controller: _noteCtrl,
                    style: tt.bodyMedium?.copyWith(color: ext.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Add a note…',
                      hintStyle: tt.bodyMedium
                          ?.copyWith(color: ext.textSecondary.withAlpha(128)),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(height: kSp32),

            // ── Save button ────────────────────────────────────────────
            PrimaryButton(
              label: 'Save',
              isLoading: _saving,
              onPressed: _save,
            ),
            const SizedBox(height: kSp16),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Expense / Income segmented toggle
// ─────────────────────────────────────────────────────────────────────────────

class _TypeToggle extends StatelessWidget {
  const _TypeToggle({
    required this.isExpense,
    required this.onChanged,
  });

  final bool isExpense;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExt>()!;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: ext.cardBackground,
        borderRadius: BorderRadius.circular(kRadiusButton),
        border: Border.all(color: ext.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ToggleOption(
              label: 'Expense',
              isSelected: isExpense,
              onTap: () => onChanged(true),
            ),
          ),
          Expanded(
            child: _ToggleOption(
              label: 'Income',
              isSelected: !isExpense,
              onTap: () => onChanged(false),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  const _ToggleOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExt>()!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: kSp10),
        decoration: BoxDecoration(
          color: isSelected ? ext.tint : Colors.transparent,
          borderRadius: BorderRadius.circular(kRadiusButton - 4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSelected) ...[
              Icon(Icons.check_rounded, size: 15, color: cs.primary),
              const SizedBox(width: kSp4),
            ],
            Text(
              label,
              style: tt.bodyMedium?.copyWith(
                color: isSelected ? cs.primary : ext.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category chip
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  final Category category;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExt>()!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          // ── Chip body ────────────────────────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: isSelected ? ext.tint : ext.cardBackground,
              borderRadius: BorderRadius.circular(kRadiusCard),
              border: Border.all(
                color: isSelected ? cs.primary : ext.cardBorder,
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  category.icon,
                  size: 26,
                  color: isSelected ? cs.primary : ext.textSecondary,
                ),
                const SizedBox(height: kSp6),
                Text(
                  category.name,
                  style: tt.bodySmall?.copyWith(
                    color: isSelected ? cs.primary : ext.textPrimary,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // ── Check badge (top-right) ──────────────────────────────────
          if (isSelected)
            Positioned(
              top: 5,
              right: 5,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: cs.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    size: 12, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Budget Exceeded dialog
// ─────────────────────────────────────────────────────────────────────────────

class _BudgetExceededDialog extends StatelessWidget {
  const _BudgetExceededDialog({
    required this.sym,
    required this.overAmount,
    required this.total,
    required this.month,
    required this.onOk,
  });

  final String sym;
  final double overAmount;
  final double total;
  final String month;
  final VoidCallback onOk;

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExt>()!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final nf = NumberFormat('#,##0');

    return Dialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(kSp24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Red warning icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: ext.expense.withAlpha(22),
                borderRadius: BorderRadius.circular(kSp16),
              ),
              child: Icon(Icons.warning_amber_rounded,
                  size: 30, color: ext.expense),
            ),
            const SizedBox(height: kSp16),
            Text(
              'Budget exceeded.',
              style: tt.titleMedium?.copyWith(
                color: ext.textPrimary,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: kSp8),
            Text(
              'This expense put you $sym${nf.format(overAmount.toInt())} '
              'over your monthly limit.',
              style: tt.bodyMedium?.copyWith(color: ext.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: kSp12),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: kSp16, vertical: kSp8),
              decoration: BoxDecoration(
                color: ext.tint,
                borderRadius: BorderRadius.circular(kSp8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$month total',
                    style: tt.bodySmall?.copyWith(color: ext.textSecondary),
                  ),
                  const SizedBox(width: kSp8),
                  Text(
                    '$sym${nf.format(total.toInt())}',
                    style: tt.bodySmall?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: kSp24),
            SizedBox(
              width: double.infinity,
              height: kButtonHeight,
              child: FilledButton(
                onPressed: onOk,
                child: const Text('OK'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
