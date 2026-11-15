import 'package:flutter/material.dart';
import 'package:paysplit/theme/app_colors.dart';
import 'package:paysplit/theme/app_typography.dart';
import 'package:paysplit/features/kyc/presentation/widgets/kyc_progress.dart';

class KycSection extends StatelessWidget {
  const KycSection({
    required this.step,
    required this.title,
    required this.description,
    required this.child,
    super.key,
  });
  final int step;
  final String title;
  final String description;
  final Widget child;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      KycProgress(step: step),
      const SizedBox(height: 24),
      Text(
        title,
        style: AppTypography.heading.copyWith(
          fontSize: 16,
          height: 28 / 16,
          color: AppColors.heading,
        ),
      ),
      const SizedBox(height: 4),
      Padding(
        padding: const EdgeInsets.only(right: 29),
        child: Text(description),
      ),
      const SizedBox(height: 32),
      child,
    ],
  );
}
