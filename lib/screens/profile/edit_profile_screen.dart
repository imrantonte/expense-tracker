import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme_ext.dart';
import '../../core/constants.dart';
import '../../data/app_state.dart';
import '../../repositories/user_repository.dart';
import '../../screens/auth/register_screen.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_card.dart';

// ─────────────────────────────────────────────────────────────────────────────
// EditProfileScreen  (follows the Figma: avatar card + Name field + Save)
// ─────────────────────────────────────────────────────────────────────────────

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(
        text: context.read<AppState>().profile.name);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  // ── Save name ────────────────────────────────────────────────────────────

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _showError('Name cannot be empty.');
      return;
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _showError('Not signed in.');
      return;
    }
    setState(() => _saving = true);
    try {
      // 1. Persist to Firestore.
      await context.read<UserRepository>().updateName(uid, name);
      // 2. Update Firebase Auth display name.
      await FirebaseAuth.instance.currentUser?.updateDisplayName(name);
      // 3. AppState refreshes via the profileStream — no manual update needed.
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) _showError('Could not save. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Change password ───────────────────────────────────────────────────────

  void _changePassword() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _ChangePasswordDialog(),
    );
  }

  // ── Delete account ────────────────────────────────────────────────────────

  void _deleteAccount() {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This will permanently delete your account and all your data. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).extension<AppThemeExt>()!.expense,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && mounted) {
        _confirmAndDelete();
      }
    });
  }

  void _confirmAndDelete() {
    showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _DeleteAccountDialog(),
    ).then((password) async {
      if (password == null || !mounted) return;
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      // Capture services before any await to avoid BuildContext-across-gap lint.
      final repo = context.read<UserRepository>();
      final authService = context.read<AuthService>();

      setState(() => _saving = true);
      try {
        // 1. Delete Firestore data first (while user is still auth'd).
        await repo.deleteUserData(uid);
        // 2. Re-auth + delete Firebase Auth user.
        await authService.deleteAccount(password: password);
        // 3. Navigate to Register (auth state change would handle it, but
        //    be explicit so we always reach a clean screen).
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const RegisterScreen()),
            (_) => false,
          );
        }
      } on AuthException catch (e) {
        if (mounted) _showError(e.message);
      } catch (_) {
        if (mounted) _showError('Could not delete account. Please try again.');
      } finally {
        if (mounted) setState(() => _saving = false);
      }
    });
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExt>()!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final profile = context.watch<AppState>().profile;

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
          'Edit Profile',
          style: tt.titleLarge?.copyWith(
            color: ext.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: kFontScreenTitle,
          ),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => FocusScope.of(context).unfocus(),
                  behavior: HitTestBehavior.opaque,
                  child: ListView(
                    padding:
                        const EdgeInsets.fromLTRB(kSp16, 0, kSp16, 24),
                    children: [
                      // Subtitle
                      Text(
                        'A few details. A more personal money journey.',
                        style: tt.bodyMedium
                            ?.copyWith(color: ext.textSecondary),
                      ),
                      const SizedBox(height: kSp20),

                      // ── Avatar card ──────────────────────────────────────
                      AppCard(
                        child: Row(
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundColor: ext.tint,
                                  child: Icon(Icons.person_rounded,
                                      color: cs.primary, size: 34),
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
                                      border: Border.all(
                                          color: ext.cardBackground, width: 2),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: kSp16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
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
                      const SizedBox(height: kSp20),

                      // ── Name field ───────────────────────────────────────
                      TextField(
                        controller: _nameCtrl,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                        ),
                      ),
                      const SizedBox(height: kSp16),

                      // ── Email field (read-only) ───────────────────────────
                      TextField(
                        controller:
                            TextEditingController(text: profile.email),
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          helperText: 'Email changes are coming later',
                        ),
                      ),
                      const SizedBox(height: kSp32),

                      // ── Security section ─────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.only(left: kSp4),
                        child: Text(
                          'SECURITY',
                          style: tt.labelSmall?.copyWith(
                            color: ext.textSecondary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(height: kSp8),

                      AppCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Change password
                            InkWell(
                              onTap: _changePassword,
                              borderRadius:
                                  BorderRadius.circular(kRadiusCard),
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
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                          Icons.lock_outline_rounded,
                                          color: cs.primary,
                                          size: 20),
                                    ),
                                    const SizedBox(width: kSp12),
                                    Expanded(
                                      child: Text('Change Password',
                                          style: tt.bodyMedium?.copyWith(
                                              color: ext.textPrimary)),
                                    ),
                                    Icon(Icons.chevron_right_rounded,
                                        color: ext.textSecondary, size: 20),
                                  ],
                                ),
                              ),
                            ),

                            Divider(
                                height: 1,
                                thickness: 1,
                                indent: kSp16 + 38 + kSp12,
                                endIndent: kSp16,
                                color: ext.divider),

                            // Delete account
                            InkWell(
                              onTap: _deleteAccount,
                              borderRadius:
                                  BorderRadius.circular(kRadiusCard),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: kSp16, vertical: kSp14),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: ext.expense.withAlpha(22),
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                          Icons.delete_outline_rounded,
                                          color: ext.expense,
                                          size: 20),
                                    ),
                                    const SizedBox(width: kSp12),
                                    Expanded(
                                      child: Text('Delete Account',
                                          style: tt.bodyMedium?.copyWith(
                                              color: ext.expense)),
                                    ),
                                    Icon(Icons.chevron_right_rounded,
                                        color: ext.textSecondary, size: 20),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: kSp24),
                    ],
                  ),
                ),
              ),

              // ── Save pill ──────────────────────────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(kSp16, 0, kSp16, kSp24),
                child: SizedBox(
                  width: double.infinity,
                  height: kButtonHeight,
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(kRadiusButton)),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Save',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Change-password dialog
// ─────────────────────────────────────────────────────────────────────────────

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final current = _currentCtrl.text;
    final newPw = _newCtrl.text;
    final confirm = _confirmCtrl.text;

    if (current.isEmpty) {
      _showError('Please enter your current password.');
      return;
    }
    if (newPw.length < 6) {
      _showError('New password must be at least 6 characters.');
      return;
    }
    if (newPw != confirm) {
      _showError('New passwords do not match.');
      return;
    }

    setState(() => _loading = true);
    try {
      await context.read<AuthService>().changePassword(
            currentPassword: current,
            newPassword: newPw,
          );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
              const SnackBar(content: Text('Password changed successfully.')));
      }
    } on AuthException catch (e) {
      if (mounted) _showError(e.message);
    } catch (_) {
      if (mounted) _showError('Could not change password. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change Password'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _currentCtrl,
              obscureText: _obscureCurrent,
              decoration: InputDecoration(
                labelText: 'Current password',
                suffixIcon: IconButton(
                  icon: Icon(_obscureCurrent
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined),
                  onPressed: () =>
                      setState(() => _obscureCurrent = !_obscureCurrent),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _newCtrl,
              obscureText: _obscureNew,
              decoration: InputDecoration(
                labelText: 'New password',
                suffixIcon: IconButton(
                  icon: Icon(_obscureNew
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined),
                  onPressed: () =>
                      setState(() => _obscureNew = !_obscureNew),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmCtrl,
              obscureText: _obscureConfirm,
              decoration: InputDecoration(
                labelText: 'Confirm new password',
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirm
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Update'),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Delete-account confirmation dialog (asks for password)
// ─────────────────────────────────────────────────────────────────────────────

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final errorColor = Theme.of(context).extension<AppThemeExt>()!.expense;
    return AlertDialog(
      title: Text('Confirm deletion',
          style: TextStyle(color: errorColor)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enter your password to permanently delete your account.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passCtrl,
            obscureText: _obscure,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Password',
              suffixIcon: IconButton(
                icon: Icon(_obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final pw = _passCtrl.text;
            if (pw.isEmpty) return;
            Navigator.pop(context, pw);
          },
          style: TextButton.styleFrom(foregroundColor: errorColor),
          child: const Text('Delete forever'),
        ),
      ],
    );
  }
}
