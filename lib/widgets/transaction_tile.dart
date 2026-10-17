import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/app_theme_ext.dart';
import '../core/constants.dart';
import '../models/models.dart';

// Comma-formatted integer amounts (e.g. 3000 → "3,000")
String _fmtAmt(double v) {
  if (v == v.roundToDouble()) return NumberFormat('#,##0').format(v.toInt());
  return NumberFormat('#,##0.00').format(v);
}

/// A list tile showing a single [TransactionItem].
///
/// Displays the category icon badge, title, category name, signed amount,
/// and date. All colours come from [AppThemeExt].
class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.transaction,
    required this.currencySymbol,
    this.category,
    this.onTap,
    this.showDivider = true,
    this.showNote = false,
  });

  final TransactionItem transaction;

  /// Resolved [Category] for this transaction (may be null if id is unknown).
  final Category? category;

  /// Currency symbol to display (e.g. '৳', '$').
  final String currencySymbol;

  final VoidCallback? onTap;
  final bool showDivider;

  /// When true, subtitle shows "Category · Note" (for Transactions tab).
  /// When false (default), subtitle shows "Category · Date" (for Home).
  final bool showNote;

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExt>()!;
    final tt = Theme.of(context).textTheme;
    final dateFmt = DateFormat('d MMM');

    final cat = category;
    final amountColor =
        transaction.isIncome ? ext.income : ext.expense;
    final amountPrefix = transaction.isIncome ? '+' : '−';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: kSp16,
              vertical: kSp12,
            ),
            child: Row(
              children: [
                // ── Category badge ────────────────────────────────────────
                Container(
                  width: kBadgeSize,
                  height: kBadgeSize,
                  decoration: BoxDecoration(
                    color: cat != null
                        ? cat.color.withAlpha(30)
                        : ext.tint,
                    borderRadius: BorderRadius.circular(kRadiusBadge),
                  ),
                  child: cat != null
                      ? Icon(cat.icon,
                          size: kBadgeIconSize, color: cat.color)
                      : Icon(Icons.category_rounded,
                          size: kBadgeIconSize,
                          color: ext.textSecondary),
                ),

                const SizedBox(width: kSp12),

                // ── Title + category name ─────────────────────────────────
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.title,
                        style: tt.titleSmall
                            ?.copyWith(color: ext.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        showNote
                            ? '${cat?.name ?? transaction.categoryId}'
                              '${transaction.note?.isNotEmpty == true ? ' · ${transaction.note}' : ''}'
                            : '${cat?.name ?? transaction.categoryId}'
                              ' · ${dateFmt.format(transaction.date)}',
                        style: tt.bodySmall
                            ?.copyWith(color: ext.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: kSp8),

                // ── Amount ───────────────────────────────────────────────
                Text(
                  '$amountPrefix$currencySymbol${_fmtAmt(transaction.amount)}',
                  style: tt.titleSmall?.copyWith(
                    color: amountColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            color: ext.divider,
            indent: kSp16 + kBadgeSize + kSp12,
            endIndent: kSp16,
          ),
      ],
    );
  }
}
