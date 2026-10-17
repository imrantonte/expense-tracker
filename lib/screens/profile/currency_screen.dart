import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme_ext.dart';
import '../../core/constants.dart';
import '../../data/app_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Currency data
// ─────────────────────────────────────────────────────────────────────────────

class _Currency {
  const _Currency(
      {required this.code, required this.name, required this.symbol});
  final String code;
  final String name;
  final String symbol;
}

const _currencies = [
  _Currency(code: 'BDT', name: 'Bangladeshi Taka', symbol: '৳'),
  _Currency(code: 'USD', name: 'US Dollar', symbol: '\$'),
  _Currency(code: 'EUR', name: 'Euro', symbol: '€'),
  _Currency(code: 'GBP', name: 'British Pound', symbol: '£'),
  _Currency(code: 'INR', name: 'Indian Rupee', symbol: '₹'),
];

// ─────────────────────────────────────────────────────────────────────────────
// CurrencyScreen
// ─────────────────────────────────────────────────────────────────────────────

class CurrencyScreen extends StatefulWidget {
  const CurrencyScreen({super.key});

  @override
  State<CurrencyScreen> createState() => _CurrencyScreenState();
}

class _CurrencyScreenState extends State<CurrencyScreen> {
  String _query = '';

  List<_Currency> get _filtered => _query.isEmpty
      ? _currencies
      : _currencies
          .where((c) =>
              c.name.toLowerCase().contains(_query) ||
              c.code.toLowerCase().contains(_query) ||
              c.symbol.contains(_query))
          .toList();

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExt>()!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

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
          'Currency',
          style: tt.titleLarge?.copyWith(
            color: ext.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: kFontScreenTitle,
          ),
        ),
      ),
      body: Consumer<AppState>(
        builder: (ctx, state, _) {
          final selected = state.profile.currencyCode;
          final visible = _filtered;

          return GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            behavior: HitTestBehavior.opaque,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(kSp16, 0, kSp16, 24),
              children: [
                // ── Subtitle ──────────────────────────────────────────────
                Text(
                  'Choose the symbol shown on your amounts.',
                  style: tt.bodyMedium?.copyWith(color: ext.textSecondary),
                ),
                const SizedBox(height: kSp16),

                // ── Search field ──────────────────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: ext.cardBackground,
                    borderRadius: BorderRadius.circular(kRadiusButton),
                    border: Border.all(color: ext.cardBorder),
                  ),
                  child: TextField(
                    onChanged: (v) =>
                        setState(() => _query = v.toLowerCase().trim()),
                    decoration: InputDecoration(
                      hintText: 'Search currency',
                      prefixIcon: Icon(Icons.search_rounded,
                          color: ext.textSecondary, size: 20),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: kSp16, vertical: kSp14),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(height: kSp16),

                // ── Currency list card ────────────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: ext.cardBackground,
                    borderRadius: BorderRadius.circular(kRadiusCard),
                    border: Border.all(color: ext.cardBorder),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(10),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(kRadiusCard),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (int i = 0; i < visible.length; i++) ...[
                          if (i > 0)
                            Divider(
                                height: 1,
                                thickness: 1,
                                color: ext.divider),
                          _CurrencyRow(
                            currency: visible[i],
                            isSelected:
                                visible[i].code == selected,
                            onTap: () => context
                                .read<AppState>()
                                .setCurrency(visible[i].code),
                            ext: ext,
                            cs: cs,
                            tt: tt,
                          ),
                        ],
                        if (visible.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(kSp24),
                            child: Text(
                              'No currency found.',
                              style: tt.bodyMedium
                                  ?.copyWith(color: ext.textSecondary),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: kSp24),

                // ── Auto-save caption ─────────────────────────────────────
                Center(
                  child: Text(
                    'Changes are saved automatically',
                    style:
                        tt.bodySmall?.copyWith(color: ext.textSecondary),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Currency row
// ─────────────────────────────────────────────────────────────────────────────

class _CurrencyRow extends StatelessWidget {
  const _CurrencyRow({
    required this.currency,
    required this.isSelected,
    required this.onTap,
    required this.ext,
    required this.cs,
    required this.tt,
  });
  final _Currency currency;
  final bool isSelected;
  final VoidCallback onTap;
  final AppThemeExt ext;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? ext.tint : ext.cardBackground,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: kSp16, vertical: kSp14),
          child: Row(
            children: [
              // Symbol badge
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isSelected ? cs.primary.withAlpha(30) : ext.tint,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    currency.symbol,
                    style: TextStyle(
                      color: cs.primary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: kSp12),

              // Name + code
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      currency.name,
                      style: tt.bodyMedium?.copyWith(
                        color: ext.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      currency.code,
                      style: tt.bodySmall
                          ?.copyWith(color: ext.textSecondary),
                    ),
                  ],
                ),
              ),

              // Check / empty circle
              isSelected
                  ? Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: cs.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_rounded,
                          color: Colors.white, size: 14),
                    )
                  : Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: ext.divider, width: 1.5),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

