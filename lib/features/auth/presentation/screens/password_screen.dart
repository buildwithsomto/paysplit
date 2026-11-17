import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paysplit/features/auth/presentation/controllers/auth_controller.dart';
import 'package:paysplit/features/auth/presentation/widgets/auth_layout.dart';
import 'package:paysplit/widgets/buttons/app_back_button.dart';
import 'package:paysplit/widgets/buttons/app_button.dart';
import 'package:paysplit/widgets/feedback/app_notice.dart';
import 'package:paysplit/widgets/inputs/app_input_field.dart';

/// One form for both password steps: creating it after the signup email is
/// verified, and choosing a new one after a reset code is verified.
class PasswordScreen extends ConsumerStatefulWidget {
  const PasswordScreen({this.creating = false, super.key});
  final bool creating;
  @override
  ConsumerState<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends ConsumerState<PasswordScreen> {
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  @override
  void dispose() {
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final controller = ref.read(authControllerProvider.notifier);
    final saved = await (widget.creating
        ? controller.createPassword(_password.text, _confirmation.text)
        : controller.resetPassword(_password.text, _confirmation.text));
    if (!mounted || !saved) return;
    _password.clear();
    _confirmation.clear();
    if (widget.creating) {
      context.go('/welcome');
    } else {
      showAppNotice(
        context,
        'Password updated. Log in with your new password.',
      );
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final controller = ref.read(authControllerProvider.notifier);
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
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(widget.creating ? '/signup' : '/forgot-password');
            }
          },
        ),
      ),
      topPadding: 22,
      titleGap: 33,
      title: widget.creating ? 'Create Password' : 'Reset Password',
      description: Text(
        widget.creating
            ? 'Use 8+ characters with upper and lower case, a number and a symbol'
            : 'Kindly enter your new password',
      ),
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppInputField(
              label: 'Password',
              controller: _password,
              password: true,
              labelGap: 6,
              error: state.errors['password'],
              autofillHints: const [AutofillHints.newPassword],
              onChanged: (_) => controller.clearError('password'),
            ),
            const SizedBox(height: 20),
            AppInputField(
              label: 'Confirm Password',
              controller: _confirmation,
              password: true,
              labelGap: 6,
              error: state.errors['confirmation'],
              autofillHints: const [AutofillHints.newPassword],
              onChanged: (_) => controller.clearError('confirmation'),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 40),
            AppButton(label: 'Continue', busy: state.busy, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
