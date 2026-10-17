import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme_ext.dart';
import '../../core/constants.dart';
import '../../data/app_state.dart';
import '../../models/transaction_item.dart';
import '../../widgets/app_card.dart';
import '../../widgets/primary_button.dart';
import '../add_transaction/add_transaction_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TransactionDetailScreen
// ─────────────────────────────────────────────────────────────────────────────

/// Displays the full details of a [TransactionItem] with Edit and Delete actions.
class TransactionDetailScreen extends StatelessWidget {
  const TransactionDetailScreen({super.key, required this.transaction});

  final TransactionItem transaction;

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExt>()!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final state = context.watch<AppState>();
    final sym = state.currencySymbol;
    final cat = state.findCategory(transaction.categoryId);

    final isIncome = transaction.isIncome;
    final typeLabel = isIncome ? 'Income' : 'Expense';
    final typeColor = isIncome ? ext.income : ext.expense;

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(
          'Transaction Details',
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
      body: Padding(
        padding:
            const EdgeInsets.fromLTRB(kSp16, kSp8, kSp16, kSp16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Hero card ────────────────────────────────────────────────
            AppCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Type chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: kSp16, vertical: kSp6),
                    decoration: BoxDecoration(
                      color: typeColor.withAlpha(22),
                      borderRadius: BorderRadius.circular(kRadiusButton),
                    ),
                    child: Text(
                      typeLabel,
                      style: tt.labelMedium?.copyWith(
                        color: typeColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: kSp12),

                  // Amount
                  _AmountDisplay(
                    sym: sym,
                    amount: transaction.amount,
                    ext: ext,
                    cs: cs,
                  ),
                  const SizedBox(height: kSp12),

                  // Category icon + name
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (cat != null)
                        Icon(cat.icon, size: 22, color: cs.primary),
                      const SizedBox(width: kSp8),
                      Text(
                        cat?.name ?? transaction.categoryId,
                        style: tt.titleSmall?.copyWith(
                          color: ext.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: kSp4),
                ],
              ),
            ),
            const SizedBox(height: kSp20),

            // ── Transaction info label ────────────────────────────────────
            Text(
              'Transaction info',
              style: tt.titleSmall?.copyWith(
                color: ext.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: kSp8),

            // ── Info card ─────────────────────────────────────────────────
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _InfoRow(
                    icon: Icons.calendar_month_outlined,
                    label: 'Date',
                    value: _formatDate(transaction.date),
                    ext: ext,
                    cs: cs,
                  ),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: ext.divider,
                    indent: kSp16,
                    endIndent: kSp16,
                  ),
                  _InfoRow(
                    icon: Icons.notes_rounded,
                    label: 'Note',
                    value: (transaction.note?.isNotEmpty == true)
                        ? transaction.note!
                        : transaction.title,
                    ext: ext,
                    cs: cs,
                  ),
                ],
              ),
            ),

            const Spacer(),

            // ── Edit button ───────────────────────────────────────────────
            PrimaryButton(
              label: 'Edit',
              icon: Icons.edit_rounded,
              onPressed: () => _openEdit(context),
            ),
            const SizedBox(height: kSp12),

            // ── Delete button (red outlined) ──────────────────────────────
            _DeleteOutlinedButton(
              onPressed: () => _confirmDelete(context),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime d) {
    final today = DateTime.now();
    final isToday =
        d.day == today.day && d.month == today.month && d.year == today.year;
    final label = DateFormat('d MMM yyyy').format(d);
    return isToday ? 'Today, $label' : label;
  }

  void _openEdit(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(
          prefilled: transaction,
          initialIsExpense: !transaction.isIncome,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => const _DeleteDialog(),
    );
    if (confirmed == true && context.mounted) {
      context.read<AppState>().deleteTransaction(transaction.id);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text('Transaction deleted.')));
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Amount display  (teal ৳  dark-bold number  gray .00)
// ─────────────────────────────────────────────────────────────────────────────

class _AmountDisplay extends StatelessWidget {
  const _AmountDisplay({
    required this.sym,
    required this.amount,
    required this.ext,
    required this.cs,
  });

  final String sym;
  final double amount;
  final AppThemeExt ext;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final intPart = amount.toInt().toString();
    final decPart = '.${((amount - amount.toInt()) * 100).round().toString().padLeft(2, '0')}';

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          sym,
          style: TextStyle(
            color: cs.primary,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: kSp4),
        Text(
          intPart,
          style: TextStyle(
            color: ext.textPrimary,
            fontSize: 40,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          decPart,
          style: TextStyle(
            color: ext.textSecondary,
            fontSize: 24,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Info row (icon + label + value)
// ─────────────────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.ext,
    required this.cs,
  });

  final IconData icon;
  final String label;
  final String value;
  final AppThemeExt ext;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(kSp16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: cs.primary),
          const SizedBox(width: kSp12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label,
                  style: tt.bodySmall?.copyWith(color: ext.textSecondary)),
              const SizedBox(height: kSp2),
              Text(value,
                  style: tt.bodyMedium?.copyWith(color: ext.textPrimary)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Red outlined delete button
// ─────────────────────────────────────────────────────────────────────────────

class _DeleteOutlinedButton extends StatelessWidget {
  const _DeleteOutlinedButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExt>()!;
    final tt = Theme.of(context).textTheme;

    return SizedBox(
      width: double.infinity,
      height: kButtonHeight,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(Icons.delete_outline_rounded, color: ext.expense, size: 18),
        label: Text(
          'Delete',
          style: tt.labelLarge?.copyWith(
            color: ext.expense,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: ext.expense, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kRadiusButton),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Delete confirmation dialog
// ─────────────────────────────────────────────────────────────────────────────

class _DeleteDialog extends StatelessWidget {
  const _DeleteDialog();

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExt>()!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Dialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(kSp24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Red trash icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: ext.expense.withAlpha(22),
                borderRadius: BorderRadius.circular(kSp16),
              ),
              child: Icon(Icons.delete_outline_rounded,
                  size: 28, color: ext.expense),
            ),
            const SizedBox(height: kSp16),
            Text(
              'Delete this transaction?',
              style: tt.titleMedium?.copyWith(
                color: ext.textPrimary,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: kSp8),
            Text(
              'This cannot be undone.',
              style: tt.bodyMedium?.copyWith(color: ext.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: kSp24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: TextButton.styleFrom(
                      foregroundColor: cs.primary,
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: kSp12),
                Expanded(
                  child: SizedBox(
                    height: kButtonHeight,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: ext.expense,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(kRadiusButton),
                        ),
                      ),
                      child: const Text('Delete'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
