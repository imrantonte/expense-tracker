import 'package:flutter/material.dart';
import '../core/constants.dart';

/// A styled text field matching the design spec:
/// - Height ~56 dp (via contentPadding + constraints)
/// - Radius 16
/// - White fill, 1 px border
/// - Teal 1.5 px border on focus
/// - Optional eye-icon toggle for passwords
///
/// All colours come from [Theme.of(context).inputDecorationTheme].
///
/// ```dart
/// AppTextField(
///   label: 'Email',
///   controller: _emailCtrl,
/// )
///
/// AppTextField.password(
///   label: 'Password',
///   controller: _passCtrl,
/// )
/// ```
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.prefixIcon,
    this.obscureText = false,
    this.enabled = true,
    this.autofocus = false,
    this.maxLines = 1,
    this.hint,
  });

  /// Convenience constructor for password fields — adds an eye toggle.
  const AppTextField.password({
    super.key,
    required this.label,
    this.controller,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.prefixIcon,
    this.enabled = true,
    this.autofocus = false,
    this.hint,
  })  : obscureText = true,
        keyboardType = TextInputType.visiblePassword,
        maxLines = 1;

  final String label;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;
  final IconData? prefixIcon;
  final bool obscureText;
  final bool enabled;
  final bool autofocus;
  final int maxLines;
  final String? hint;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscure;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
      validator: widget.validator,
      obscureText: _obscure,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      maxLines: widget.maxLines,
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        prefixIcon: widget.prefixIcon != null
            ? Icon(widget.prefixIcon, size: 20)
            : null,
        // Constrain to ~56 dp via minHeight
        constraints: const BoxConstraints(minHeight: kFieldHeight),
        suffixIcon: widget.obscureText
            ? IconButton(
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
                tooltip: _obscure ? 'Show password' : 'Hide password',
              )
            : null,
      ),
    );
  }
}
