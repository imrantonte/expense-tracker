import 'package:flutter/material.dart';

import '../core/app_theme_ext.dart';
import '../core/constants.dart';
import '../data/app_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Public entry-point
// ─────────────────────────────────────────────────────────────────────────────

/// Shows the month-and-year picker as a modal bottom sheet.
///
/// Returns the selected `(month, year)` record when the user presses **Apply**
/// or **This month**, or `null` if they cancel.
///
/// Caller is responsible for calling [AppState.setSelectedMonth] with the result.
Future<({int month, int year})?> showMonthPickerSheet(
  BuildContext context, {
  required int initialMonth,
  required int initialYear,
}) {
  return showModalBottomSheet<({int month, int year})>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius:
          BorderRadius.vertical(top: Radius.circular(kRadiusSheet)),
    ),
    builder: (_) => _MonthPickerSheet(
      initialMonth: initialMonth,
      initialYear: initialYear,
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Sheet widget (stateful)
// ─────────────────────────────────────────────────────────────────────────────

class _MonthPickerSheet extends StatefulWidget {
  const _MonthPickerSheet({
    required this.initialMonth,
    required this.initialYear,
  });
  final int initialMonth;
  final int initialYear;

  @override
  State<_MonthPickerSheet> createState() => _MonthPickerSheetState();
}

class _MonthPickerSheetState extends State<_MonthPickerSheet> {
  late int _year;
  late int _month;

  static const _years = [2023, 2024, 2025, 2026, 2027];
  static const _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr',
    'May', 'Jun', 'Jul', 'Aug',
    'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  void initState() {
    super.initState();
    _year = widget.initialYear;
    _month = widget.initialMonth;
  }

  // ── Enabled logic ──────────────────────────────────────────────────────────

  bool _yearEnabled(int y) => y <= DateTime.now().year;

  bool _monthEnabled(int m) {
    final now = DateTime.now();
    if (_year < now.year) return true;
    if (_year == now.year) return m <= now.month;
    return false;
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  void _selectYear(int y) {
    setState(() {
      _year = y;
      if (!_monthEnabled(_month)) _month = DateTime.now().month;
    });
  }

  void _apply() => Navigator.pop(context, (month: _month, year: _year));

  void _thisMonth() {
    final now = DateTime.now();
    Navigator.pop(context, (month: now.month, year: now.year));
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExt>()!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(kSp24, kSp12, kSp24, kSp24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Drag handle ────────────────────────────────────────────────
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ext.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: kSp20),

          // ── Title ──────────────────────────────────────────────────────
          Text(
            'Select month',
            style: tt.titleLarge?.copyWith(
              color: ext.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: kSp20),

          // ── Year label ─────────────────────────────────────────────────
          Text('Year',
              style: tt.labelMedium?.copyWith(color: ext.textSecondary)),
          const SizedBox(height: kSp8),

          // ── Year chips row ─────────────────────────────────────────────
          Row(
            children: _years.map((y) {
              final sel = y == _year;
              final ena = _yearEnabled(y);
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                      right: y != _years.last ? kSp6 : 0),
                  child: _PickerChip(
                    label: y.toString(),
                    isSelected: sel,
                    isEnabled: ena,
                    onTap: ena ? () => _selectYear(y) : null,
                    ext: ext,
                    cs: cs,
                    tt: tt,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: kSp16),

          // ── Month label ────────────────────────────────────────────────
          Text('Month',
              style: tt.labelMedium?.copyWith(color: ext.textSecondary)),
          const SizedBox(height: kSp8),

          // ── Month grid (3 × 4) ─────────────────────────────────────────
          GridView.count(
            crossAxisCount: 3,
            crossAxisSpacing: kSp8,
            mainAxisSpacing: kSp8,
            childAspectRatio: 2.8,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: _monthNames.asMap().entries.map((e) {
              final idx = e.key + 1;
              final sel = idx == _month;
              final ena = _monthEnabled(idx);
              return _PickerChip(
                label: e.value,
                isSelected: sel,
                isEnabled: ena,
                onTap: ena ? () => setState(() => _month = idx) : null,
                ext: ext,
                cs: cs,
                tt: tt,
              );
            }).toList(),
          ),
          const SizedBox(height: kSp24),

          // ── Bottom action row ──────────────────────────────────────────
          Row(
            children: [
              TextButton(
                onPressed: _thisMonth,
                style: TextButton.styleFrom(
                  foregroundColor: cs.primary,
                  padding: EdgeInsets.zero,
                ),
                child: const Text('This month'),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                style: TextButton.styleFrom(
                  foregroundColor: ext.textSecondary,
                ),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: kSp8),
              SizedBox(
                height: 44,
                child: FilledButton(
                  onPressed: _apply,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: kSp8),
                    child: Text('Apply'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared chip widget used for both years and months
// ─────────────────────────────────────────────────────────────────────────────

class _PickerChip extends StatelessWidget {
  const _PickerChip({
    required this.label,
    required this.isSelected,
    required this.isEnabled,
    required this.onTap,
    required this.ext,
    required this.cs,
    required this.tt,
  });

  final String label;
  final bool isSelected;
  final bool isEnabled;
  final VoidCallback? onTap;
  final AppThemeExt ext;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    final bg = isSelected
        ? cs.primary
        : isEnabled
            ? ext.cardBackground
            : ext.divider.withAlpha(70);
    final fg = isSelected
        ? Colors.white
        : isEnabled
            ? ext.textPrimary
            : ext.textSecondary.withAlpha(100);
    final border = isSelected
        ? cs.primary
        : isEnabled
            ? ext.cardBorder
            : Colors.transparent;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(kRadiusButton),
          border: Border.all(color: border),
        ),
        child: Text(
          label,
          style: tt.bodyMedium?.copyWith(
            color: fg,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
