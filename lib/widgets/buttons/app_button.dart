import 'package:flutter/material.dart';
import 'package:paysplit/theme/app_colors.dart';
import 'package:paysplit/theme/app_typography.dart';

class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.outlined = false,
    this.busy = false,
    super.key,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool outlined;
  final bool busy;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: FilledButton(
      onPressed: busy ? null : onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 50),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        textStyle: AppTypography.button,
        backgroundColor: outlined ? AppColors.white : AppColors.action,
        foregroundColor: outlined ? AppColors.action : AppColors.white,
        disabledBackgroundColor: AppColors.primaryBorder,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: outlined
            ? const BorderSide(color: AppColors.primaryBorder)
            : BorderSide.none,
        elevation: 0,
      ),
      child: busy
          ? Semantics(
              label: '$label in progress',
              child: const SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : Text(label, textAlign: TextAlign.center),
    ),
  );
}
