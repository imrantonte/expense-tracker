import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme_ext.dart';
import '../../core/constants.dart';
import '../../data/app_state.dart';
import '../../models/managed_category.dart';
import '../../widgets/app_card.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Available icon + color palettes  (shared between screen and dialog)
// ─────────────────────────────────────────────────────────────────────────────

const _kIcons = [
  Icons.flight_rounded,
  Icons.restaurant_rounded,
  Icons.shopping_basket_rounded,
  Icons.home_rounded,
  Icons.favorite_rounded,
  Icons.directions_car_rounded,
  Icons.movie_rounded,
  Icons.school_rounded,
];

const _kColors = [
  Color(0xFF00897B), // teal
  Color(0xFFFFB300), // amber
  Color(0xFFE53935), // red
  Color(0xFF2196F3), // blue
  Color(0xFF7E57C2), // purple
  Color(0xFFEC407A), // pink
];

// ─────────────────────────────────────────────────────────────────────────────
// ManageCategoriesScreen
// ─────────────────────────────────────────────────────────────────────────────

class ManageCategoriesScreen extends StatelessWidget {
  const ManageCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExt>()!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

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
          'Manage categories',
          style: tt.titleLarge?.copyWith(
            color: ext.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: kFontScreenTitle,
          ),
        ),
      ),
      floatingActionButton: _AddCategoryFab(ext: ext, cs: cs, tt: tt),
      body: Consumer<AppState>(
        builder: (ctx, state, _) {
          final cats = state.managedCategories;
          return ListView(
            padding: const EdgeInsets.fromLTRB(kSp16, 0, kSp16, 100),
            children: [
              // Subtitle
              Text(
                'Your spending, sorted your way.',
                style: tt.bodyMedium?.copyWith(color: ext.textSecondary),
              ),
              const SizedBox(height: kSp20),

              // YOUR CATEGORIES row
              Row(
                children: [
                  Text(
                    'YOUR CATEGORIES',
                    style: tt.labelSmall?.copyWith(
                      color: ext.textSecondary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${cats.length} categories',
                    style:
                        tt.labelSmall?.copyWith(color: ext.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: kSp12),

              // Category list
              for (final cat in cats) ...[
                _CategoryCard(
                  cat: cat,
                  onEdit: () => _openDialog(context, state, existing: cat),
                  ext: ext,
                  cs: cs,
                  tt: tt,
                ),
                const SizedBox(height: kSp8),
              ],
            ],
          );
        },
      ),
    );
  }

  static void _openDialog(
    BuildContext context,
    AppState state, {
    ManagedCategory? existing,
  }) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => _CategoryDialog(
        existing: existing,
        onSave: (cat) {
          if (existing != null) {
            state.updateManagedCategory(cat);
          } else {
            state.addManagedCategory(cat);
          }
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// "+ Add Category" FAB
// ─────────────────────────────────────────────────────────────────────────────

class _AddCategoryFab extends StatelessWidget {
  const _AddCategoryFab(
      {required this.ext, required this.cs, required this.tt});
  final AppThemeExt ext;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () {
        final state = context.read<AppState>();
        ManageCategoriesScreen._openDialog(context, state);
      },
      backgroundColor: cs.primary,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadiusButton)),
      icon: const Icon(Icons.add_rounded),
      label: const Text(
        'Add Category',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual category card row
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.cat,
    required this.onEdit,
    required this.ext,
    required this.cs,
    required this.tt,
  });
  final ManagedCategory cat;
  final VoidCallback onEdit;
  final AppThemeExt ext;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          // Icon badge
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: cat.color.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(cat.icon, color: cat.color, size: 24),
          ),
          const SizedBox(width: kSp12),

          // Name + description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  cat.name,
                  style: tt.bodyMedium?.copyWith(
                    color: ext.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (cat.description.isNotEmpty) ...[
                  const SizedBox(height: kSp2),
                  Text(
                    cat.description,
                    style: tt.bodySmall?.copyWith(color: ext.textSecondary),
                  ),
                ],
              ],
            ),
          ),

          // Color dot
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
                color: cat.color, shape: BoxShape.circle),
          ),
          const SizedBox(width: kSp12),

          // Edit icon
          GestureDetector(
            onTap: onEdit,
            child: Icon(Icons.edit_outlined, color: ext.textSecondary, size: 20),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add / Edit Category dialog
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryDialog extends StatefulWidget {
  const _CategoryDialog({this.existing, required this.onSave});
  final ManagedCategory? existing;
  final ValueChanged<ManagedCategory> onSave;

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  late final TextEditingController _nameCtrl;
  late IconData _selectedIcon;
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    final ex = widget.existing;
    _nameCtrl = TextEditingController(text: ex?.name ?? '');
    _selectedIcon = ex?.icon ?? _kIcons[0];
    _selectedColor = ex?.color ?? _kColors[0];
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
        const SnackBar(content: Text('Please enter a category name.')),
      );
      return;
    }
    final cat = ManagedCategory(
      id: widget.existing?.id ??
          'mc_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      icon: _selectedIcon,
      color: _selectedColor,
      description: widget.existing?.description ?? '',
    );
    widget.onSave(cat);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExt>()!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: ext.cardBackground,
      insetPadding:
          const EdgeInsets.symmetric(horizontal: kSp20, vertical: 40),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(kSp20, kSp24, kSp20, kSp16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Title ─────────────────────────────────────────────────
            Text(
              widget.existing != null ? 'Edit Category' : 'Add Category',
              style: tt.titleLarge?.copyWith(
                color: ext.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: kSp4),
            Text(
              'Give your spending a new home.',
              style: tt.bodySmall?.copyWith(color: ext.textSecondary),
            ),
            const SizedBox(height: kSp16),

            // ── Name field ────────────────────────────────────────────
            TextField(
              controller: _nameCtrl,
              onChanged: (_) => setState(() {}),
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Category name',
                floatingLabelStyle:
                    TextStyle(color: cs.primary, fontSize: 13),
              ),
            ),
            const SizedBox(height: kSp20),

            // ── Choose an icon ────────────────────────────────────────
            Row(
              children: [
                Text(
                  'Choose an icon',
                  style: tt.bodyMedium?.copyWith(
                    color: ext.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                if (_nameCtrl.text.isNotEmpty)
                  Text(
                    _nameCtrl.text,
                    style: tt.bodySmall
                        ?.copyWith(color: ext.textSecondary),
                  ),
              ],
            ),
            const SizedBox(height: kSp10),

            // 4 × 2 icon grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _kIcons.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: kSp8,
                crossAxisSpacing: kSp8,
                childAspectRatio: 1,
              ),
              itemBuilder: (_, i) {
                final icon = _kIcons[i];
                final sel = icon == _selectedIcon;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIcon = icon),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    decoration: BoxDecoration(
                      color: sel
                          ? cs.primary.withAlpha(22)
                          : ext.cardBackground,
                      borderRadius: BorderRadius.circular(kSp12),
                      border: Border.all(
                        color: sel ? cs.primary : ext.cardBorder,
                        width: sel ? 1.5 : 1,
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: sel ? cs.primary : ext.textSecondary,
                      size: 24,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: kSp20),

            // ── Choose a color ────────────────────────────────────────
            Text(
              'Choose a color',
              style: tt.bodyMedium?.copyWith(
                color: ext.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: kSp10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _kColors.map((color) {
                final sel = color == _selectedColor;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: sel
                          ? Border.all(color: Colors.white, width: 2)
                          : null,
                    ),
                    child: sel
                        ? const Icon(Icons.check_rounded,
                            color: Colors.white, size: 18)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: kSp24),

            // ── Buttons ───────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: cs.primary,
                    ),
                    child: const Text('Cancel',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: kSp12),
                Expanded(
                  child: FilledButton(
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(kRadiusButton)),
                    ),
                    child: const Text('Save',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

