import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paysplit/core/constants/app_assets.dart';
import 'package:paysplit/features/auth/presentation/controllers/auth_controller.dart';
import 'package:paysplit/features/auth/presentation/widgets/auth_layout.dart';
import 'package:paysplit/theme/app_colors.dart';
import 'package:paysplit/widgets/app_svg_icon.dart';
import 'package:paysplit/widgets/buttons/app_button.dart';
import 'package:paysplit/widgets/buttons/app_text_link.dart';
import 'package:paysplit/widgets/feedback/preview_notice.dart';
import 'package:paysplit/widgets/inputs/app_input_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!ref
        .read(authControllerProvider.notifier)
        .validateLogin(_email.text, _password.text)) {
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    _password.clear();
    context.go('/home');
  }

  void _open(String path) {
    ref.read(authControllerProvider.notifier).clearErrors();
    context.push(path);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final controller = ref.read(authControllerProvider.notifier);
    return AuthLayout(
      topPadding: 42,
      title: 'Welcome back!',
      description: const Text('Enter your email and password to log in.'),
      footer: AppTextLink(
        label: 'Switch Account',
        onPressed: () {
          _email.clear();
          _password.clear();
          controller.reset();
          showPreviewNotice(context, 'Enter the details for another account.');
        },
      ),
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppInputField(
              label: 'Email',
              hint: 'Enter your email',
              controller: _email,
              error: state.errors['email'],
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.username],
              onChanged: (_) => controller.clearError('email'),
            ),
            const SizedBox(height: 16),
            AppInputField(
              label: 'Password',
              controller: _password,
              password: true,
              labelGap: 6,
              error: state.errors['password'],
              autofillHints: const [AutofillHints.password],
              onChanged: (_) => controller.clearError('password'),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: AppTextLink(
                label: 'Forgot password',
                onPressed: () => _open('/forgot-password'),
              ),
            ),
            const SizedBox(height: 26),
            AppButton(label: 'Login', onPressed: _submit),
            const SizedBox(height: 10),
            Center(
              child: AppTextLink(
                prefix: 'Don’t have an account? ',
                label: 'Sign Up',
                regularPrefix: true,
                onPressed: () => _open('/signup'),
              ),
            ),
            const SizedBox(height: 22),
            Center(
              child: IconButton(
                tooltip: 'Biometric sign-in',
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primaryLight,
                  minimumSize: const Size.square(44),
                  padding: const EdgeInsets.all(10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => showPreviewNotice(
                  context,
                  'Biometric sign-in will be available after account integration.',
                ),
                icon: const AppSvgIcon(AppAssets.scan),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
