import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../core/app_theme_ext.dart';
import '../../core/constants.dart';
import '_preview_nav_bar.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DashboardLoadingScreen — skeleton shimmer of the Home layout
// Pure Flutter shimmer: no external package required.
// ─────────────────────────────────────────────────────────────────────────────

class DashboardLoadingScreen extends StatefulWidget {
  const DashboardLoadingScreen({super.key});

  @override
  State<DashboardLoadingScreen> createState() =>
      _DashboardLoadingScreenState();
}

class _DashboardLoadingScreenState extends State<DashboardLoadingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ── Shimmer gradient helper ─────────────────────────────────────────────────

  Decoration _shimmerDecoration(BuildContext context, AppThemeExt ext, double radius) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? const Color(0xFF263634) : const Color(0xFFDEE8E6);
    final hi = isDark ? const Color(0xFF37514D) : const Color(0xFFF0F5F4);

    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: LinearGradient(
        begin: Alignment(
            lerpDouble(-1.5, 1.5, _ctrl.value)!, 0),
        end: Alignment(
            lerpDouble(-0.5, 2.5, _ctrl.value)!, 0),
        colors: [base, hi, base],
        stops: const [0.0, 0.5, 1.0],
      ),
    );
  }

  // ── Skeleton box ────────────────────────────────────────────────────────────

  Widget _box(BuildContext context, AppThemeExt ext,
      {double? width, required double height, double radius = 10}) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Container(
        width: width,
        height: height,
        decoration: _shimmerDecoration(context, ext, radius),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExt>()!;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding:
              const EdgeInsets.fromLTRB(kSp16, kSp16, kSp16, kSp24),
          children: [
            // ── Header skeleton ───────────────────────────────────────
            Row(
              children: [
                _box(context, ext, width: 34, height: 34, radius: kRadiusBadge),
                const SizedBox(width: kSp10),
                _box(context, ext, width: 140, height: 16),
                const Spacer(),
                _box(context, ext, width: 28, height: 28, radius: 14),
              ],
            ),
            const SizedBox(height: kSp24),

            // ── Greeting skeleton ─────────────────────────────────────
            _box(context, ext, width: 160, height: 20),
            const SizedBox(height: kSp6),
            _box(context, ext, width: 200, height: 14),
            const SizedBox(height: kSp20),

            // ── Balance card skeleton (tall, teal-card shape) ─────────
            _box(context, ext, height: 148, radius: kRadiusCard),
            const SizedBox(height: kSp12),

            // ── Budget card skeleton ──────────────────────────────────
            _box(context, ext, height: 110, radius: kRadiusCard),
            const SizedBox(height: kSp12),

            // ── Two side-by-side summary cards ────────────────────────
            Row(
              children: [
                Expanded(
                    child: _box(context, ext,
                        height: 80, radius: kRadiusCard)),
                const SizedBox(width: kSp12),
                Expanded(
                    child: _box(context, ext,
                        height: 80, radius: kRadiusCard)),
              ],
            ),
            const SizedBox(height: kSp24),

            // ── Section header skeleton ───────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _box(context, ext, width: 150, height: 16),
                _box(context, ext, width: 56, height: 14),
              ],
            ),
            const SizedBox(height: kSp16),

            // ── Transaction row skeletons ─────────────────────────────
            for (int i = 0; i < 4; i++) ...[
              _TxnRowSkeleton(box: (h, {double? w}) => _box(context, ext, width: w, height: h)),
              const SizedBox(height: kSp10),
            ],
          ],
        ),
      ),
      bottomNavigationBar: const PreviewNavBar(selectedIndex: 0),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Transaction row skeleton
// ─────────────────────────────────────────────────────────────────────────────

class _TxnRowSkeleton extends StatelessWidget {
  const _TxnRowSkeleton({required this.box});
  final Widget Function(double h, {double? w}) box;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        box(48, w: 48),
        const SizedBox(width: kSp12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              box(14, w: 120),
              const SizedBox(height: kSp6),
              box(11, w: 80),
            ],
          ),
        ),
        box(14, w: 60),
      ],
    );
  }
}
