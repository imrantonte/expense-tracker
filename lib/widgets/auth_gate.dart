import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme_controller.dart';
import '../data/app_state.dart';
import '../repositories/budget_repository.dart';
import '../repositories/category_repository.dart';
import '../repositories/notification_repository.dart';
import '../repositories/transaction_repository.dart';
import '../repositories/user_repository.dart';
import '../screens/auth/login_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/reports/reports_screen.dart';
import '../screens/transactions/transactions_screen.dart';
import '../services/auth_service.dart';
import '../services/onboarding_prefs.dart';
import 'app_bottom_nav.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AuthGate
// ─────────────────────────────────────────────────────────────────────────────

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        final user = snapshot.data;
        if (user != null) {
          return _AuthenticatedShell(user: user);
        }
        return _SignedOutCanceller(child: const _UnauthenticatedGate());
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SignedOutCanceller — tears down all streams on logout
// ─────────────────────────────────────────────────────────────────────────────

class _SignedOutCanceller extends StatefulWidget {
  const _SignedOutCanceller({required this.child});
  final Widget child;

  @override
  State<_SignedOutCanceller> createState() => _SignedOutCancellerState();
}

class _SignedOutCancellerState extends State<_SignedOutCanceller> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AppState>().cancelAll();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

// ─────────────────────────────────────────────────────────────────────────────
// _AuthenticatedShell — subscribes to all streams, then shows AppShell
// ─────────────────────────────────────────────────────────────────────────────

class _AuthenticatedShell extends StatefulWidget {
  const _AuthenticatedShell({required this.user});
  final User user;

  @override
  State<_AuthenticatedShell> createState() => _AuthenticatedShellState();
}

class _AuthenticatedShellState extends State<_AuthenticatedShell> {
  bool _loaded = false;
  StreamSubscription<dynamic>? _profileSub;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final txRepo = context.read<TransactionRepository>();
    final budgetRepo = context.read<BudgetRepository>();
    final notifRepo = context.read<NotificationRepository>();
    final catRepo = context.read<CategoryRepository>();
    final userRepo = context.read<UserRepository>();
    final appState = context.read<AppState>();
    final uid = widget.user.uid;

    // 1. Subscribe to all Firestore streams immediately.
    appState.subscribeAll(
      txRepo: txRepo,
      budgetRepo: budgetRepo,
      notifRepo: notifRepo,
      catRepo: catRepo,
      userRepo: userRepo,
      uid: uid,
    );

    // 2. Seed categories on first login (best-effort, fire-and-forget).
    catRepo.seedIfEmpty(uid).ignore();

    // 3. Restore theme mode saved to Firestore (SharedPrefs is already
    //    applied before runApp; this keeps them in sync on new devices).
    _restoreThemeFromFirestore(userRepo, uid);

    // 4. Subscribe to profile stream.
    _profileSub = userRepo.profileStream(uid).listen(
      (profile) {
        if (!mounted) return;
        if (profile != null) {
          appState.applyProfileSnapshot(profile);
        } else {
          final displayName =
              widget.user.displayName ?? widget.user.email ?? 'User';
          final email = widget.user.email ?? '';
          appState.applyProfileSnapshot(
              appState.profile.copyWith(name: displayName, email: email));
        }
        if (!_loaded && mounted) setState(() => _loaded = true);
      },
      onError: (_) {
        if (!_loaded && mounted) setState(() => _loaded = true);
      },
    );

    // Fallback: show shell after 3 s even if profile stream is slow.
    await Future.delayed(const Duration(seconds: 3));
    if (!_loaded && mounted) setState(() => _loaded = true);
  }

  void _restoreThemeFromFirestore(UserRepository repo, String uid) async {
    try {
      final settings = await repo.fetchRawSettings(uid);
      final modeStr = settings?['themeMode'] as String?;
      if (modeStr != null && mounted) {
        final mode = ThemeMode.values.firstWhere(
          (m) => m.name == modeStr,
          orElse: () => ThemeMode.system,
        );
        // setMode also persists to SharedPreferences.
        await context.read<ThemeController>().setMode(mode);
      }
    } catch (_) {
      // Non-fatal.
    }
  }

  @override
  void dispose() {
    _profileSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    return _SyncBannerWrapper(
      child: AppShell(
        tabs: const [
          HomeScreen(),
          TransactionsScreen(),
          ReportsScreen(),
          ProfileScreen(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SyncBannerWrapper
// ─────────────────────────────────────────────────────────────────────────────

class _SyncBannerWrapper extends StatefulWidget {
  const _SyncBannerWrapper({required this.child});
  final Widget child;

  @override
  State<_SyncBannerWrapper> createState() => _SyncBannerWrapperState();
}

class _SyncBannerWrapperState extends State<_SyncBannerWrapper> {
  bool _wasShowingBanner = false;

  @override
  Widget build(BuildContext context) {
    return _PendingWritesListener(
      onChanged: (hasPending) {
        if (!mounted) return;
        final messenger = ScaffoldMessenger.maybeOf(context);
        if (messenger == null) return;
        if (hasPending && !_wasShowingBanner) {
          _wasShowingBanner = true;
          messenger.showSnackBar(const SnackBar(
            content: Row(children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(width: 12),
              Text('Syncing your data…'),
            ]),
            duration: Duration(seconds: 30),
            behavior: SnackBarBehavior.floating,
          ));
        } else if (!hasPending && _wasShowingBanner) {
          _wasShowingBanner = false;
          messenger.hideCurrentSnackBar();
        }
      },
      child: widget.child,
    );
  }
}

class _PendingWritesListener extends StatefulWidget {
  const _PendingWritesListener(
      {required this.onChanged, required this.child});
  final void Function(bool) onChanged;
  final Widget child;

  @override
  State<_PendingWritesListener> createState() =>
      _PendingWritesListenerState();
}

class _PendingWritesListenerState extends State<_PendingWritesListener> {
  bool _last = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final current = context.watch<AppState>().hasPendingWrites;
    if (current != _last) {
      _last = current;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onChanged(current);
      });
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

// ─────────────────────────────────────────────────────────────────────────────
// _UnauthenticatedGate
// ─────────────────────────────────────────────────────────────────────────────

class _UnauthenticatedGate extends StatefulWidget {
  const _UnauthenticatedGate();

  @override
  State<_UnauthenticatedGate> createState() => _UnauthenticatedGateState();
}

class _UnauthenticatedGateState extends State<_UnauthenticatedGate> {
  Widget? _screen;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    final seen = await OnboardingPrefs.hasSeenOnboarding();
    if (!mounted) return;
    setState(() {
      _screen = seen ? const LoginScreen() : const OnboardingScreen();
    });
  }

  @override
  Widget build(BuildContext context) =>
      _screen ??
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}
