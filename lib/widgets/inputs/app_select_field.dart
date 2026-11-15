import 'package:flutter/material.dart';
import 'package:paysplit/theme/app_colors.dart';
import 'package:paysplit/theme/app_typography.dart';
import 'package:paysplit/widgets/app_svg_icon.dart';

class AppSelectField extends StatelessWidget {
  const AppSelectField({
    required this.onPressed,
    this.label,
    this.value,
    this.hint = 'Select',
    this.error,
    this.arrowAsset = 'assets/icons/kyc/f26f0.svg',
    super.key,
  });
  final VoidCallback onPressed;
  final String? label;
  final String? value;
  final String hint;
  final String? error;
  final String arrowAsset;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (label case final label?) ...[
        Text(label, style: AppTypography.label),
        const SizedBox(height: 8),
      ],
      Semantics(
        button: true,
        label: label,
        child: Material(
          color: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: error == null ? AppColors.border : AppColors.error,
            ),
          ),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 50),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  spacing: 8,
                  children: [
                    Expanded(
                      child: Text(
                        value ?? hint,
                        style: AppTypography.input.copyWith(
                          color: value == null
                              ? AppColors.placeholder
                              : AppColors.ink,
                        ),
                      ),
                    ),
                    AppSvgIcon(arrowAsset),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      if (error case final error?) ...[
        const SizedBox(height: 6),
        Text(error, style: AppTypography.body.copyWith(color: AppColors.error)),
      ],
    ],
  );
}
