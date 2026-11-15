import 'package:flutter/material.dart';
import 'package:paysplit/core/constants/app_assets.dart';
import 'package:paysplit/theme/app_colors.dart';
import 'package:paysplit/widgets/app_svg_icon.dart';

/// A 48px hit area surrounding Figma's 44px circular button.
class AppBackButton extends StatelessWidget {
  const AppBackButton({required this.onPressed, super.key});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    button: true,
    label: 'Back',
    child: Tooltip(
      message: 'Back',
      excludeFromSemantics: true,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(24),
        child: SizedBox.square(
          dimension: 48,
          child: Align(
            alignment: Alignment.topLeft,
            child: Container(
              width: 44,
              height: 44,
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primaryBorder),
              ),
              child: const AppSvgIcon(AppAssets.arrowLeft),
            ),
          ),
        ),
      ),
    ),
  );
}
