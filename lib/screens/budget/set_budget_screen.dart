import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme_ext.dart';
import '../../core/constants.dart';
import '../../data/app_state.dart';
import '../../models/budget.dart';
import '../../widgets/app_card.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SetBudgetScreen
// ─────────────────────────────────────────────────────────────────────────────

class SetBudgetScreen extends StatefulWidget {
  const SetBudgetScreen({super.key});

  @override
  State<SetBudgetScreen> createState() => _SetBudgetScreenState();
}

class _SetBudgetScreenState extends State<SetBudgetScreen> {
  late final TextEditingController _amountCtrl;
  late double _threshold; // 0.0 – 1.0
  late bool _notifyClose;

  final _nf = NumberFormat('#,##0');
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    _amountCtrl = TextEditingController(
        text: state.budget.limit.toInt().toString());
    _threshold = state.budget.alertThreshold;
    _notifyClose = true;
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ── Computed values ─────────────────────────────────────────────────────────

  double get _budgetAmount =>
      double.tryParse(_amountCtrl.text.replaceAll(',', '')) ??
      context.read<AppState>().budget.limit;

  double get _spent => context.read<AppState>().budgetSpent;

  double get _remaining => (_budgetAmount - _spent).clamp(0, double.infinity);

  double get _progress =>
      _budgetAmount > 0 ? (_spent / _budgetAmount).clamp(0, 1) : 0;

  double get _alertAmount => _budgetAmount * _threshold;

  bool get _onTrack => _spent <= _budgetAmount;

  // ── Actions ─────────────────────────────────────────────────────────────────

  void _save() {
    final amount = _budgetAmount;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid budget amount.')),
      );
      return;
    }
    context.read<AppState>().setBudget(Budget(
          limit: amount,
          alertThreshold: _threshold,
        ));
    Navigator.of(context).pop();
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExt>()!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final state = context.watch<AppState>();
    final sym = state.currencySymbol;

    // Month label
    final now = DateTime.now();
    final monthLabel =
        DateFormat('MMMM yyyy').format(DateTime(now.year, now.month));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Set monthly budget',
          style: tt.titleLarge?.copyWith(
            color: ext.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: kFontScreenTitle,
          ),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(kSp16, 0, kSp16, 24),
          children: [
            Text(
              'A little plan. A lot more peace of mind.',
              style: tt.bodyMedium?.copyWith(color: ext.textSecondary),
            ),
            const SizedBox(height: kSp20),

            // ── Card 1: Spending limit ─────────────────────────────────────
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        'Monthly spending limit',
                        style: tt.titleSmall?.copyWith(
                          color: ext.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(monthLabel,
                          style: tt.bodySmall
                              ?.copyWith(color: ext.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: kSp12),
                  // Amount input with teal border
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: kSp14, vertical: kSp10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(kRadiusCard),
                      border: Border.all(color: cs.primary, width: 1.8),
                    ),
                    child: Row(
                      children: [
                        Text(
                          sym,
                          style: tt.headlineMedium?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 28,
                          ),
                        ),
                        const SizedBox(width: kSp8),
                        Expanded(
                          child: TextField(
                            controller: _amountCtrl,
                            focusNode: _focusNode,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (_) => setState(() {}),
                            style: tt.headlineMedium?.copyWith(
                              color: ext.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 40,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: kSp10),
                  Text(
                    'Your budget starts fresh each month.',
                    style:
                        tt.bodySmall?.copyWith(color: ext.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: kSp12),

            // ── Card 2: Alert threshold ────────────────────────────────────
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        'Alert threshold',
                        style: tt.titleSmall?.copyWith(
                          color: ext.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: kSp12, vertical: kSp4),
                        decoration: BoxDecoration(
                          color: ext.tint,
                          borderRadius:
                              BorderRadius.circular(kRadiusButton),
                          border: Border.all(color: cs.primary),
                        ),
                        child: Text(
                          '${(_threshold * 100).round()}%',
                          style: tt.labelMedium?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Slider
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: cs.primary,
                      inactiveTrackColor: ext.divider,
                      thumbColor: cs.primary,
                      overlayColor: cs.primary.withAlpha(30),
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 10),
                    ),
                    child: Slider(
                      value: _threshold,
                      min: 0,
                      max: 1,
                      divisions: 20,
                      onChanged: (v) => setState(() => _threshold = v),
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: kSp4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('0%',
                            style: tt.bodySmall
                                ?.copyWith(color: ext.textSecondary)),
                        Text('100%',
                            style: tt.bodySmall
                                ?.copyWith(color: ext.textSecondary)),
                      ],
                    ),
                  ),
                  const SizedBox(height: kSp12),
                  // Alert label
                  Row(
                    children: [
                      Icon(Icons.notifications_outlined,
                          size: 18, color: ext.warning),
                      const SizedBox(width: kSp8),
                      Expanded(
                        child: Text(
                          "We'll give you a heads-up at $sym${_nf.format(_alertAmount.toInt())}.",
                          style: tt.bodySmall
                              ?.copyWith(color: ext.textSecondary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: kSp12),
                  Divider(color: ext.divider),
                  const SizedBox(height: kSp4),
                  // Notify row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Notify me when I'm close to my limit",
                          style: tt.bodyMedium
                              ?.copyWith(color: ext.textPrimary),
                        ),
                      ),
                      const SizedBox(width: kSp12),
                      Switch(
                        value: _notifyClose,
                        onChanged: (v) =>
                            setState(() => _notifyClose = v),
                        activeThumbColor: Colors.white,
                        activeTrackColor: cs.primary,
                        inactiveThumbColor: Colors.white,
                        inactiveTrackColor: ext.divider,
                        thumbIcon: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return Icon(Icons.check_rounded,
                                size: 14, color: cs.primary);
                          }
                          return null;
                        }),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: kSp12),

            // ── Card 3: This month's progress ──────────────────────────────
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        "This month's progress",
                        style: tt.titleSmall?.copyWith(
                          color: ext.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: kSp10, vertical: kSp4),
                        decoration: BoxDecoration(
                          color: ext.tint,
                          borderRadius:
                              BorderRadius.circular(kRadiusButton),
                        ),
                        child: Text(
                          _onTrack ? 'On track' : 'Over budget',
                          style: tt.labelSmall?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: kSp12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$sym${_nf.format(_spent.toInt())}',
                              style: tt.headlineMedium?.copyWith(
                                color: ext.textPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: 28,
                              ),
                            ),
                            Text(
                              'spent of $sym${_nf.format(_budgetAmount.toInt())}',
                              style: tt.bodySmall
                                  ?.copyWith(color: ext.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${(_progress * 100).toStringAsFixed(1)}%',
                        style: tt.titleMedium?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 22,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: kSp12),
                  // Progress bar
                  _ProgressBar(
                      progress: _progress,
                      threshold: _threshold,
                      ext: ext,
                      cs: cs),
                  const SizedBox(height: kSp10),
                  Row(
                    children: [
                      Text(
                        '$sym${_nf.format(_remaining.toInt())} left to spend',
                        style: tt.bodySmall?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                            color: ext.warning, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: kSp4),
                      Text(
                        '${(_threshold * 100).round()}% alert',
                        style: tt.bodySmall
                            ?.copyWith(color: ext.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: kSp24),

            // ── Save button ────────────────────────────────────────────────
            SizedBox(
              height: kButtonHeight,
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(kRadiusButton),
                  ),
                ),
                child: const Text('Save Budget',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Progress bar with threshold marker
// ─────────────────────────────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.progress,
    required this.threshold,
    required this.ext,
    required this.cs,
  });
  final double progress;
  final double threshold;
  final AppThemeExt ext;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, constraints) {
      final w = constraints.maxWidth;
      return Stack(
        children: [
          // Track
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              width: double.infinity,
              child: Stack(children: [
                Container(color: ext.divider),
                FractionallySizedBox(
                  widthFactor: progress,
                  alignment: Alignment.centerLeft,
                  child: Container(
                      color: progress > threshold ? ext.expense : cs.primary),
                ),
              ]),
            ),
          ),
          // Threshold tick
          Positioned(
            left: w * threshold - 2,
            top: 0,
            bottom: 0,
            child: Container(
              width: 3,
              decoration: BoxDecoration(
                color: ext.warning,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      );
    });
  }
}

// Local spacing constant used for padding
