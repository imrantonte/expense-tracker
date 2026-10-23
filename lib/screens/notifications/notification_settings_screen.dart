import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme_ext.dart';
import '../../core/constants.dart';
import '../../data/app_state.dart';
import '../../services/reminder_service.dart';
import '../../widgets/app_card.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NotificationSettingsScreen
// ─────────────────────────────────────────────────────────────────────────────

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  static const _remindOptions = [
    ('2h', '2 hours'),
    ('3h', '3 hours'),
    ('4h', '4 hours'),
    ('1d', 'Once a day'),
    ('custom', 'Custom'),
  ];

  // ── Permission-aware toggle ─────────────────────────────────────────────────

  Future<void> _toggleExpenseReminders(
      AppState state, bool newValue) async {
    if (newValue) {
      // On Android 13+ we must request POST_NOTIFICATIONS before scheduling.
      final granted =
          await ReminderService.instance.requestPermission();
      if (!mounted) return;
      if (!granted) {
        // Show a brief explanation and leave the toggle OFF.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Notification permission denied. Enable it in Settings.'),
          ),
        );
        return;
      }
    }
    state.setExpenseReminders(newValue);
  }

  // ── 12-hour time formatter ──────────────────────────────────────────────────

  static String _fmt12h(int hour, int min) {
    final period = hour < 12 ? 'AM' : 'PM';
    final h = hour % 12 == 0 ? 12 : hour % 12;
    final m = min.toString().padLeft(2, '0');
    return '$h:$m $period';
  }

  // ── Shared styled switch ────────────────────────────────────────────────────

  static Widget _switch(bool value, ValueChanged<bool> onChanged,
      ColorScheme cs, AppThemeExt ext) {
    return Switch(
      value: value,
      onChanged: onChanged,
      activeThumbColor: Colors.white,
      activeTrackColor: cs.primary,
      inactiveThumbColor: Colors.white,
      inactiveTrackColor: ext.divider,
      thumbIcon: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Icon(Icons.check_rounded, size: 14, color: cs.primary);
        }
        return null;
      }),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────

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
          'Notification settings',
          style: tt.titleLarge?.copyWith(
            color: ext.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: kFontScreenTitle,
          ),
        ),
      ),
      body: Consumer<AppState>(
        builder: (ctx, state, _) {
          return ListView(
            padding:
                const EdgeInsets.fromLTRB(kSp16, kSp8, kSp16, kSp24),
            children: [
              // ── Card: Expense reminders ──────────────────────────────────
              AppCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Expense reminders',
                            style: tt.titleSmall?.copyWith(
                              color: ext.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: kSp4),
                          Text(
                            'Get a nudge to log what you spent.',
                            style: tt.bodySmall
                                ?.copyWith(color: ext.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    _switch(
                        state.expenseReminders,
                        (v) => _toggleExpenseReminders(state, v),
                        cs,
                        ext),
                  ],
                ),
              ),
              const SizedBox(height: kSp12),

              // ── Card: Remind me every ────────────────────────────────────
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Remind me every',
                      style: tt.titleSmall?.copyWith(
                        color: ext.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: kSp12),
                    Wrap(
                      spacing: kSp8,
                      runSpacing: kSp8,
                      children: _remindOptions.map((opt) {
                        final sel = state.remindEvery == opt.$1;
                        return GestureDetector(
                          onTap: () =>
                              state.setRemindEvery(opt.$1),
                          child: AnimatedContainer(
                            duration:
                                const Duration(milliseconds: 160),
                            padding: const EdgeInsets.symmetric(
                                horizontal: kSp12,
                                vertical: kSp8),
                            decoration: BoxDecoration(
                              color: sel ? ext.tint : ext.cardBackground,
                              borderRadius: BorderRadius.circular(kSp12),
                              border: Border.all(
                                  color:
                                      sel ? cs.primary : ext.cardBorder,
                                  width: sel ? 1.5 : 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (sel) ...[
                                  Icon(Icons.check_rounded,
                                      size: 14, color: cs.primary),
                                  const SizedBox(width: kSp4),
                                ],
                                Text(
                                  opt.$2,
                                  style: tt.bodySmall?.copyWith(
                                    color: sel
                                        ? cs.primary
                                        : ext.textPrimary,
                                    fontWeight: sel
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: kSp12),

              // ── Card: Quiet hours ────────────────────────────────────────
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Quiet hours',
                      style: tt.titleSmall?.copyWith(
                        color: ext.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: kSp12),
                    Row(
                      children: [
                        Expanded(
                          child: _TimeField(
                            prefix: 'From',
                            timeLabel: _fmt12h(
                                state.quietFromHour, state.quietFromMin),
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay(
                                    hour: state.quietFromHour,
                                    minute: state.quietFromMin),
                              );
                              if (picked != null && context.mounted) {
                                context.read<AppState>().setQuietFrom(
                                    picked.hour, picked.minute);
                              }
                            },
                            ext: ext,
                            tt: tt,
                          ),
                        ),
                        const SizedBox(width: kSp8),
                        Expanded(
                          child: _TimeField(
                            prefix: 'To',
                            timeLabel: _fmt12h(
                                state.quietToHour, state.quietToMin),
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay(
                                    hour: state.quietToHour,
                                    minute: state.quietToMin),
                              );
                              if (picked != null && context.mounted) {
                                context.read<AppState>().setQuietTo(
                                    picked.hour, picked.minute);
                              }
                            },
                            ext: ext,
                            tt: tt,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: kSp10),
                    Text(
                      'No reminders during quiet hours.',
                      style: tt.bodySmall
                          ?.copyWith(color: ext.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: kSp12),

              // ── Card: Skip if already logged ─────────────────────────────
              AppCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Skip if I already logged something',
                            style: tt.titleSmall?.copyWith(
                              color: ext.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: kSp4),
                          Text(
                            'Only remind me when nothing was added in that time.',
                            style: tt.bodySmall
                                ?.copyWith(color: ext.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    _switch(state.skipIfLogged,
                        state.setSkipIfLogged, cs, ext),
                  ],
                ),
              ),
              const SizedBox(height: kSp12),

              // ── Card: Budget alerts ──────────────────────────────────────
              AppCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Budget alerts',
                            style: tt.titleSmall?.copyWith(
                              color: ext.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: kSp4),
                          Text(
                            'Warn me at 80% and when I go over budget.',
                            style: tt.bodySmall
                                ?.copyWith(color: ext.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    _switch(state.budgetAlerts,
                        state.setBudgetAlerts, cs, ext),
                  ],
                ),
              ),
              const SizedBox(height: kSp12),

              // ── Preview card ─────────────────────────────────────────────
              AppCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // App icon preview
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: cs.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          color: Colors.white,
                          size: 22),
                    ),
                    const SizedBox(width: kSp12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Where Did It Go?',
                                style: tt.bodyMedium?.copyWith(
                                  color: ext.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'Preview',
                                style: tt.bodySmall?.copyWith(
                                    color: ext.textSecondary),
                              ),
                            ],
                          ),
                          const SizedBox(height: kSp4),
                          Text(
                            _previewBody(state),
                            style: tt.bodySmall
                                ?.copyWith(color: ext.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: kSp20),

              // ── Auto-save caption ────────────────────────────────────────
              Center(
                child: Text(
                  'Changes are saved automatically',
                  style: tt.bodySmall?.copyWith(color: ext.textSecondary),
                ),
              ),
              const SizedBox(height: kSp8),
            ],
          );
        },
      ),
    );
  }

  static String _previewBody(AppState state) {
    final interval = switch (state.remindEvery) {
      '2h' => 'last 2 hours',
      '3h' => 'last 3 hours',
      '4h' => 'last 4 hours',
      '1d' => 'today',
      _ => 'a while',
    };
    return 'Spent anything in the $interval? Log it in 10 seconds.';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Time field widget
// ─────────────────────────────────────────────────────────────────────────────

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.prefix,
    required this.timeLabel,
    required this.onTap,
    required this.ext,
    required this.tt,
  });
  final String prefix;
  final String timeLabel;
  final VoidCallback onTap;
  final AppThemeExt ext;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: kSp12, vertical: kSp10),
        decoration: BoxDecoration(
          color: ext.cardBackground,
          borderRadius: BorderRadius.circular(kSp12),
          border: Border.all(color: ext.cardBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$prefix ',
              style: tt.bodySmall?.copyWith(color: ext.textSecondary),
            ),
            Text(
              timeLabel,
              style: tt.bodySmall?.copyWith(
                color: ext.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
