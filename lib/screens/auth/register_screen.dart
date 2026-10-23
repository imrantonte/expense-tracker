import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme_ext.dart';
import '../../core/constants.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/auth_gate.dart';
import '../../widgets/primary_button.dart';
import 'auth_shared.dart';
import 'login_screen.dart';

/// Registration screen — collects name, email, password, and confirm password.
///
/// Validation errors are reported via a [SnackBar]; no inline error text.
/// On success [AuthGate]'s StreamBuilder reacts and navigates automatically.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // ── Validation & submission ─────────────────────────────────────────────────

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    final confirm = _confirmCtrl.text;

    if (name.isEmpty) {
      showAuthSnackBar(context, 'Please enter your full name.');
      return;
    }
    if (email.isEmpty || !isValidEmail(email)) {
      showAuthSnackBar(context, 'Please enter a valid email address.');
      return;
    }
    if (pass.length < 6) {
      showAuthSnackBar(context, 'Password must be at least 6 characters.');
      return;
    }
    if (pass != confirm) {
      showAuthSnackBar(context, 'Passwords do not match.');
      return;
    }

    setState(() => _loading = true);
    try {
      await context.read<AuthService>().register(
            name: name,
            email: email,
            password: pass,
          );
      // AuthGate's StreamBuilder reacts to the auth state change automatically.
      if (mounted) _goToAuthGate();
    } on AuthException catch (e) {
      if (mounted) showAuthSnackBar(context, e.message);
    } catch (_) {
      if (mounted) {
        showAuthSnackBar(context, 'Something went wrong. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _goToAuthGate() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthGate()),
      (_) => false,
    );
  }

  void _goToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _googleSignIn() {
    showAuthSnackBar(context, 'Google sign-in is coming soon.');
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExt>()!;
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
                  'Create your account',
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
                  "A little clarity starts here. Let's give your money a plan.",
                  style: tt.bodyMedium?.copyWith(
                    color: ext.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: kSp32),

                // ── Fields ────────────────────────────────────────────────
                AppTextField(
                  label: 'Full Name',
                  controller: _nameCtrl,
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: kSp16),

                AppTextField(
                  label: 'Email',
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: kSp16),

                AppTextField.password(
                  label: 'Password',
                  controller: _passCtrl,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: kSp16),

                AppTextField.password(
                  label: 'Confirm Password',
                  controller: _confirmCtrl,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: kSp28),

                // ── Create Account button ─────────────────────────────────
                PrimaryButton(
                  label: 'Create Account',
                  isLoading: _loading,
                  onPressed: _submit,
                ),
                const SizedBox(height: kSp24),

                // ── Or divider ────────────────────────────────────────────
                const AuthDividerOr(),
                const SizedBox(height: kSp24),

                // ── Google button ─────────────────────────────────────────
                GoogleButton(onPressed: _loading ? () {} : _googleSignIn),
                const SizedBox(height: kSp32),

                // ── Footer ────────────────────────────────────────────────
                Center(
                  child: AuthFooterLink(
                    prefix: 'Already have an account?',
                    linkLabel: 'Log in',
                    onTap: _loading ? () {} : _goToLogin,
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

// ─── local spacing not in system ─────────────────────────────────────────────
const double kSp28 = 28.0;
