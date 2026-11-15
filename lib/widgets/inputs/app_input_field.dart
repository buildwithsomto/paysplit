import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:paysplit/core/constants/app_assets.dart';
import 'package:paysplit/theme/app_colors.dart';
import 'package:paysplit/theme/app_typography.dart';
import 'package:paysplit/widgets/app_svg_icon.dart';

class AppInputField extends StatefulWidget {
  const AppInputField({
    required this.label,
    required this.controller,
    this.hint,
    this.prefix,
    this.error,
    this.password = false,
    this.keyboardType,
    this.autofillHints,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction = TextInputAction.next,
    this.inputFormatters,
    this.labelGap = 8,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    super.key,
  });
  final String label;
  final TextEditingController controller;
  final String? hint;
  final Widget? prefix;
  final String? error;
  final bool password;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final double labelGap;
  final bool enabled;
  final bool readOnly;
  final int maxLines;

  @override
  State<AppInputField> createState() => _AppInputFieldState();
}

class _AppInputFieldState extends State<AppInputField> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(widget.label, style: AppTypography.label),
      SizedBox(height: widget.labelGap),
      Semantics(
        label: widget.label,
        child: TextField(
          controller: widget.controller,
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          maxLines: widget.password ? 1 : widget.maxLines,
          style: AppTypography.input,
          obscureText: widget.password && !_visible,
          enableSuggestions: !widget.password,
          autocorrect:
              !widget.password &&
              widget.keyboardType != TextInputType.emailAddress,
          keyboardType: widget.keyboardType,
          autofillHints: widget.autofillHints,
          textInputAction: widget.textInputAction,
          inputFormatters: widget.inputFormatters,
          onChanged: widget.onChanged,
          onSubmitted: widget.onSubmitted,
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: widget.prefix,
            prefixIconConstraints: const BoxConstraints(minHeight: 48),
            hintStyle: AppTypography.input.copyWith(
              color: AppColors.placeholder,
            ),
            errorText: widget.error,
            errorMaxLines: 3,
            isDense: true,
            filled: true,
            fillColor: AppColors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
            border: _border(AppColors.border),
            enabledBorder: _border(AppColors.border),
            focusedBorder: _border(AppColors.action),
            errorBorder: _border(AppColors.error),
            focusedErrorBorder: _border(AppColors.error),
            suffixIconConstraints: const BoxConstraints(
              minHeight: 48,
              minWidth: 48,
            ),
            suffixIcon: widget.password
                ? IconButton(
                    tooltip: _visible ? 'Hide password' : 'Show password',
                    onPressed: () => setState(() => _visible = !_visible),
                    icon: const AppSvgIcon(AppAssets.eye),
                  )
                : null,
          ),
        ),
      ),
    ],
  );

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: color),
  );
}
