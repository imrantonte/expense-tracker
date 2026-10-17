import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme_ext.dart';
import '../../core/constants.dart';
import '../../data/app_state.dart';

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

  void _save() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot be empty.')),
      );
      return;
    }
    final state = context.read<AppState>();
    state.updateProfile(state.profile.copyWith(name: name));
    Navigator.pop(context);
  }

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
      body: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              behavior: HitTestBehavior.opaque,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(kSp16, 0, kSp16, 24),
                children: [
                  // Subtitle
                  Text(
                    'A few details. A more personal money journey.',
                    style:
                        tt.bodyMedium?.copyWith(color: ext.textSecondary),
                  ),
                  const SizedBox(height: kSp20),

                  // ── Avatar card ──────────────────────────────────────────
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
                            crossAxisAlignment: CrossAxisAlignment.start,
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

                  // ── Name field ───────────────────────────────────────────
                  TextField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                    ),
                  ),
                  const SizedBox(height: kSp16),
                ],
              ),
            ),
          ),

          // ── Save pill ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(kSp16, 0, kSp16, kSp24),
            child: SizedBox(
              width: double.infinity,
              height: kButtonHeight,
              child: FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(kRadiusButton)),
                ),
                child: const Text('Save',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
