import 'package:flutter/material.dart';

import '../core/app_theme_ext.dart';
import '../core/constants.dart';
import '../models/expense.dart';

/// Legacy expense card tile — uses the old [Expense] model.
///
/// Prefer [TransactionTile] for new code.
class ExpenseTile extends StatelessWidget {
  const ExpenseTile({
    super.key,
    required this.expense,
    this.onTap,
  });

  final Expense expense;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExt>()!;
    final tt = Theme.of(context).textTheme;
    final cat = expense.category;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: kSp16, vertical: kSp4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(kRadiusCard),
        child: Padding(
          padding: const EdgeInsets.all(kSp16),
          child: Row(
            children: [
              // Category icon badge using the new Category.icon + Category.color
              Container(
                width: kBadgeSize,
                height: kBadgeSize,
                decoration: BoxDecoration(
                  color: cat.color.withAlpha(30),
                  borderRadius: BorderRadius.circular(kRadiusBadge),
                ),
                child: Icon(cat.icon, size: kBadgeIconSize, color: cat.color),
              ),
              const SizedBox(width: kSp16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.title,
                      style: tt.titleSmall?.copyWith(color: ext.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      cat.name,
                      style:
                          tt.bodySmall?.copyWith(color: ext.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: kSp8),
              Text(
                '−৳${expense.amount.toStringAsFixed(2)}',
                style: tt.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: ext.expense,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
