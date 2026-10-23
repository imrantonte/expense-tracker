import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme_ext.dart';
import '../../core/constants.dart';
import '../../core/theme_controller.dart';
import '../../data/app_state.dart';
import '../../repositories/user_repository.dart';
import '../../services/auth_service.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/budget/set_budget_screen.dart';
import '../../screens/notifications/notification_settings_screen.dart';
import '../../screens/profile/about_screen.dart';
import '../../screens/profile/currency_screen.dart';
import '../../screens/profile/edit_profile_screen.dart';
import '../../screens/profile/manage_categories_screen.dart';
import '../../widgets/app_card.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ProfileScreen  (4th tab)
// ─────────────────────────────────────────────────────────────────────────────

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static final _nf = NumberFormat('#,##0');

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExt>()!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Consumer2<AppState, ThemeController>(
          builder: (ctx, state, themeCtrl, _) {
            final sym = state.currencySymbol;
            final profile = state.profile;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(kSp16, kSp16, kSp16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Title ─────────────────────────────────────────────────
                  Text(
                    'Profile',
                    style: tt.titleLarge?.copyWith(
                      color: ext.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: kFontScreenTitle,
                    ),
                  ),
                  const SizedBox(height: kSp16),

                  // ── Avatar card ───────────────────────────────────────────
                  AppCard(
                    child: Row(
                      children: [
                        _Avatar(ext: ext, cs: cs),
                        const SizedBox(width: kSp16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                profile.name,
                                style: tt.titleMedium?.copyWith(
                                  color: ext.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: kSp2),
                              Text(
                                profile.email,
                                style: tt.bodySmall
                                    ?.copyWith(color: ext.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: kSp12),

                  // ── "Member since" pill ───────────────────────────
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: kSp12, vertical: kSp6),
                      decoration: BoxDecoration(
                        color: ext.tint,
                        borderRadius: BorderRadius.circular(kRadiusButton),
                      ),
                      child: Text(
                        'Member since '
                        '${DateFormat('MMM yyyy').format(profile.joinedDate)}',
                        style: tt.bodySmall?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: kSp16),

                  // ── "Your journey" stats row ───────────────────────
                  AppCard(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _JourneyStat(
                          value: '${state.totalTransactionCount}',
                          label: 'Transactions',
                          ext: ext,
                          cs: cs,
                          tt: tt,
                        ),
                        Container(width: 1, height: 40, color: ext.divider),
                        _JourneyStat(
                          value: '${state.usedCategoryCount}',
                          label: 'Categories',
                          ext: ext,
                          cs: cs,
                          tt: tt,
                        ),
                        Container(width: 1, height: 40, color: ext.divider),
                        _JourneyStat(
                          value: '${state.daysSinceJoining}',
                          label: 'Days tracked',
                          ext: ext,
                          cs: cs,
                          tt: tt,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: kSp16),

                  // ── "MAKE IT YOURS" caption ───────────────────────────────
                  Padding(
                    padding: const EdgeInsets.only(left: kSp4),
                    child: Text(
                      'MAKE IT YOURS',
                      style: tt.labelSmall?.copyWith(
                        color: ext.textSecondary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(height: kSp8),

                  // ── Card 1: Profile settings ──────────────────────────────
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _SettingsRow(
                          icon: Icons.person_outline_rounded,
                          label: 'Edit Profile',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const EditProfileScreen()),
                          ),
                          ext: ext,
                          cs: cs,
                          tt: tt,
                        ),
                        _RowDivider(ext: ext),
                        _SettingsRow(
                          icon: Icons.currency_exchange_rounded,
                          label: 'Currency',
                          value:
                              '${profile.currencyCode} $sym',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const CurrencyScreen()),
                          ),
                          ext: ext,
                          cs: cs,
                          tt: tt,
                        ),
                        _RowDivider(ext: ext),
                        _SettingsRow(
                          icon: Icons.account_balance_wallet_outlined,
                          label: 'Monthly Budget',
                          value:
                              '$sym${_nf.format((state.budget?.limit ?? 0).toInt())}',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SetBudgetScreen()),
                          ),
                          ext: ext,
                          cs: cs,
                          tt: tt,
                        ),
                        _RowDivider(ext: ext),
                        _SettingsRow(
                          icon: Icons.tune_rounded,
                          label: 'Manage Categories',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const ManageCategoriesScreen()),
                          ),
                          ext: ext,
                          cs: cs,
                          tt: tt,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: kSp12),

                  // ── Card 2: App settings ──────────────────────────────────
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _SettingsRow(
                          icon: Icons.notifications_outlined,
                          label: 'Notifications',
                          value: state.expenseReminders ? 'On' : 'Off',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const NotificationSettingsScreen()),
                          ),
                          ext: ext,
                          cs: cs,
                          tt: tt,
                        ),
                        _RowDivider(ext: ext),
                        _ThemeModeRow(
                          icon: Icons.dark_mode_outlined,
                          label: 'Appearance',
                          themeCtrl: themeCtrl,
                          ext: ext,
                          cs: cs,
                          tt: tt,
                        ),
                        _RowDivider(ext: ext),
                        _SettingsRow(
                          icon: Icons.info_outline_rounded,
                          label: 'About',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const AboutScreen()),
                          ),
                          ext: ext,
                          cs: cs,
                          tt: tt,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: kSp24),

                  // ── Log Out button ────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: kButtonHeight,
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.logout_rounded, color: ext.expense),
                      label: Text(
                        'Log Out',
                        style: TextStyle(
                          color: ext.expense,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onPressed: () => _logOut(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ext.expense.withAlpha(22),
                        foregroundColor: ext.expense,
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(kRadiusButton),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: kSp20),

                  // ── Footer ────────────────────────────────────────────────
                  Center(
                    child: Text(
                      'Where Did It Go? · Version 1.0.0',
                      style: tt.bodySmall?.copyWith(
                        color: ext.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  void _logOut(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text(
            "You'll need to log back in to see your expenses."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Log Out',
                style: TextStyle(
                    color:
                        Theme.of(ctx).extension<AppThemeExt>()!.expense)),
          ),
        ],
      ),
    ).then((ok) async {
      if (ok == true && context.mounted) {
        try {
          await context.read<AuthService>().signOut();
        } catch (_) {
          // Sign-out errors are non-critical — proceed to login regardless.
        }
        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (_) => false,
          );
        }
      }
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Circular avatar with amber dot
// ─────────────────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  const _Avatar({required this.ext, required this.cs});
  final AppThemeExt ext;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: ext.tint,
          child: Icon(Icons.person_rounded, color: cs.primary, size: 34),
        ),
        Positioned(
          bottom: 2,
          right: 2,
          child: Container(
            width: 11,
            height: 11,
            decoration: BoxDecoration(
              color: ext.warning,
              shape: BoxShape.circle,
              border: Border.all(color: ext.cardBackground, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Settings row (icon badge + label + optional value + chevron)
// ─────────────────────────────────────────────────────────────────────────────

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.value,
    required this.ext,
    required this.cs,
    required this.tt,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? value;
  final AppThemeExt ext;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(kRadiusCard),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: kSp16, vertical: kSp14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: ext.tint,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: cs.primary, size: 20),
            ),
            const SizedBox(width: kSp12),
            Expanded(
              child: Text(
                label,
                style: tt.bodyMedium?.copyWith(color: ext.textPrimary),
              ),
            ),
            if (value != null) ...[
              Text(
                value!,
                style: tt.bodySmall?.copyWith(color: ext.textSecondary),
              ),
              const SizedBox(width: kSp4),
            ],
            Icon(Icons.chevron_right_rounded,
                color: ext.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3-way Appearance row  (Light / System / Dark)
// ─────────────────────────────────────────────────────────────────────────────

class _ThemeModeRow extends StatelessWidget {
  const _ThemeModeRow({
    required this.icon,
    required this.label,
    required this.themeCtrl,
    required this.ext,
    required this.cs,
    required this.tt,
  });
  final IconData icon;
  final String label;
  final ThemeController themeCtrl;
  final AppThemeExt ext;
  final ColorScheme cs;
  final TextTheme tt;

  static const _modes = [
    (ThemeMode.light, Icons.light_mode_rounded, 'Light'),
    (ThemeMode.system, Icons.brightness_auto_rounded, 'System'),
    (ThemeMode.dark, Icons.dark_mode_rounded, 'Dark'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: kSp16, vertical: kSp10),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: ext.tint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: cs.primary, size: 20),
          ),
          const SizedBox(width: kSp12),
          Text(label,
              style: tt.bodyMedium?.copyWith(color: ext.textPrimary)),
          const Spacer(),
          // Segmented picker
          Container(
            decoration: BoxDecoration(
              color: ext.cardBackground,
              borderRadius: BorderRadius.circular(kRadiusButton),
              border: Border.all(color: ext.cardBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: _modes.map((m) {
                final (mode, mIcon, mLabel) = m;
                final sel = themeCtrl.themeMode == mode;
                return GestureDetector(
                  onTap: () async {
                    await themeCtrl.setMode(mode);
                    // Also save to Firestore (best-effort).
                    if (context.mounted) {
                      final uid = context
                          .read<AuthService>()
                          .currentUser
                          ?.uid;
                      if (uid != null) {
                        context.read<UserRepository>().updateSettings(
                          uid,
                          {'settings': {'themeMode': mode.name}},
                        ).ignore();
                      }
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                        horizontal: kSp10, vertical: kSp6),
                    decoration: BoxDecoration(
                      color: sel ? cs.primary : Colors.transparent,
                      borderRadius:
                          BorderRadius.circular(kRadiusButton - 2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(mIcon,
                            size: 14,
                            color: sel
                                ? Colors.white
                                : ext.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          mLabel,
                          style: tt.bodySmall?.copyWith(
                            color: sel ? Colors.white : ext.textSecondary,
                            fontWeight: sel
                                ? FontWeight.w600
                                : FontWeight.normal,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Thin divider used between settings rows
// ─────────────────────────────────────────────────────────────────────────────

class _RowDivider extends StatelessWidget {
  const _RowDivider({required this.ext});
  final AppThemeExt ext;

  @override
  Widget build(BuildContext context) => Divider(
        height: 1,
        thickness: 1,
        indent: kSp16 + 38 + kSp12,
        endIndent: kSp16,
        color: ext.divider,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Journey stat cell  (used in the "Your journey" row)
// ─────────────────────────────────────────────────────────────────────────────

class _JourneyStat extends StatelessWidget {
  const _JourneyStat({
    required this.value,
    required this.label,
    required this.ext,
    required this.cs,
    required this.tt,
  });
  final String value;
  final String label;
  final AppThemeExt ext;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: tt.titleMedium?.copyWith(
            color: cs.primary,
            fontWeight: FontWeight.w800,
            fontSize: 22,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: tt.bodySmall?.copyWith(
            color: ext.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

