import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paysplit/features/auth/presentation/controllers/auth_controller.dart';
import 'package:paysplit/features/auth/presentation/widgets/auth_layout.dart';
import 'package:paysplit/theme/app_colors.dart';
import 'package:paysplit/widgets/buttons/app_back_button.dart';
import 'package:paysplit/widgets/buttons/app_button.dart';
import 'package:paysplit/widgets/buttons/app_text_link.dart';
import 'package:paysplit/widgets/feedback/app_notice.dart';
import 'package:paysplit/widgets/inputs/app_code_field.dart';

class VerificationScreen extends ConsumerStatefulWidget {
  const VerificationScreen({super.key});
  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> {
  final _code = TextEditingController();
  late final AppLifecycleListener _lifecycle;
  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () {
        ref.read(authControllerProvider.notifier).refreshCooldown();
      },
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final recovery =
        ref.read(authControllerProvider).purpose ==
        VerificationPurpose.recovery;
    final verified = await ref
        .read(authControllerProvider.notifier)
        .verify(_code.text);
    if (!mounted || !verified) return;
    _code.clear();
    context.go(recovery ? '/reset-password' : '/signup/password');
  }

  Future<void> _resend() async {
    final sent = await ref.read(authControllerProvider.notifier).resendCode();
    if (!mounted || !sent) return;
    _code.clear();
    showAppNotice(context, 'We’ve sent a new code to your email.');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final controller = ref.read(authControllerProvider.notifier);
    final recovery = state.purpose == VerificationPurpose.recovery;
    ref.listen(authControllerProvider.select((s) => s.errors['form']), (
      previous,
      next,
    ) {
      if (next != null) showAppNotice(context, next);
    });
    return AuthLayout(
      header: Align(
        alignment: Alignment.centerLeft,
        child: AppBackButton(
          onPressed: () {
            controller.clearErrors();
            context.go(recovery ? '/forgot-password' : '/signup');
          },
        ),
      ),
      topPadding: recovery ? 22 : 20,
      titleGap: recovery ? 33 : 20,
      formGap: 63,
      largeTitle: true,
      title: 'Enter verification code',
      description: Text.rich(
        TextSpan(
          children: [
            const TextSpan(text: 'Enter the six-digit code for '),
            TextSpan(
              text: state.email.isEmpty ? 'your email address' : state.email,
              style: const TextStyle(
                color: AppColors.action,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppCodeField(
            controller: _code,
            error: state.errors['code'],
            onChanged: (_) => controller.clearError('code'),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 6),
          Center(
            child: AppTextLink(
              prefix: 'Didn’t get a code? ',
              regularPrefix: true,
              underline: true,
              label: state.resendSeconds > 0
                  ? 'Resend in ${state.resendSeconds}s'
                  : 'Click to resend.',
              onPressed: state.resendSeconds > 0 || state.busy ? null : _resend,
            ),
          ),
          const SizedBox(height: 86),
          AppButton(
            label: recovery ? 'Verify Code' : 'Verify Email',
            busy: state.busy,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
