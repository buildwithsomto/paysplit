import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paysplit/features/auth/presentation/controllers/account_controller.dart';
import 'package:paysplit/widgets/buttons/app_button.dart';
import 'package:paysplit/widgets/layout/onboarding_result_layout.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(
      accountControllerProvider.select((state) => state.firstName),
    );
    return OnboardingResultLayout(
      title: name.isEmpty
          ? 'Welcome to PaySplit'
          : 'Welcome to PaySplit, $name',
      description: 'Set up your profile and salary details to get started.',
      bottom: Row(
        spacing: 16,
        children: [
          Expanded(
            child: AppButton(
              label: 'Go to Dashboard',
              outlined: true,
              onPressed: () => context.go('/home'),
            ),
          ),
          Expanded(
            child: AppButton(
              label: 'Continue to KYC',
              onPressed: () => context.go('/kyc'),
            ),
          ),
        ],
      ),
    );
  }
}
