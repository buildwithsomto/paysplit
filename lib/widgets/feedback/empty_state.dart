import 'package:flutter/material.dart';
import 'package:paysplit/theme/app_colors.dart';
import 'package:paysplit/widgets/app_svg_icon.dart';

/// The design's empty-list treatment: the list illustration, a title and an
/// optional line saying what will show up here.
class EmptyState extends StatelessWidget {
  const EmptyState({required this.title, this.message, super.key});
  final String title;
  final String? message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AppSvgIcon(
          'assets/icons/history/b98c5.svg',
          width: 103,
          height: 66,
        ),
        const SizedBox(height: 20),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            height: 1.2,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
        if (message case final message?) ...[
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 20 / 14,
              color: AppColors.body,
            ),
          ),
        ],
      ],
    ),
  );
}
