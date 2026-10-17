import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme_ext.dart';
import '../core/constants.dart';
import '../data/app_state.dart';
import '../models/category.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Filter state (plain immutable data class, exported for callers)
// ─────────────────────────────────────────────────────────────────────────────

/// Holds all active filter values for the Transactions screen.
class TxFilterState {
  const TxFilterState({
    this.dateRangeType = 'month',
    this.selectedCategoryIds = const <String>{},
    this.sortOrder = 'newest',
  });

  /// One of: 'today', 'week', 'month', 'custom'.
  final String dateRangeType;

  /// Empty → all categories; non-empty → only matching ones shown.
  final Set<String> selectedCategoryIds;

  /// 'newest' or 'highest'.
  final String sortOrder;

  TxFilterState copyWith({
    String? dateRangeType,
    Set<String>? selectedCategoryIds,
    String? sortOrder,
  }) =>
      TxFilterState(
        dateRangeType: dateRangeType ?? this.dateRangeType,
        selectedCategoryIds: selectedCategoryIds ?? this.selectedCategoryIds,
        sortOrder: sortOrder ?? this.sortOrder,
      );

  bool get isActive =>
      dateRangeType != 'month' ||
      selectedCategoryIds.isNotEmpty ||
      sortOrder != 'newest';
}

// ─────────────────────────────────────────────────────────────────────────────
// Public entry-point
// ─────────────────────────────────────────────────────────────────────────────

/// Shows the filter bottom sheet.
///
/// Returns the new [TxFilterState] when Apply is tapped, or `null` on dismiss.
Future<TxFilterState?> showFilterSheet(
  BuildContext context, {
  required TxFilterState initial,
}) {
  return showModalBottomSheet<TxFilterState>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius:
          BorderRadius.vertical(top: Radius.circular(kRadiusSheet)),
    ),
    builder: (_) => _FilterSheet(initial: initial),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Sheet widget
// ─────────────────────────────────────────────────────────────────────────────

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.initial});
  final TxFilterState initial;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String _dateRange;
  late Set<String> _catIds;
  late String _sort;

  @override
  void initState() {
    super.initState();
    _dateRange = widget.initial.dateRangeType;
    _catIds = Set.from(widget.initial.selectedCategoryIds);
    _sort = widget.initial.sortOrder;
  }

  void _toggleCat(String id) => setState(() {
        if (_catIds.contains(id)) {
          _catIds.remove(id);
        } else {
          _catIds.add(id);
        }
      });

  void _reset() {
    Navigator.pop(context, const TxFilterState());
  }

  void _apply() {
    Navigator.pop(
      context,
      TxFilterState(
        dateRangeType: _dateRange,
        selectedCategoryIds: Set.from(_catIds),
        sortOrder: _sort,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExt>()!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final state = context.read<AppState>();
    final cats = state.allCategories;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(
              top: Radius.circular(kRadiusSheet)),
        ),
        child: ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(kSp24, kSp12, kSp24, kSp24),
          children: [
            // Drag handle
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

            // ── Header ─────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Filter transactions',
                        style: tt.titleLarge?.copyWith(
                          color: ext.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 22,
                        ),
                      ),
                      const SizedBox(height: kSp4),
                      Text(
                        'Find where your money wandered.',
                        style: tt.bodyMedium
                            ?.copyWith(color: ext.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context, null),
                  icon: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: ext.cardBorder),
                    ),
                    child: Icon(Icons.close_rounded,
                        size: 16, color: ext.textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: kSp24),

            // ── Date range ─────────────────────────────────────────────
            Text(
              'Date range',
              style: tt.titleSmall?.copyWith(
                color: ext.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: kSp12),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: kSp10,
              mainAxisSpacing: kSp10,
              childAspectRatio: 3.5,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _DateRangeChip(
                  label: 'Today',
                  value: 'today',
                  current: _dateRange,
                  onTap: () => setState(() => _dateRange = 'today'),
                  ext: ext, cs: cs, tt: tt,
                ),
                _DateRangeChip(
                  label: 'This Week',
                  value: 'week',
                  current: _dateRange,
                  onTap: () => setState(() => _dateRange = 'week'),
                  ext: ext, cs: cs, tt: tt,
                ),
                _DateRangeChip(
                  label: 'This Month',
                  value: 'month',
                  current: _dateRange,
                  onTap: () => setState(() => _dateRange = 'month'),
                  ext: ext, cs: cs, tt: tt,
                ),
                _DateRangeChip(
                  label: 'Custom',
                  value: 'custom',
                  current: _dateRange,
                  leadingIcon: Icons.calendar_month_outlined,
                  onTap: () => setState(() => _dateRange = 'custom'),
                  ext: ext, cs: cs, tt: tt,
                ),
              ],
            ),
            const SizedBox(height: kSp24),

            // ── Categories ─────────────────────────────────────────────
            Row(
              children: [
                Text(
                  'Categories',
                  style: tt.titleSmall?.copyWith(
                    color: ext.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  'Select multiple',
                  style:
                      tt.bodySmall?.copyWith(color: ext.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: kSp12),
            Wrap(
              spacing: kSp8,
              runSpacing: kSp8,
              children: cats.map((cat) {
                final sel = _catIds.contains(cat.id);
                return _CatChip(
                  category: cat,
                  isSelected: sel,
                  onTap: () => _toggleCat(cat.id),
                  ext: ext, cs: cs, tt: tt,
                );
              }).toList(),
            ),
            const SizedBox(height: kSp24),

            // ── Sort by ────────────────────────────────────────────────
            Text(
              'Sort by',
              style: tt.titleSmall?.copyWith(
                color: ext.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: kSp12),
            Row(
              children: [
                Expanded(
                  child: _SortChip(
                    label: 'Newest',
                    value: 'newest',
                    current: _sort,
                    onTap: () => setState(() => _sort = 'newest'),
                    ext: ext, cs: cs, tt: tt,
                  ),
                ),
                const SizedBox(width: kSp10),
                Expanded(
                  child: _SortChip(
                    label: 'Highest amount',
                    value: 'highest',
                    current: _sort,
                    onTap: () => setState(() => _sort = 'highest'),
                    ext: ext, cs: cs, tt: tt,
                  ),
                ),
              ],
            ),
            const SizedBox(height: kSp32),

            // ── Action buttons ─────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: kButtonHeight,
                    child: OutlinedButton(
                      onPressed: _reset,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: ext.cardBorder),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(kRadiusButton),
                        ),
                      ),
                      child: Text('Reset',
                          style: tt.labelLarge
                              ?.copyWith(color: ext.textPrimary)),
                    ),
                  ),
                ),
                const SizedBox(width: kSp12),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: kButtonHeight,
                    child: FilledButton.icon(
                      onPressed: _apply,
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Apply'),
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

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _DateRangeChip extends StatelessWidget {
  const _DateRangeChip({
    required this.label,
    required this.value,
    required this.current,
    required this.onTap,
    required this.ext,
    required this.cs,
    required this.tt,
    this.leadingIcon,
  });
  final String label;
  final String value;
  final String current;
  final VoidCallback onTap;
  final IconData? leadingIcon;
  final AppThemeExt ext;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    final sel = value == current;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: sel ? ext.tint : ext.cardBackground,
          borderRadius: BorderRadius.circular(kSp12),
          border: Border.all(
              color: sel ? cs.primary : ext.cardBorder,
              width: sel ? 1.5 : 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (sel) ...[
              Icon(Icons.check_rounded, size: 14, color: cs.primary),
              const SizedBox(width: kSp4),
            ] else if (leadingIcon != null) ...[
              Icon(leadingIcon, size: 14, color: ext.textSecondary),
              const SizedBox(width: kSp4),
            ],
            Text(
              label,
              style: tt.bodyMedium?.copyWith(
                color: sel ? cs.primary : ext.textPrimary,
                fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CatChip extends StatelessWidget {
  const _CatChip({
    required this.category,
    required this.isSelected,
    required this.onTap,
    required this.ext,
    required this.cs,
    required this.tt,
  });
  final Category category;
  final bool isSelected;
  final VoidCallback onTap;
  final AppThemeExt ext;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(
            horizontal: kSp12, vertical: kSp8),
        decoration: BoxDecoration(
          color: isSelected ? ext.tint : ext.cardBackground,
          borderRadius: BorderRadius.circular(kRadiusButton),
          border: Border.all(
              color: isSelected ? cs.primary : ext.cardBorder,
              width: isSelected ? 1.5 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              Icon(Icons.check_rounded, size: 14, color: cs.primary),
              const SizedBox(width: kSp4),
            ],
            Text(
              category.name,
              style: tt.bodySmall?.copyWith(
                color: isSelected ? cs.primary : ext.textPrimary,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  const _SortChip({
    required this.label,
    required this.value,
    required this.current,
    required this.onTap,
    required this.ext,
    required this.cs,
    required this.tt,
  });
  final String label;
  final String value;
  final String current;
  final VoidCallback onTap;
  final AppThemeExt ext;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    final sel = value == current;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(
            horizontal: kSp12, vertical: kSp12),
        decoration: BoxDecoration(
          color: sel ? ext.tint : ext.cardBackground,
          borderRadius: BorderRadius.circular(kSp12),
          border: Border.all(
              color: sel ? cs.primary : ext.cardBorder,
              width: sel ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Icon(
              sel ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              size: 18,
              color: sel ? cs.primary : ext.textSecondary,
            ),
            const SizedBox(width: kSp8),
            Expanded(
              child: Text(
                label,
                style: tt.bodySmall?.copyWith(
                  color: sel ? cs.primary : ext.textPrimary,
                  fontWeight:
                      sel ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
