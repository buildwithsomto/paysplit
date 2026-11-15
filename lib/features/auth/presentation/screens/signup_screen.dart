import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paysplit/features/auth/presentation/controllers/auth_controller.dart';
import 'package:paysplit/features/auth/presentation/widgets/auth_layout.dart';
import 'package:paysplit/widgets/buttons/app_back_button.dart';
import 'package:paysplit/widgets/buttons/app_button.dart';
import 'package:paysplit/widgets/buttons/app_text_link.dart';
import 'package:paysplit/widgets/inputs/app_input_field.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});
  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    super.dispose();
  }

  void _submit() {
    if (!ref
        .read(authControllerProvider.notifier)
        .validateSignup(_firstName.text, _lastName.text, _email.text)) {
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    context.push('/signup/password');
  }

  void _login() {
    ref.read(authControllerProvider.notifier).clearErrors();
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final errors = ref.watch(authControllerProvider).errors;
    final controller = ref.read(authControllerProvider.notifier);
    return AuthLayout(
      header: Align(
        alignment: Alignment.centerLeft,
        child: AppBackButton(onPressed: _login),
      ),
      titleGap: 20,
      largeTitle: true,
      formGap: 32,
      title: 'Create Account',
      description: const Text('Enter your details, to create your account'),
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppInputField(
              label: 'First Name',
              hint: 'e.g John',
              controller: _firstName,
              error: errors['firstName'],
              autofillHints: const [AutofillHints.givenName],
              onChanged: (_) => controller.clearError('firstName'),
            ),
            const SizedBox(height: 16),
            AppInputField(
              label: 'Last Name',
              hint: 'e.g John',
              controller: _lastName,
              error: errors['lastName'],
              autofillHints: const [AutofillHints.familyName],
              onChanged: (_) => controller.clearError('lastName'),
            ),
            const SizedBox(height: 16),
            AppInputField(
              label: 'Email Address',
              hint: 'e.g John@gmail.com',
              controller: _email,
              error: errors['email'],
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              onChanged: (_) => controller.clearError('email'),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 26),
            AppButton(label: 'Sign Up', onPressed: _submit),
            const SizedBox(height: 10),
            Center(
              child: AppTextLink(
                prefix: 'Already have an account? ',
                label: 'Login',
                regularPrefix: true,
                onPressed: _login,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
