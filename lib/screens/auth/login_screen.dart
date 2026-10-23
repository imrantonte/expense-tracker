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
import 'register_screen.dart';

/// Login screen — email and password, with "Forgot password?" and footer link.
///
/// Validation errors are reported via [SnackBar]; no inline error text.
/// On success the [AuthGate] StreamBuilder reacts and navigates automatically.
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

  Future<void> _submit() async {
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
    try {
      await context.read<AuthService>().signIn(email: email, password: pass);
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

  void _goToRegister() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  Future<void> _forgotPassword() async {
    final email = _emailCtrl.text.trim();

    // If the field is empty, ask for the email via a dialog.
    if (email.isEmpty || !isValidEmail(email)) {
      await _showForgotPasswordDialog();
      return;
    }

    await _sendReset(email);
  }

  Future<void> _showForgotPasswordDialog() async {
    final ctrl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset password'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            hintText: 'Enter your email address',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final email = ctrl.text.trim();
              if (isValidEmail(email)) {
                await _sendReset(email);
              } else {
                if (mounted) {
                  showAuthSnackBar(
                      context, 'Please enter a valid email address.');
                }
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
    ctrl.dispose();
  }

  Future<void> _sendReset(String email) async {
    try {
      await context.read<AuthService>().sendPasswordReset(email);
      if (mounted) showAuthSnackBar(context, 'Reset link sent to $email.');
    } on AuthException catch (e) {
      if (mounted) showAuthSnackBar(context, e.message);
    } catch (_) {
      if (mounted) {
        showAuthSnackBar(context, 'Could not send reset email. Try again.');
      }
    }
  }

  void _googleSignIn() {
    showAuthSnackBar(context, 'Google sign-in is coming soon.');
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
                    onTap: _loading ? null : _forgotPassword,
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
                GoogleButton(onPressed: _loading ? () {} : _googleSignIn),
                const SizedBox(height: kSp32),

                // ── Footer ────────────────────────────────────────────────
                Center(
                  child: AuthFooterLink(
                    prefix: "Don't have an account?",
                    linkLabel: 'Sign up',
                    onTap: _loading ? () {} : _goToRegister,
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
