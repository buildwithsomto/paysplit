import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paysplit/theme/app_colors.dart';
import 'package:paysplit/theme/app_typography.dart';
import 'package:paysplit/widgets/buttons/app_text_link.dart';

/// Shown inside an editor when the server refuses the action until identity
/// verification is complete. Closes the editor and opens verification.
class VerificationNotice extends StatelessWidget {
  const VerificationNotice({required this.message, super.key});
  final String message;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    liveRegion: true,
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 4,
        children: [
          Text(message, style: AppTypography.body),
          AppTextLink(
            label: 'Complete verification',
            onPressed: () {
              final router = GoRouter.of(context);
              if (Navigator.of(context).canPop()) Navigator.of(context).pop();
              router.push('/kyc/result');
            },
          ),
        ],
      ),
    ),
  );
}
