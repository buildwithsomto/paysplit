import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:paysplit/features/kyc/presentation/controllers/kyc_controller.dart';
import 'package:paysplit/features/salary/presentation/controllers/salary_account_controller.dart';
import 'package:paysplit/theme/app_colors.dart';

class SalaryAccountStatusCard extends ConsumerWidget {
  const SalaryAccountStatusCard({this.compact = false, super.key});
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(salaryAccountProvider);
    final approved = ref.watch(
      kycControllerProvider.select((s) => s.status == KycStatus.approved),
    );
    final awaited = state.expectedSalaryDate != null;
    if (state.status == SalaryAccountStatus.ready && !awaited) {
      return const SizedBox.shrink();
    }
    final title = awaited ? 'Salary still awaited' : state.status.label;
    final message = awaited
        ? 'Salary expected on ${DateFormat.yMMMd().format(state.expectedSalaryDate!)} has not been confirmed in this sample. The expected date does not trigger a split. Check with payroll if the payment is delayed.'
        : switch (state.status) {
            SalaryAccountStatus.notProvisioned =>
              approved
                  ? 'Verification alone does not create an account. Your dedicated account details will appear after the provider confirms eligibility and account setup. Provider integration is pending.'
                  : 'Complete verification to request a dedicated salary account.',
            SalaryAccountStatus.pending =>
              'Account setup is awaiting the provider’s confirmation. No account details are available yet. Check the existing request status before submitting another request.',
            SalaryAccountStatus.failed =>
              'Account setup was not completed in this sample. No provider reason or permission to resubmit is available. Review the latest status before trying again.',
            SalaryAccountStatus.providerUnavailable =>
              'The account provider cannot be reached in this sample. This does not confirm that account setup failed. Check again later; do not submit a duplicate request.',
            SalaryAccountStatus.ready => '',
          };
    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          border: Border.all(color: AppColors.primaryBorder),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            if (state.preview)
              const Text(
                'ACCOUNT STATUS PREVIEW · SIMULATED',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.action,
              ),
            ),
            Text(message),
            if (compact)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => context.push('/salary-account'),
                  child: const Text('View account status'),
                ),
              )
            else ...[
              if (state.checking)
                const Row(
                  spacing: 12,
                  children: [
                    SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    Expanded(child: Text('Checking sample status…')),
                  ],
                ),
              if (state.checked)
                const Text(
                  'No change in the sample status. No provider request was made, and no funds were received or moved.',
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: state.checking
                      ? null
                      : state.preview
                      ? ref.read(salaryAccountProvider.notifier).checkPreview
                      : approved
                      ? null
                      : () => context.push('/kyc/result'),
                  child: Text(
                    state.preview
                        ? 'Check sample status'
                        : approved
                        ? 'Awaiting provider integration'
                        : 'Review verification',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
