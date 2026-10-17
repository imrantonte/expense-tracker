import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme_ext.dart';
import '../../core/constants.dart';
import '../../data/app_state.dart';
import '../../models/transaction_item.dart';
import '../../screens/add_transaction/add_transaction_screen.dart';
import '../../screens/transaction_detail/transaction_detail_screen.dart';
import '../../widgets/app_card.dart';
import '../../widgets/filter_sheet.dart';
import '../../widgets/transaction_tile.dart';
import '../../widgets/wallet_logo_badge.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TransactionsScreen
// ─────────────────────────────────────────────────────────────────────────────

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _searchCtrl = TextEditingController();
  String _typeFilter = 'all'; // 'all' | 'expense' | 'income'
  TxFilterState _filter = const TxFilterState();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Date-range label shown in pill ─────────────────────────────────────────

  String _dateRangeLabel(AppState state) {
    final now = DateTime.now();
    switch (_filter.dateRangeType) {
      case 'today':
        return 'Today, ${DateFormat('d MMM yyyy').format(now)}';
      case 'week':
        final start = now.subtract(const Duration(days: 6));
        return '${start.day}–${now.day} ${DateFormat('MMM yyyy').format(now)}';
      case 'month':
        final yr = state.selectedYear;
        final mo = state.selectedMonth;
        final firstDay = 1;
        final isCurrentMonth =
            mo == now.month && yr == now.year;
        final lastDay = isCurrentMonth
            ? now.day
            : DateTime(yr, mo + 1, 0).day;
        final label =
            DateFormat('MMM yyyy').format(DateTime(yr, mo));
        return '$firstDay–$lastDay $label';
      default:
        return 'Custom range';
    }
  }

  // ── Filtering logic ────────────────────────────────────────────────────────

  List<TransactionItem> _filtered(AppState state) {
    var list = state.transactions; // already scoped to selected month

    // Type chip
    if (_typeFilter == 'expense') {
      list = list.where((t) => !t.isIncome).toList();
    } else if (_typeFilter == 'income') {
      list = list.where((t) => t.isIncome).toList();
    }

    // Category filter from filter sheet
    if (_filter.selectedCategoryIds.isNotEmpty) {
      list = list
          .where((t) => _filter.selectedCategoryIds.contains(t.categoryId))
          .toList();
    }

    // Date-range filter
    final now = DateTime.now();
    DateTime? from;
    switch (_filter.dateRangeType) {
      case 'today':
        from = DateTime(now.year, now.month, now.day);
        list = list.where((t) {
          final d = t.date;
          return d.year == from!.year &&
              d.month == from.month &&
              d.day == from.day;
        }).toList();
        break;
      case 'week':
        from = now.subtract(const Duration(days: 6));
        list = list.where((t) => t.date.isAfter(from!)).toList();
        break;
      default:
        break; // 'month' already handled by AppState
    }

    // Search
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where((t) =>
              t.title.toLowerCase().contains(q) ||
              (t.note?.toLowerCase().contains(q) ?? false))
          .toList();
    }

    // Sort
    if (_filter.sortOrder == 'highest') {
      list = List.from(list)..sort((a, b) => b.amount.compareTo(a.amount));
    }

    return list;
  }

  // ── Group by calendar date ────────────────────────────────────────────────

  Map<DateTime, List<TransactionItem>> _groupByDate(
      List<TransactionItem> list) {
    final map = <DateTime, List<TransactionItem>>{};
    for (final tx in list) {
      final key =
          DateTime(tx.date.year, tx.date.month, tx.date.day);
      map.putIfAbsent(key, () => []).add(tx);
    }
    return map;
  }

  // ── Summaries for type chips ───────────────────────────────────────────────

  double _total(List<TransactionItem> list) =>
      list.fold(0.0, (s, t) => s + t.amount);

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _openFilter() async {
    final result = await showFilterSheet(
      context,
      initial: _filter,
    );
    if (result != null) setState(() => _filter = result);
  }

  Future<void> _openDateRange(AppState state) async {
    final now = DateTime.now();
    final firstDay = DateTime(state.selectedYear, state.selectedMonth, 1);
    final lastDay = DateTime(state.selectedYear, state.selectedMonth + 1, 0);
    await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: lastDay.isAfter(now) ? now : lastDay,
      initialDateRange: DateTimeRange(start: firstDay, end: now),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx),
        child: child!,
      ),
    );
    // Date range display is managed via filter state; picker here is for UX
  }

  void _openAdd({bool isIncome = false}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(
          initialIsExpense: !isIncome,
        ),
      ),
    );
  }

  void _openDetail(TransactionItem tx) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TransactionDetailScreen(transaction: tx),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<AppState>(
          builder: (context, state, _) {
            final ext = Theme.of(context).extension<AppThemeExt>()!;
            final cs = Theme.of(context).colorScheme;
            final tt = Theme.of(context).textTheme;
            final sym = state.currencySymbol;

            final filtered = _filtered(state);
            final groups = _groupByDate(filtered);
            final sortedDates = groups.keys.toList()
              ..sort((a, b) => b.compareTo(a));

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Fixed header ───────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      kSp16, kSp16, kSp16, 0),
                  child: _TxHeader(
                    onAdd: () => _openAdd(
                        isIncome: _typeFilter == 'income'),
                  ),
                ),
                const SizedBox(height: kSp12),

                // ── Search bar ─────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: kSp16),
                  child: _SearchBar(
                    controller: _searchCtrl,
                    onChanged: (_) => setState(() {}),
                    ext: ext,
                    tt: tt,
                  ),
                ),
                const SizedBox(height: kSp12),

                // ── Type filter chips ──────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: kSp16),
                  child: _TypeFilterRow(
                    current: _typeFilter,
                    onChanged: (v) => setState(() => _typeFilter = v),
                    ext: ext, cs: cs, tt: tt,
                  ),
                ),
                const SizedBox(height: kSp12),

                // ── Date range row ─────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: kSp16),
                  child: _DateRangeRow(
                    label: _dateRangeLabel(state),
                    hasActiveFilter: _filter.isActive,
                    onDateTap: () => _openDateRange(state),
                    onFilterTap: _openFilter,
                    ext: ext, cs: cs, tt: tt,
                  ),
                ),

                // ── Summary card (Expense / Income only) ───────────────
                if (_typeFilter != 'all') ...[
                  const SizedBox(height: kSp12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: kSp16),
                    child: _SummaryCard(
                      isIncome: _typeFilter == 'income',
                      total: _total(filtered),
                      rangeLabel: _dateRangeLabel(state),
                      sym: sym,
                      ext: ext, cs: cs, tt: tt,
                    ),
                  ),
                ],
                const SizedBox(height: kSp16),

                // ── Scrollable list ────────────────────────────────────
                Expanded(
                  child: filtered.isEmpty
                      ? _EmptyState(
                          isIncome: _typeFilter == 'income',
                          onAdd: () => _openAdd(
                              isIncome: _typeFilter == 'income'),
                          ext: ext, cs: cs, tt: tt,
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(
                              kSp16, 0, kSp16, 92),
                          itemCount: sortedDates.length +
                              (_typeFilter != 'all' ? 1 : 0),
                          itemBuilder: (ctx, i) {
                            // Add-card at the end for Expense/Income tabs
                            if (_typeFilter != 'all' &&
                                i == sortedDates.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: kSp12),
                                child: _AddDashedCard(
                                  isIncome: _typeFilter == 'income',
                                  onTap: () => _openAdd(
                                      isIncome: _typeFilter == 'income'),
                                  ext: ext, cs: cs, tt: tt,
                                ),
                              );
                            }

                            final date = sortedDates[i];
                            final dayTxns = groups[date]!;

                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Date group header
                                _DateGroupHeader(
                                  date: date,
                                  ext: ext,
                                  tt: tt,
                                ),
                                const SizedBox(height: kSp8),
                                // Transactions card
                                AppCard(
                                  padding: EdgeInsets.zero,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      for (int j = 0;
                                          j < dayTxns.length;
                                          j++)
                                        TransactionTile(
                                          transaction: dayTxns[j],
                                          category: state.findCategory(
                                              dayTxns[j].categoryId),
                                          currencySymbol: sym,
                                          showNote: true,
                                          showDivider:
                                              j < dayTxns.length - 1,
                                          onTap: () =>
                                              _openDetail(dayTxns[j]),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: kSp16),
                              ],
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header row
// ─────────────────────────────────────────────────────────────────────────────

class _TxHeader extends StatelessWidget {
  const _TxHeader({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExt>()!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Row(
      children: [
        const WalletLogoBadge(size: 36),
        const SizedBox(width: kSp10),
        Expanded(
          child: Text(
            'Where Did It Go?',
            style: tt.titleMedium?.copyWith(
              color: ext.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        GestureDetector(
          onTap: onAdd,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: cs.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 22),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Search bar
// ─────────────────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.ext,
    required this.tt,
  });
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final AppThemeExt ext;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: ext.cardBackground,
        borderRadius: BorderRadius.circular(kRadiusButton),
        border: Border.all(color: ext.cardBorder),
      ),
      child: Row(
        children: [
          const SizedBox(width: kSp14),
          Icon(Icons.search_rounded, color: ext.textSecondary, size: 20),
          const SizedBox(width: kSp10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: tt.bodyMedium?.copyWith(color: ext.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search transactions',
                hintStyle:
                    tt.bodyMedium?.copyWith(color: ext.textSecondary),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(width: kSp12),
        ],
      ),
    );
  }
}

// helper constant not in constants.dart

// ─────────────────────────────────────────────────────────────────────────────
// Type filter chips  (All / Expense / Income)
// ─────────────────────────────────────────────────────────────────────────────

class _TypeFilterRow extends StatelessWidget {
  const _TypeFilterRow({
    required this.current,
    required this.onChanged,
    required this.ext,
    required this.cs,
    required this.tt,
  });
  final String current;
  final ValueChanged<String> onChanged;
  final AppThemeExt ext;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _TypeChip(label: 'All', value: 'all', current: current, onTap: () => onChanged('all'), ext: ext, cs: cs, tt: tt),
        const SizedBox(width: kSp8),
        _TypeChip(label: 'Expense', value: 'expense', current: current, onTap: () => onChanged('expense'), ext: ext, cs: cs, tt: tt),
        const SizedBox(width: kSp8),
        _TypeChip(label: 'Income', value: 'income', current: current, onTap: () => onChanged('income'), ext: ext, cs: cs, tt: tt),
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
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
            horizontal: kSp12, vertical: kSp8),
        decoration: BoxDecoration(
          color: sel ? ext.tint : ext.cardBackground,
          borderRadius: BorderRadius.circular(kRadiusButton),
          border: Border.all(
              color: sel ? cs.primary : ext.cardBorder,
              width: sel ? 1.5 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (sel) ...[
              Icon(Icons.check_rounded, size: 13, color: cs.primary),
              const SizedBox(width: kSp4),
            ],
            Text(
              label,
              style: tt.bodySmall?.copyWith(
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

// ─────────────────────────────────────────────────────────────────────────────
// Date range + filter button row
// ─────────────────────────────────────────────────────────────────────────────

class _DateRangeRow extends StatelessWidget {
  const _DateRangeRow({
    required this.label,
    required this.hasActiveFilter,
    required this.onDateTap,
    required this.onFilterTap,
    required this.ext,
    required this.cs,
    required this.tt,
  });
  final String label;
  final bool hasActiveFilter;
  final VoidCallback onDateTap;
  final VoidCallback onFilterTap;
  final AppThemeExt ext;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Date range pill
        Expanded(
          child: GestureDetector(
            onTap: onDateTap,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: kSp12, vertical: kSp10),
              decoration: BoxDecoration(
                color: ext.cardBackground,
                borderRadius: BorderRadius.circular(kSp12),
                border: Border.all(color: ext.cardBorder),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_month_outlined,
                      size: 18, color: cs.primary),
                  const SizedBox(width: kSp8),
                  Expanded(
                    child: Text(
                      label,
                      style: tt.bodyMedium
                          ?.copyWith(color: ext.textPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.keyboard_arrow_down_rounded,
                      size: 18, color: cs.primary),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: kSp8),

        // Filter button
        GestureDetector(
          onTap: onFilterTap,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: hasActiveFilter ? ext.tint : ext.cardBackground,
              borderRadius: BorderRadius.circular(kSp12),
              border: Border.all(
                  color:
                      hasActiveFilter ? cs.primary : ext.cardBorder,
                  width: hasActiveFilter ? 1.5 : 1),
            ),
            child: Icon(
              Icons.tune_rounded,
              size: 20,
              color: hasActiveFilter ? cs.primary : ext.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Summary card  (shown when Expense or Income tab is active)
// ─────────────────────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.isIncome,
    required this.total,
    required this.rangeLabel,
    required this.sym,
    required this.ext,
    required this.cs,
    required this.tt,
  });
  final bool isIncome;
  final double total;
  final String rangeLabel;
  final String sym;
  final AppThemeExt ext;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    final color = isIncome ? ext.income : ext.expense;
    final icon = isIncome
        ? Icons.arrow_upward_rounded
        : Icons.arrow_downward_rounded;
    final label = isIncome ? 'Total earned' : 'Total spent';
    final nf = NumberFormat('#,##0');

    return AppCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withAlpha(22),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: kSp12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label,
                    style: tt.bodySmall?.copyWith(color: ext.textSecondary)),
                const SizedBox(height: kSp2),
                Text(
                  '$sym${nf.format(total.toInt())}',
                  style: tt.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(rangeLabel,
                    style: tt.bodySmall?.copyWith(color: ext.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Date group header  (Today / Yesterday / 4 Oct 2026)
// ─────────────────────────────────────────────────────────────────────────────

class _DateGroupHeader extends StatelessWidget {
  const _DateGroupHeader({
    required this.date,
    required this.ext,
    required this.tt,
  });
  final DateTime date;
  final AppThemeExt ext;
  final TextTheme tt;

  static String _label(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(d).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return DateFormat('d MMM yyyy').format(d);
  }

  static String _right(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(d).inDays;
    if (diff <= 1) return DateFormat('d MMM').format(d);
    return DateFormat('EEEE').format(d); // e.g. "Sunday"
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          _label(date),
          style: tt.labelLarge?.copyWith(
            color: ext.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        Text(
          _right(date),
          style: tt.bodySmall?.copyWith(color: ext.textSecondary),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dashed "Add expense / income" card
// ─────────────────────────────────────────────────────────────────────────────

class _AddDashedCard extends StatelessWidget {
  const _AddDashedCard({
    required this.isIncome,
    required this.onTap,
    required this.ext,
    required this.cs,
    required this.tt,
  });
  final bool isIncome;
  final VoidCallback onTap;
  final AppThemeExt ext;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    final label = isIncome ? 'Add income' : 'Add expense';

    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: _DashedBorderPainter(color: cs.primary),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: kSp16),
          decoration: BoxDecoration(
            color: ext.tint.withAlpha(80),
            borderRadius: BorderRadius.circular(kRadiusCard),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: cs.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 16),
              ),
              const SizedBox(width: kSp10),
              Text(
                label,
                style: tt.bodyMedium?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dashWidth = 8.0;
    const gapWidth = 5.0;
    const radius = Radius.circular(kRadiusCard);
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, radius);
    final path = Path()..addRRect(rrect);
    final pathMetric = path.computeMetrics().first;
    var distance = 0.0;
    var draw = true;
    while (distance < pathMetric.length) {
      final seg = draw ? dashWidth : gapWidth;
      if (draw) {
        final segment = pathMetric.extractPath(distance, distance + seg);
        canvas.drawPath(segment, paint);
      }
      distance += seg;
      draw = !draw;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.isIncome,
    required this.onAdd,
    required this.ext,
    required this.cs,
    required this.tt,
  });
  final bool isIncome;
  final VoidCallback onAdd;
  final AppThemeExt ext;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    final label =
        isIncome ? 'Add your first income!' : 'Add your first expense!';
    final btnLabel = isIncome ? '+ Add income' : '+ Add expense';

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Illustration
          Stack(
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: ext.tint,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(Icons.sentiment_satisfied_alt_rounded,
                    size: 44, color: cs.primary.withAlpha(180)),
              ),
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration:
                      BoxDecoration(color: cs.primary, shape: BoxShape.circle),
                  child: const Icon(Icons.add, color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: kSp16),
          Text(
            'Nothing here yet.',
            style: tt.titleSmall?.copyWith(
              color: ext.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: kSp4),
          Text(
            label,
            style: tt.bodyMedium?.copyWith(color: ext.textSecondary),
          ),
          const SizedBox(height: kSp20),
          SizedBox(
            height: kButtonHeight,
            child: FilledButton(
              onPressed: onAdd,
              child: Text(btnLabel),
            ),
          ),
        ],
      ),
    );
  }
}
