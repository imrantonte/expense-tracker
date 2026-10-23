import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
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
/// - Signed in  → loads the Firestore profile into [AppState], then shows
///                [AppShell].
/// - Signed out → checks whether onboarding was already seen (SharedPrefs):
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
          // Signed in — hydrate AppState profile and show the main shell.
          return _AuthenticatedShell(user: user);
        }

        // Signed out — check onboarding flag.
        return const _UnauthenticatedGate();
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _AuthenticatedShell
// ─────────────────────────────────────────────────────────────────────────────

/// Loads the Firestore user profile into [AppState], then renders [AppShell].
class _AuthenticatedShell extends StatefulWidget {
  const _AuthenticatedShell({required this.user});
  final User user;

  @override
  State<_AuthenticatedShell> createState() => _AuthenticatedShellState();
}

class _AuthenticatedShellState extends State<_AuthenticatedShell> {
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final repo = context.read<UserRepository>();
      final appState = context.read<AppState>();
      final profile = await repo.fetchProfile(widget.user.uid);
      if (!mounted) return;
      if (profile != null) {
        appState.updateProfile(profile);
      } else {
        // Firestore doc missing — fall back to Firebase Auth display name.
        final displayName =
            widget.user.displayName ?? widget.user.email ?? 'User';
        final email = widget.user.email ?? '';
        appState.updateProfile(
          appState.profile.copyWith(name: displayName, email: email),
        );
      }
    } catch (_) {
      // Profile load failed — continue with mock/existing data.
    } finally {
      if (mounted) setState(() => _loaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return AppShell(
      tabs: const [
        HomeScreen(),
        TransactionsScreen(),
        ReportsScreen(),
        ProfileScreen(),
      ],
    );
  }
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
