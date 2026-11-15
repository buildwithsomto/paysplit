import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paysplit/features/kyc/presentation/controllers/kyc_controller.dart';
import 'package:paysplit/widgets/buttons/app_button.dart';
import 'package:paysplit/widgets/layout/app_page_layout.dart';
import 'package:paysplit/widgets/overlays/choice_sheet.dart';

class LivenessScreen extends ConsumerWidget {
  const LivenessScreen({super.key});

  Future<void> _previewCapture(BuildContext context, WidgetRef ref) async {
    final status = await showChoiceSheet(
      context,
      title: 'Choose a sample result',
      choices: [KycStatus.approved, KycStatus.inReview, KycStatus.rejected],
      label: (value) => value.label,
    );
    if (!context.mounted || status == null) return;
    ref.read(kycControllerProvider.notifier).previewOutcome(status);
    context.go('/kyc/result');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => AppPageLayout(
    title: '',
    onBack: () => context.go('/kyc/identity'),
    bodyGap: 20,
    bottom: AppButton(
      label: 'Use sample photo',
      onPressed: () => _previewCapture(context, ref),
    ),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 272),
        child: Column(
          children: [
            Image.asset(
              'assets/icons/kyc/8bac2.png',
              width: 272,
              height: 433,
              fit: BoxFit.contain,
              semanticLabel: 'Sample face from the design, not a live camera',
            ),
            const SizedBox(height: 34),
            const Text(
              'Face Verification',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontWeight: FontWeight.w700,
                fontSize: 22,
                height: 1.2,
                color: Color(0xFF323232),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Continue with the sample photo to review an outcome.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontWeight: FontWeight.w500,
                fontSize: 14,
                height: 1.6,
                color: Color(0xFF7C7C7C),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
