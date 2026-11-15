import 'package:flutter/material.dart';
import 'package:paysplit/theme/app_colors.dart';
import 'package:paysplit/theme/app_typography.dart';

class AppTextLink extends StatelessWidget {
  const AppTextLink({
    required this.label,
    required this.onPressed,
    this.prefix = '',
    this.underline = false,
    this.regularPrefix = false,
    super.key,
  });
  final String label;
  final String prefix;
  final VoidCallback? onPressed;
  final bool underline;
  final bool regularPrefix;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: onPressed != null,
    child: InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(6),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
        child: Center(
          widthFactor: 1,
          heightFactor: 1,
          child: Text.rich(
            TextSpan(
              style: AppTypography.label.copyWith(color: AppColors.ink),
              children: [
                TextSpan(
                  text: prefix,
                  style: regularPrefix
                      ? const TextStyle(
                          fontWeight: FontWeight.w400,
                          color: AppColors.body,
                        )
                      : null,
                ),
                TextSpan(
                  text: label,
                  style: TextStyle(
                    color: onPressed == null
                        ? AppColors.placeholder
                        : AppColors.action,
                    decoration: underline ? TextDecoration.underline : null,
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ),
  );
}
