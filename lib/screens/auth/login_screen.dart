import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_theme_ext.dart';
import '../../core/constants.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/reports/reports_screen.dart';
import '../../screens/transactions/transactions_screen.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';
import 'auth_shared.dart';
import 'register_screen.dart';

/// Login screen — email and password, with "Forgot password?" and footer link.
///
/// Validation errors are reported via [SnackBar]; no inline error text.
/// On success navigates to [AppShell] (the main app).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  // ── Validation & submission ─────────────────────────────────────────────────

  void _submit() {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;

    if (email.isEmpty || !isValidEmail(email)) {
      showAuthSnackBar(context, 'Please enter a valid email address.');
      return;
    }
    if (pass.isEmpty) {
      showAuthSnackBar(context, 'Please enter your password.');
      return;
    }

    setState(() => _loading = true);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      _goToApp();
    });
  }

  void _goToApp() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => AppShell(
          tabs: const [
            HomeScreen(),
            TransactionsScreen(),
            ReportsScreen(),
            ProfileScreen(),
          ],
        ),
      ),
      (_) => false,
    );
  }

  void _goToRegister() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  void _forgotPassword() {
    showAuthSnackBar(context, 'Password reset is not available in this demo.');
  }

  void _googleSignIn() {
    showAuthSnackBar(context, 'Google Sign-In is not available in this demo.');
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExt>()!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
                horizontal: kSp24, vertical: kSp20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header row ────────────────────────────────────────────
                const AuthHeader(),
                const SizedBox(height: kSp32),

                // ── Heading ───────────────────────────────────────────────
                Text(
                  'Welcome back',
                  style: tt.headlineMedium?.copyWith(
                    color: ext.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 26,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: kSp8),

                // ── Subtitle ──────────────────────────────────────────────
                Text(
                  "Let's find where your money went.",
                  style: tt.bodyMedium?.copyWith(
                    color: ext.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: kSp32),

                // ── Email field ───────────────────────────────────────────
                AppTextField(
                  label: 'Email',
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: kSp16),

                // ── Password field ────────────────────────────────────────
                AppTextField.password(
                  label: 'Password',
                  controller: _passCtrl,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: kSp8),

                // ── Forgot password ───────────────────────────────────────
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: _forgotPassword,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: kSp8),
                      child: Text(
                        'Forgot password?',
                        style: tt.bodyMedium?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: kSp20),

                // ── Log In button ─────────────────────────────────────────
                PrimaryButton(
                  label: 'Log In',
                  isLoading: _loading,
                  onPressed: _submit,
                ),
                const SizedBox(height: kSp24),

                // ── Or divider ────────────────────────────────────────────
                const AuthDividerOr(),
                const SizedBox(height: kSp24),

                // ── Google button ─────────────────────────────────────────
                GoogleButton(onPressed: _googleSignIn),
                const SizedBox(height: kSp32),

                // ── Footer ────────────────────────────────────────────────
                Center(
                  child: AuthFooterLink(
                    prefix: "Don't have an account?",
                    linkLabel: 'Sign up',
                    onTap: _goToRegister,
                  ),
                ),
                const SizedBox(height: kSp16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
