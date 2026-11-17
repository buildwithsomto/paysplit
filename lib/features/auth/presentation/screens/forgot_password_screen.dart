import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paysplit/features/auth/presentation/controllers/auth_controller.dart';
import 'package:paysplit/features/auth/presentation/widgets/auth_layout.dart';
import 'package:paysplit/widgets/buttons/app_back_button.dart';
import 'package:paysplit/widgets/buttons/app_button.dart';
import 'package:paysplit/widgets/feedback/app_notice.dart';
import 'package:paysplit/widgets/inputs/app_input_field.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _email = TextEditingController();
  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final sent = await ref
        .read(authControllerProvider.notifier)
        .requestReset(_email.text);
    if (!mounted || !sent) return;
    context.push('/verify');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
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
            ref.read(authControllerProvider.notifier).clearErrors();
            context.go('/login');
          },
        ),
      ),
      topPadding: 22,
      titleGap: 33,
      title: 'Forgot Password',
      description: const Text('Enter your registered email to reset password'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppInputField(
            label: 'Email',
            hint: 'Enter your email',
            controller: _email,
            error: state.errors['email'],
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            onChanged: (_) =>
                ref.read(authControllerProvider.notifier).clearError('email'),
          ),
          const SizedBox(height: 40),
          AppButton(label: 'Continue', busy: state.busy, onPressed: _submit),
        ],
      ),
    );
  }
}
