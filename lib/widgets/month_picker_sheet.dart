import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/app_theme_ext.dart';
import '../core/constants.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Allowed-range helper (pure, easy to unit-test)
// ─────────────────────────────────────────────────────────────────────────────

/// Returns `true` when [month] in [year] is within the selectable range:
///   • no earlier than [joinYear]/[joinMonth]
///   • no later than the real current month (from [now])
bool isMonthSelectable({
  required int year,
  required int month,
  required int joinYear,
  required int joinMonth,
  required DateTime now,
}) {
  // Before join date → disabled.
  if (year < joinYear) return false;
  if (year == joinYear && month < joinMonth) return false;
  // After today's month → disabled.
  if (year > now.year) return false;
  if (year == now.year && month > now.month) return false;
  return true;
}

/// Returns `true` when [year] has at least one selectable month.
bool isYearSelectable({
  required int year,
  required int joinYear,
  required int joinMonth,
  required DateTime now,
}) {
  for (int m = 1; m <= 12; m++) {
    if (isMonthSelectable(
      year: year,
      month: m,
      joinYear: joinYear,
      joinMonth: joinMonth,
      now: now,
    )) { return true; }
  }
  return false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Public entry-point
// ─────────────────────────────────────────────────────────────────────────────

/// Shows the month-and-year picker as a modal bottom sheet.
///
/// Returns the selected `(month, year)` record when the user presses **Apply**
/// or **This month**, or `null` if they cancel.
///
/// Pass [joinedDate] so the sheet can disable months before the account was
/// created. When omitted it falls back to [FirebaseAuth] metadata, then today.
Future<({int month, int year})?> showMonthPickerSheet(
  BuildContext context, {
  required int initialMonth,
  required int initialYear,
  DateTime? joinedDate,
}) {
  // Resolve join date: caller → Firestore profile → FirebaseAuth metadata → now
  final DateTime resolvedJoin = joinedDate ??
      _joinFromAuth() ??
      DateTime.now();

  // Extract theme data values RIGHT NOW from the caller's context — before
  // showModalBottomSheet creates a new route context that has no AppThemeExt.
  final theme = Theme.of(context);
  final ext = theme.extension<AppThemeExt>() ?? AppThemeExt.dark;
  final cs = theme.colorScheme;
  final tt = theme.textTheme;

  return showModalBottomSheet<({int month, int year})>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: ext.cardBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(kRadiusSheet)),
    ),
    builder: (_) => _MonthPickerSheet(
      initialMonth: initialMonth,
      initialYear: initialYear,
      joinedDate: resolvedJoin,
      ext: ext,
      cs: cs,
      tt: tt,
    ),
  );
}

DateTime? _joinFromAuth() {
  final meta = FirebaseAuth.instance.currentUser?.metadata;
  return meta?.creationTime;
}

// ─────────────────────────────────────────────────────────────────────────────
// Sheet widget (stateful)
// ─────────────────────────────────────────────────────────────────────────────

class _MonthPickerSheet extends StatefulWidget {
  const _MonthPickerSheet({
    required this.initialMonth,
    required this.initialYear,
    required this.joinedDate,
    required this.ext,
    required this.cs,
    required this.tt,
  });
  final int initialMonth;
  final int initialYear;
  final DateTime joinedDate;
  final AppThemeExt ext;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  State<_MonthPickerSheet> createState() => _MonthPickerSheetState();
}

class _MonthPickerSheetState extends State<_MonthPickerSheet> {
  late int _year;
  late int _month;

  late final DateTime _now;
  late final int _joinYear;
  late final int _joinMonth;

  static const _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr',
    'May', 'Jun', 'Jul', 'Aug',
    'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  void initState() {
    super.initState();
    _year  = widget.initialYear;
    _month = widget.initialMonth;
    _now       = DateTime.now();
    _joinYear  = widget.joinedDate.year;
    _joinMonth = widget.joinedDate.month;
  }

  // ── Derived year list: (current−3) to (current+1) ─────────────────────────

  List<int> get _years {
    final base = _now.year;
    return [base - 3, base - 2, base - 1, base, base + 1];
  }

  // ── Enabled helpers (delegates to pure top-level functions) ───────────────

  bool _yearEnabled(int y) => isYearSelectable(
        year: y,
        joinYear: _joinYear,
        joinMonth: _joinMonth,
        now: _now,
      );

  bool _monthEnabled(int m) => isMonthSelectable(
        year: _year,
        month: m,
        joinYear: _joinYear,
        joinMonth: _joinMonth,
        now: _now,
      );

  // ── Actions ────────────────────────────────────────────────────────────────

  void _selectYear(int y) {
    setState(() {
      _year = y;
      // If the current selected month is not valid in the new year, snap to
      // the nearest allowed month: clamp to [joinMonth..currentMonth] within y.
      if (!_monthEnabled(_month)) {
        // Try to stay on the same month if possible.
        int candidate = _month;
        // Walk backward until we find one that's valid.
        while (candidate > 1 &&
            !isMonthSelectable(
              year: y,
              month: candidate,
              joinYear: _joinYear,
              joinMonth: _joinMonth,
              now: _now,
            )) {
          candidate--;
        }
        _month = candidate;
      }
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
    // Theme values were extracted from the caller's context before the sheet
    // route was pushed, so they are always valid here.
    final ext = widget.ext;
    final cs  = widget.cs;
    final tt  = widget.tt;

    return Container(
      decoration: BoxDecoration(
        color: ext.cardBackground,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(kRadiusSheet)),
      ),
      // Clip children so nothing bleeds outside the rounded corners.
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(kSp24, kSp12, kSp24, kSp24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Drag handle ──────────────────────────────────────────────
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ext.textSecondary.withAlpha(80),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: kSp20),

              // ── Title ────────────────────────────────────────────────────
              Text(
                'Select month',
                style: tt.titleLarge?.copyWith(
                  color: ext.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: kSp20),

              // ── Year label ───────────────────────────────────────────────
              Text('Year',
                  style:
                      tt.labelMedium?.copyWith(color: ext.textSecondary)),
              const SizedBox(height: kSp8),

              // ── Year chips row ───────────────────────────────────────────
              Row(
                children: _years.map((y) {
                  final sel = y == _year;
                  final ena = _yearEnabled(y);
                  final isLast = y == _years.last;
                  return Expanded(
                    child: Padding(
                      padding:
                          EdgeInsets.only(right: isLast ? 0 : kSp6),
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

              // ── Month label ──────────────────────────────────────────────
              Text('Month',
                  style:
                      tt.labelMedium?.copyWith(color: ext.textSecondary)),
              const SizedBox(height: kSp8),

              // ── Month grid (3 × 4) ───────────────────────────────────────
              GridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: kSp8,
                mainAxisSpacing: kSp8,
                childAspectRatio: 2.8,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: _monthNames.asMap().entries.map((e) {
                  final idx = e.key + 1; // 1-based month number
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

              // ── Bottom action row ────────────────────────────────────────
              Row(
                children: [
                  TextButton(
                    onPressed: _thisMonth,
                    style: TextButton.styleFrom(
                      foregroundColor: cs.primary,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 44),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('This month'),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context, null),
                    style: TextButton.styleFrom(
                      foregroundColor: ext.textSecondary,
                      minimumSize: const Size(0, 44),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: kSp8),
                  SizedBox(
                    height: 44,
                    child: FilledButton(
                      onPressed: _apply,
                      style: FilledButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 44),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(kRadiusButton),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: kSp20),
                      ),
                      child: const Text(
                        'Apply',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared chip widget (year pills + month grid buttons)
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
    final Color bg = isSelected
        ? cs.primary
        : isEnabled
            ? Colors.transparent
            : ext.divider.withAlpha(70);
    final Color fg = isSelected
        ? Colors.white
        : isEnabled
            ? ext.textPrimary
            : ext.textSecondary.withAlpha(100);
    final Color borderColor = isSelected
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
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Text(
          label,
          style: tt.bodyMedium?.copyWith(
            color: fg,
            fontWeight:
                isSelected ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
