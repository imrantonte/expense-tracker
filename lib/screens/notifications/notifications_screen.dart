import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme_ext.dart';
import '../../core/constants.dart';
import '../../data/app_state.dart';
import '../../models/app_notification.dart';
import '../../screens/notifications/notification_settings_screen.dart';
import '../../widgets/app_card.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NotificationsScreen
// ─────────────────────────────────────────────────────────────────────────────

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  // ── Date group label ────────────────────────────────────────────────────────

  static String _groupLabel(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(time.year, time.month, time.day);
    final diff = today.difference(d).inDays;
    if (diff == 0) return 'TODAY';
    if (diff == 1) return 'YESTERDAY';
    return 'EARLIER THIS MONTH';
  }

  static const _groupOrder = ['TODAY', 'YESTERDAY', 'EARLIER THIS MONTH'];

  // ── Timestamp formatting ────────────────────────────────────────────────────

  static String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(time.year, time.month, time.day);
    final diff = today.difference(d).inDays;
    final t = DateFormat('h:mm a').format(time);
    if (diff == 0) return 'Today · $t';
    if (diff == 1) return 'Yesterday · $t';
    return '${DateFormat('MMM d').format(time)} · $t';
  }

  // ── Icon per type ───────────────────────────────────────────────────────────

  static Widget _icon(NotificationType type, AppThemeExt ext, ColorScheme cs) {
    late Color bg;
    late Color fg;
    late IconData icon;
    switch (type) {
      case NotificationType.budgetOver:
        bg = ext.expense.withAlpha(22);
        fg = ext.expense;
        icon = Icons.error_outline_rounded;
        break;
      case NotificationType.budgetWarning:
        bg = ext.warning.withAlpha(32);
        fg = ext.warning;
        icon = Icons.warning_amber_rounded;
        break;
      default:
        bg = ext.tint;
        fg = cs.primary;
        icon = Icons.account_balance_wallet_outlined;
    }
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: fg, size: 24),
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
          'Notifications',
          style: tt.titleLarge?.copyWith(
            color: ext.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: kFontScreenTitle,
          ),
        ),
      ),
      body: Consumer<AppState>(
        builder: (ctx, state, _) {
          final notifs = state.notifications;
          final unread = state.unreadCount;

          // Group by date section
          final Map<String, List<AppNotification>> grouped = {};
          for (final n in notifs) {
            final label = _groupLabel(n.time);
            grouped.putIfAbsent(label, () => []).add(n);
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(kSp16, 0, kSp16, 24),
            children: [
              // subtitle
              Text(
                'Little nudges. No spending surprises.',
                style: tt.bodyMedium?.copyWith(color: ext.textSecondary),
              ),
              const SizedBox(height: kSp16),

              // ── Unread chip + Mark all as read ─────────────────────────
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: kSp12, vertical: kSp6),
                    decoration: BoxDecoration(
                      color: ext.tint,
                      borderRadius: BorderRadius.circular(kRadiusButton),
                    ),
                    child: Text(
                      '$unread unread',
                      style: tt.labelMedium?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: state.markAllNotificationsRead,
                    style: TextButton.styleFrom(
                      foregroundColor: cs.primary,
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text(
                      'Mark all as read',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: kSp20),

              // ── Grouped notification lists ──────────────────────────────
              for (final group in _groupOrder)
                if (grouped.containsKey(group)) ...[
                  Text(
                    group,
                    style: tt.labelSmall?.copyWith(
                      color: ext.textSecondary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: kSp8),
                  for (final notif in grouped[group]!) ...[
                    _NotifCard(
                      notif: notif,
                      timeLabel: _formatTime(notif.time),
                      iconWidget: _icon(notif.type, ext, cs),
                      onTap: () =>
                          context.read<AppState>().markNotificationRead(notif.id),
                      ext: ext,
                      cs: cs,
                      tt: tt,
                    ),
                    const SizedBox(height: kSp8),
                  ],
                  const SizedBox(height: kSp12),
                ],

              // ── Footer: budget nudges card ──────────────────────────────
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const NotificationSettingsScreen()),
                ),
                child: Container(
                  padding: const EdgeInsets.all(kSp16),
                  decoration: BoxDecoration(
                    color: ext.tint,
                    borderRadius: BorderRadius.circular(kRadiusCard),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: ext.cardBackground,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.notifications_outlined,
                            color: cs.primary, size: 22),
                      ),
                      const SizedBox(width: kSp12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Your budget, your nudges',
                              style: tt.bodyMedium?.copyWith(
                                color: cs.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: kSp2),
                            Text(
                              'Manage alerts in budget settings',
                              style: tt.bodySmall
                                  ?.copyWith(color: ext.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded,
                          color: cs.primary, size: 20),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual notification card
// ─────────────────────────────────────────────────────────────────────────────

class _NotifCard extends StatelessWidget {
  const _NotifCard({
    required this.notif,
    required this.timeLabel,
    required this.iconWidget,
    required this.onTap,
    required this.ext,
    required this.cs,
    required this.tt,
  });
  final AppNotification notif;
  final String timeLabel;
  final Widget iconWidget;
  final VoidCallback onTap;
  final AppThemeExt ext;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(kSp14),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          iconWidget,
          const SizedBox(width: kSp12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  notif.title,
                  style: tt.bodyMedium?.copyWith(
                    color: ext.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: kSp4),
                Text(
                  notif.body,
                  style: tt.bodySmall?.copyWith(color: ext.textSecondary),
                ),
                const SizedBox(height: kSp8),
                Text(
                  timeLabel,
                  style: tt.bodySmall?.copyWith(
                    color: ext.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (notif.unread) ...[
            const SizedBox(width: kSp8),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Container(
                width: 8,
                height: 8,
                decoration:
                    BoxDecoration(color: cs.primary, shape: BoxShape.circle),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

