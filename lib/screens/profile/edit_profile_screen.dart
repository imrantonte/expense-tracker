import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme_ext.dart';
import '../../core/constants.dart';
import '../../data/app_state.dart';
import '../../repositories/user_repository.dart';
import '../../screens/auth/register_screen.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_card.dart';
import '../../widgets/user_avatar.dart';

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
  bool _photoLoading = false;

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

  // ── Photo bottom sheet ────────────────────────────────────────────────────

  void _openPhotoSheet() {
    final profile = context.read<AppState>().profile;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _PhotoBottomSheet(
        currentAvatarId: profile.avatarId,
        hasPhoto:
            (profile.photoBase64 != null && profile.photoBase64!.isNotEmpty) ||
                (profile.avatarId != null && profile.avatarId!.isNotEmpty),
        onTakePhoto: () {
          Navigator.pop(ctx);
          _pickImage(ImageSource.camera);
        },
        onChooseGallery: () {
          Navigator.pop(ctx);
          _pickImage(ImageSource.gallery);
        },
        onPickAvatar: (String id) {
          Navigator.pop(ctx);
          _saveAvatarId(id);
        },
        onRemove: () {
          Navigator.pop(ctx);
          _removePhoto();
        },
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final repo = context.read<UserRepository>(); // capture before async gap

    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: source,
        maxWidth: 256,
        maxHeight: 256,
        imageQuality: 70,
      );
      if (file == null) return; // user cancelled

      setState(() => _photoLoading = true);

      final bytes = await file.readAsBytes();
      // Refuse images larger than 200 KB after compression.
      if (bytes.length > 200 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(const SnackBar(
              content: Text(
                'Photo is too large (max 200 KB). '
                'Please choose a smaller image.',
              ),
            ));
        }
        return;
      }

      final base64Str = base64Encode(bytes);
      await repo.updatePhotoBase64(uid, base64Str);
    } catch (_) {
      if (mounted) _showError('Could not upload photo. Please try again.');
    } finally {
      if (mounted) setState(() => _photoLoading = false);
    }
  }

  Future<void> _saveAvatarId(String id) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() => _photoLoading = true);
    try {
      await context.read<UserRepository>().updateAvatarId(uid, id);
    } catch (_) {
      if (mounted) _showError('Could not save avatar. Please try again.');
    } finally {
      if (mounted) setState(() => _photoLoading = false);
    }
  }

  Future<void> _removePhoto() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() => _photoLoading = true);
    try {
      await context.read<UserRepository>().removePhoto(uid);
    } catch (_) {
      if (mounted) _showError('Could not remove photo. Please try again.');
    } finally {
      if (mounted) setState(() => _photoLoading = false);
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
                            // Avatar with camera badge + loading overlay
                            GestureDetector(
                              onTap: _openPhotoSheet,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  UserAvatar(
                                    radius: 30,
                                    photoBase64: profile.photoBase64,
                                    avatarId: profile.avatarId,
                                    showDot: true,
                                    onTap: null, // handled by GestureDetector
                                  ),
                                  // Camera badge
                                  Positioned(
                                    bottom: -2,
                                    right: -2,
                                    child: Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: cs.primary,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: ext.cardBackground,
                                            width: 1.5),
                                      ),
                                      child: Icon(
                                        Icons.camera_alt_rounded,
                                        color: Colors.white,
                                        size: 11,
                                      ),
                                    ),
                                  ),
                                  // Loading overlay
                                  if (_photoLoading)
                                    Positioned.fill(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black38,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Center(
                                          child: SizedBox(
                                            width: 20,
                                            height: 20,
                                            child:
                                                CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
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
                                  const SizedBox(height: kSp4),
                                  // "Change photo" link
                                  GestureDetector(
                                    onTap: _openPhotoSheet,
                                    child: Text(
                                      'Change photo',
                                      style: tt.bodySmall?.copyWith(
                                        color: cs.primary,
                                        fontWeight: FontWeight.w600,
                                        decoration:
                                            TextDecoration.underline,
                                        decorationColor: cs.primary,
                                      ),
                                    ),
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
// Photo options bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _PhotoBottomSheet extends StatefulWidget {
  const _PhotoBottomSheet({
    required this.onTakePhoto,
    required this.onChooseGallery,
    required this.onPickAvatar,
    required this.onRemove,
    required this.hasPhoto,
    this.currentAvatarId,
  });

  final VoidCallback onTakePhoto;
  final VoidCallback onChooseGallery;
  final void Function(String avatarId) onPickAvatar;
  final VoidCallback onRemove;
  final bool hasPhoto;
  final String? currentAvatarId;

  @override
  State<_PhotoBottomSheet> createState() => _PhotoBottomSheetState();
}

class _PhotoBottomSheetState extends State<_PhotoBottomSheet> {
  bool _showAvatarGrid = false;

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExt>()!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ext.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  'Profile photo',
                  style: tt.titleMedium?.copyWith(
                    color: ext.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              Divider(height: 1, color: ext.divider),

              // ── Options ──────────────────────────────────────────────────
              _SheetOption(
                icon: Icons.camera_alt_outlined,
                label: 'Take photo',
                onTap: widget.onTakePhoto,
                ext: ext,
                cs: cs,
                tt: tt,
              ),
              _SheetOption(
                icon: Icons.photo_library_outlined,
                label: 'Choose from gallery',
                onTap: widget.onChooseGallery,
                ext: ext,
                cs: cs,
                tt: tt,
              ),
              _SheetOption(
                icon: Icons.face_rounded,
                label: 'Pick an avatar',
                onTap: () => setState(() => _showAvatarGrid = !_showAvatarGrid),
                ext: ext,
                cs: cs,
                tt: tt,
                trailing: AnimatedRotation(
                  turns: _showAvatarGrid ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.expand_more_rounded,
                      color: ext.textSecondary, size: 20),
                ),
              ),

              // Avatar grid (animated)
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 220),
                crossFadeState: _showAvatarGrid
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: const SizedBox.shrink(),
                secondChild: AvatarPickerGrid(
                  selectedId: widget.currentAvatarId,
                  onSelected: widget.onPickAvatar,
                ),
              ),

              if (widget.hasPhoto) ...[
                Divider(height: 1, color: ext.divider),
                _SheetOption(
                  icon: Icons.delete_outline_rounded,
                  label: 'Remove photo',
                  onTap: widget.onRemove,
                  ext: ext,
                  cs: cs,
                  tt: tt,
                  isDestructive: true,
                ),
              ],

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  const _SheetOption({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.ext,
    required this.cs,
    required this.tt,
    this.trailing,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final AppThemeExt ext;
  final ColorScheme cs;
  final TextTheme tt;
  final Widget? trailing;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? ext.expense : ext.textPrimary;
    final iconColor = isDestructive ? ext.expense : cs.primary;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isDestructive
                    ? ext.expense.withAlpha(22)
                    : ext.tint,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: tt.bodyMedium?.copyWith(color: color),
              ),
            ),
            ?trailing,
          ],
        ),
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
