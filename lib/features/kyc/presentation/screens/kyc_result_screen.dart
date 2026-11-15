import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paysplit/features/kyc/presentation/controllers/kyc_controller.dart';
import 'package:paysplit/theme/app_typography.dart';
import 'package:paysplit/widgets/buttons/app_button.dart';
import 'package:paysplit/widgets/buttons/app_text_link.dart';
import 'package:paysplit/widgets/layout/app_page_layout.dart';
import 'package:paysplit/widgets/layout/onboarding_result_layout.dart';

class KycResultScreen extends ConsumerWidget {
  const KycResultScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(kycControllerProvider);
    final status = state.status;
    final document = switch (state.document) {
      IdentityDocument.bvn => 'BVN',
      IdentityDocument.nin => 'NIN',
      _ => 'identity document',
    };
    if (status == KycStatus.approved) {
      return OnboardingResultLayout(
        title: 'Identity Approved',
        secondStepActive: true,
        description: 'Your sample $document and face check are complete.',
        bottom: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextLink(label: 'Skip', onPressed: () => context.go('/home')),
            AppButton(
              label: 'Continue to Setup Checklist',
              onPressed: () {
                final router = GoRouter.of(context);
                router.go('/home');
                router.push('/setup/progress');
              },
            ),
          ],
        ),
      );
    }
    final (title, message) = switch (status) {
      KycStatus.inReview => (
        'Verification in review',
        'Your identity details are being reviewed. You can continue exploring PaySplit.',
      ),
      KycStatus.inProgress => (
        'Verification in progress',
        'Your profile is started. Continue the remaining identity and liveness steps; financial actions stay restricted until approval.',
      ),
      KycStatus.actionRequired => (
        'Action required',
        'Review your identity details before continuing.',
      ),
      KycStatus.rejected => (
        'Verification rejected',
        'Verification was unsuccessful. Review the verification steps.',
      ),
      KycStatus.reverificationRequired => (
        'Re-verification required',
        'Your identity needs to be checked again. Previous approval no longer permits financial actions. Review the verification steps to continue.',
      ),
      _ => (
        'Complete your verification',
        'Verify your identity before setting up your salary account.',
      ),
    };
    return AppPageLayout(
      title: 'Profile Verification',
      onBack: () => context.go('/home'),
      bottom: AppButton(
        label: switch (status) {
          KycStatus.inReview => 'Go to Dashboard',
          KycStatus.unverified => 'Start Verification',
          KycStatus.inProgress => 'Continue Verification',
          _ => 'Review Verification Steps',
        },
        onPressed: () => context.go(switch (status) {
          KycStatus.inReview => '/home',
          KycStatus.inProgress => '/kyc/identity',
          _ => '/kyc',
        }),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 48),
          Text(title, style: AppTypography.title),
          const SizedBox(height: 16),
          Text(message),
        ],
      ),
    );
  }
}
