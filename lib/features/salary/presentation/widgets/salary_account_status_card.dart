import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paysplit/core/presentation/content_phase.dart';
import 'package:paysplit/features/auth/presentation/controllers/account_controller.dart';
import 'package:paysplit/features/salary/data/models/salary_account.dart';
import 'package:paysplit/features/salary/presentation/controllers/salary_account_controller.dart';
import 'package:paysplit/theme/app_colors.dart';
import 'package:paysplit/theme/app_typography.dart';
import 'package:paysplit/widgets/buttons/app_button.dart';
import 'package:paysplit/widgets/feedback/app_notice.dart';
import 'package:paysplit/widgets/inputs/app_input_field.dart';
import 'package:paysplit/widgets/inputs/app_select_field.dart';
import 'package:paysplit/widgets/overlays/choice_sheet.dart';

/// Explains where a salary account that is not yet usable stands, and offers
/// the one action that moves it forward. Renders nothing for an active account.
class SalaryAccountStatusCard extends ConsumerStatefulWidget {
  const SalaryAccountStatusCard({this.compact = false, super.key});

  /// The dashboard shows the status and a link; the account screen shows the
  /// full explanation and the action.
  final bool compact;

  @override
  ConsumerState<SalaryAccountStatusCard> createState() =>
      _SalaryAccountStatusCardState();
}

class _SalaryAccountStatusCardState
    extends ConsumerState<SalaryAccountStatusCard> {
  final _idNumber = TextEditingController();

  @override
  void dispose() {
    _idNumber.dispose();
    super.dispose();
  }

  Future<void> _submitId() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final added = await ref
        .read(salaryAccountProvider.notifier)
        .addIdentity(_idNumber.text);
    if (!mounted || !added) return;
    _idNumber.clear();
    showAppNotice(context, 'Thanks. We’re setting up your salary account.');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(salaryAccountProvider);
    final account = state.account;
    if (account == null || account.isActive) return const SizedBox.shrink();
    final controller = ref.read(salaryAccountProvider.notifier);
    final approved = ref.watch(onboardingProvider.select((o) => o.kycApproved));
    ref.listen(salaryAccountProvider.select((s) => s.errors['form']), (
      previous,
      next,
    ) {
      if (next != null) showAppNotice(context, next);
    });

    final needsId = account.needsNigerianId;
    final (title, message) = switch (account.phase) {
      _ when needsId => (
        'Add your BVN or NIN',
        'Our banking partner needs a Nigerian ID to issue your salary account.',
      ),
      SalaryAccountPhase.notIssued when !approved => (
        'Verify your identity first',
        'Your salary account number is created as soon as your identity is approved.',
      ),
      SalaryAccountPhase.notIssued || SalaryAccountPhase.pending => (
        'Setting up your salary account',
        'This usually takes a few minutes. Your account number will appear here once it’s ready.',
      ),
      SalaryAccountPhase.failed => (
        'We couldn’t set up your account',
        'Something went wrong while creating your salary account. Please check again shortly.',
      ),
      SalaryAccountPhase.closed => (
        'This salary account is closed',
        'It can no longer receive salary. Contact support if you think this is a mistake.',
      ),
      SalaryAccountPhase.active => ('', ''),
    };
    final refreshing = state.phase == ContentPhase.refreshing;

    return Semantics(
      container: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border.all(color: AppColors.primaryBorder),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 12,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    switch (account.phase) {
                      SalaryAccountPhase.failed ||
                      SalaryAccountPhase.closed => Icons.error_outline_rounded,
                      _ when needsId || !approved =>
                        Icons.verified_user_outlined,
                      _ => Icons.hourglass_top_rounded,
                    },
                    size: 20,
                    color: AppColors.action,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 4,
                    children: [
                      Text(
                        title,
                        style: AppTypography.heading.copyWith(
                          fontSize: 16,
                          height: 24 / 16,
                          color: AppColors.heading,
                        ),
                      ),
                      Text(message, style: AppTypography.body),
                    ],
                  ),
                ),
              ],
            ),
            if (widget.compact) ...[
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.push('/salary-account'),
                  child: const Text('View details'),
                ),
              ),
            ] else if (needsId) ...[
              const SizedBox(height: 16),
              AppSelectField(
                label: 'ID Type',
                value: state.method.label,
                onPressed: () async {
                  FocusManager.instance.primaryFocus?.unfocus();
                  final method = await showChoiceSheet(
                    context,
                    title: 'ID Type',
                    choices: SalaryIdentityMethod.values,
                    selected: state.method,
                    label: (value) => value.label,
                  );
                  if (method != null) controller.selectMethod(method);
                },
              ),
              const SizedBox(height: 16),
              AppInputField(
                label: state.method.label,
                controller: _idNumber,
                hint: '11-digit number',
                error: state.errors['idNumber'],
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submitId(),
                onChanged: (_) => controller.clearErrors(),
              ),
              const SizedBox(height: 16),
              AppButton(
                label: 'Submit',
                busy: state.busy,
                onPressed: _submitId,
              ),
            ] else if (account.phase != SalaryAccountPhase.closed) ...[
              const SizedBox(height: 16),
              if (account.phase == SalaryAccountPhase.notIssued && !approved)
                AppButton(
                  label: 'Complete Verification',
                  onPressed: () => context.push('/kyc/result'),
                )
              else
                AppButton(
                  label: 'Check Again',
                  outlined: true,
                  busy: refreshing,
                  onPressed: controller.load,
                ),
            ],
          ],
        ),
      ),
    );
  }
}
