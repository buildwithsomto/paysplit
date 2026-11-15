import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paysplit/features/kyc/presentation/controllers/kyc_controller.dart';
import 'package:paysplit/features/kyc/presentation/controllers/kyc_code_controller.dart';
import 'package:paysplit/features/kyc/presentation/widgets/kyc_progress.dart';
import 'package:paysplit/theme/app_typography.dart';
import 'package:paysplit/widgets/buttons/app_button.dart';
import 'package:paysplit/widgets/buttons/app_text_link.dart';
import 'package:paysplit/widgets/inputs/app_code_field.dart';
import 'package:paysplit/widgets/layout/app_page_layout.dart';

class KycCodeScreen extends ConsumerStatefulWidget {
  const KycCodeScreen({super.key});
  @override
  ConsumerState<KycCodeScreen> createState() => _KycCodeScreenState();
}

class _KycCodeScreenState extends ConsumerState<KycCodeScreen> {
  final _code = TextEditingController();
  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _continue() {
    if (!ref.read(kycCodeProvider.notifier).verify(_code.text)) {
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    _code.clear();
    context.go('/kyc/liveness');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(kycCodeProvider);
    final controller = ref.read(kycCodeProvider.notifier);
    final document = ref.watch(kycControllerProvider.select((s) => s.document));
    return AppPageLayout(
      title: 'Profile Verification',
      backgroundColor: const Color(0xFFFBFDFF),
      onBack: () => context.go('/kyc/identity'),
      bottom: AppButton(
        label: 'Continue',
        onPressed: state.accepted ? null : _continue,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const KycProgress(step: 2),
          const SizedBox(height: 40),
          Text(
            'Verify ${KycController.documentLabel(document)}',
            style: AppTypography.heading,
          ),
          const SizedBox(height: 4),
          const Text('Enter the six-digit verification code.'),
          const SizedBox(height: 32),
          AppCodeField(
            controller: _code,
            error: state.error,
            onChanged: (_) => controller.clearError(),
            onSubmitted: (_) => _continue(),
          ),
          const SizedBox(height: 6),
          Center(
            child: AppTextLink(
              prefix: 'Didn’t get a code? ',
              regularPrefix: true,
              underline: true,
              label: state.seconds > 0
                  ? 'Resend in ${state.seconds}s'
                  : 'Click to resend.',
              onPressed: state.seconds > 0
                  ? null
                  : () {
                      if (controller.resend()) _code.clear();
                    },
            ),
          ),
        ],
      ),
    );
  }
}
