import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paysplit/features/auth/presentation/controllers/auth_controller.dart';
import 'package:paysplit/features/auth/presentation/widgets/auth_layout.dart';
import 'package:paysplit/widgets/buttons/app_back_button.dart';
import 'package:paysplit/widgets/buttons/app_button.dart';
import 'package:paysplit/widgets/inputs/app_input_field.dart';

/// Signup uses the same password form because the brief requires a password
/// although the supplied signup frame only shows name and email fields.
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

  void _submit() {
    final controller = ref.read(authControllerProvider.notifier);
    if (!controller.validatePasswords(_password.text, _confirmation.text)) {
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    _password.clear();
    _confirmation.clear();
    if (widget.creating) {
      controller.startVerification();
      context.go('/verify');
    } else {
      controller.clearErrors();
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final controller = ref.read(authControllerProvider.notifier);
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
            ? 'Create a password with at least 8 characters'
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
            AppButton(label: 'Continue', onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
