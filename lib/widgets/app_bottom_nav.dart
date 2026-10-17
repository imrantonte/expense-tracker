import 'package:flutter/material.dart';
import '../core/app_theme_ext.dart';
import '../core/constants.dart';

/// The 4-tab bottom navigation bar.
///
/// Active tab: light-teal pill behind the icon + teal label.
/// Inactive tab: muted icon + muted label.
///
/// Usage — place this as [Scaffold.bottomNavigationBar]:
/// ```dart
/// AppBottomNav(
///   currentIndex: _tabIndex,
///   onDestinationSelected: (i) => setState(() => _tabIndex = i),
/// )
/// ```
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExt>()!;

    return Container(
      decoration: BoxDecoration(
        color: ext.cardBackground,
        border: Border(top: BorderSide(color: ext.divider)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(14),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onDestinationSelected,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        // Compact height
        height: 64,
        animationDuration: const Duration(milliseconds: 200),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
            tooltip: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Transactions',
            tooltip: 'Transactions',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart_rounded),
            label: 'Reports',
            tooltip: 'Reports',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
            tooltip: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ─── Convenience: wraps Scaffold with AppBottomNav ───────────────────────────

/// A [Scaffold] that owns the [AppBottomNav] and handles tab switching via an
/// [IndexedStack] so each tab preserves its scroll position.
///
/// Pass [tabs] as an ordered list of widgets matching the 4 nav destinations.
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.tabs});

  final List<Widget> tabs;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: widget.tabs,
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
      ),
    );
  }
}

// ─── Placeholder screens for unmplemented tabs ────────────────────────────────

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExt>()!;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: ext.textSecondary),
            const SizedBox(height: kSp12),
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: ext.textSecondary,
                  ),
            ),
            const SizedBox(height: kSp8),
            Text(
              'Coming soon',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ext.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pre-built placeholder for the Transactions tab.
class TransactionsPlaceholder extends StatelessWidget {
  const TransactionsPlaceholder({super.key});
  @override
  Widget build(BuildContext context) => const _PlaceholderTab(
        label: 'Transactions',
        icon: Icons.receipt_long_outlined,
      );
}

/// Pre-built placeholder for the Reports tab.
class ReportsPlaceholder extends StatelessWidget {
  const ReportsPlaceholder({super.key});
  @override
  Widget build(BuildContext context) => const _PlaceholderTab(
        label: 'Reports',
        icon: Icons.bar_chart_outlined,
      );
}

/// Pre-built placeholder for the Profile tab.
class ProfilePlaceholder extends StatelessWidget {
  const ProfilePlaceholder({super.key});
  @override
  Widget build(BuildContext context) => const _PlaceholderTab(
        label: 'Profile',
        icon: Icons.person_outline_rounded,
      );
}
