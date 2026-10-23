import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../repositories/category_repository.dart';
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
import '../widgets/app_bottom_nav.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AuthGate
// ─────────────────────────────────────────────────────────────────────────────

/// Placed after the splash screen.
///
/// Listens to [AuthService.authStateChanges]:
/// - Signed in  → subscribes to profile stream + transaction stream, seeds
///                default categories if needed, then shows [AppShell].
/// - Signed out → cancels all streams, checks onboarding flag:
///                seen → [LoginScreen]; not seen → [OnboardingScreen].
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // While Firebase resolves the initial auth state show a blank screen.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        if (user != null) {
          // Signed in — subscribe to streams and show the main shell.
          return _AuthenticatedShell(user: user);
        }

        // Signed out — cancel streams + check onboarding flag.
        // Reading AppState here is safe; it doesn't trigger a rebuild.
        return _SignedOutCanceller(child: const _UnauthenticatedGate());
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SignedOutCanceller
// ─────────────────────────────────────────────────────────────────────────────

/// Cancels the transaction stream the moment the user signs out, then renders
/// [child]. Using initState ensures it runs exactly once per sign-out.
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
    // Cancel without triggering a rebuild on this widget.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AppState>().cancelTransactionStream();
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

// ─────────────────────────────────────────────────────────────────────────────
// _AuthenticatedShell
// ─────────────────────────────────────────────────────────────────────────────

/// Subscribes to the Firestore profile stream AND the transaction stream,
/// seeds categories on first login, then renders [AppShell].
///
/// Also shows a "Syncing your data…" SnackBar when [AppState.hasPendingWrites].
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
    final repo = context.read<UserRepository>();
    final txRepo = context.read<TransactionRepository>();
    final catRepo = context.read<CategoryRepository>();
    final appState = context.read<AppState>();
    final uid = widget.user.uid;

    // 1. Subscribe to transaction stream immediately (offline cache loads fast).
    appState.subscribeToTransactions(txRepo, uid);

    // 2. Seed categories if needed (best-effort, fire-and-forget).
    catRepo.seedIfEmpty(uid).ignore();

    // 3. Subscribe to profile stream.
    _profileSub = repo.profileStream(uid).listen(
      (profile) {
        if (!mounted) return;
        if (profile != null) {
          appState.applyProfileSnapshot(profile);
        } else {
          final displayName =
              widget.user.displayName ?? widget.user.email ?? 'User';
          final email = widget.user.email ?? '';
          appState.applyProfileSnapshot(
            appState.profile.copyWith(name: displayName, email: email),
          );
        }
        if (!_loaded && mounted) {
          setState(() => _loaded = true);
        }
      },
      onError: (_) {
        if (!_loaded && mounted) {
          setState(() => _loaded = true);
        }
      },
    );

    // Fallback: show shell even if profile stream is slow.
    await Future.delayed(const Duration(seconds: 3));
    if (!_loaded && mounted) {
      setState(() => _loaded = true);
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
        body: Center(child: CircularProgressIndicator()),
      );
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

/// Listens to [AppState.hasPendingWrites] and shows the "Syncing your data…"
/// SnackBar whenever there are unsynced offline writes.
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
    // Listen without rebuilding the heavy child.
    return _PendingWritesListener(
      onChanged: (hasPending) {
        if (!mounted) return;
        final messenger = ScaffoldMessenger.maybeOf(context);
        if (messenger == null) return;
        if (hasPending && !_wasShowingBanner) {
          _wasShowingBanner = true;
          messenger.showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  ),
                  SizedBox(width: 12),
                  Text('Syncing your data…'),
                ],
              ),
              duration: Duration(seconds: 30),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (!hasPending && _wasShowingBanner) {
          _wasShowingBanner = false;
          messenger.hideCurrentSnackBar();
        }
      },
      child: widget.child,
    );
  }
}

/// Helper that listens to [AppState.hasPendingWrites] and calls [onChanged].
class _PendingWritesListener extends StatefulWidget {
  const _PendingWritesListener(
      {required this.onChanged, required this.child});
  final void Function(bool hasPending) onChanged;
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
      // Defer so we're not calling setState during build.
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

/// Decides between [OnboardingScreen] and [LoginScreen] based on shared prefs.
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
  Widget build(BuildContext context) {
    return _screen ??
        const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
