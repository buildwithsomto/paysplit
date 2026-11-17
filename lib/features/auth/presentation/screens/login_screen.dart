import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paysplit/core/constants/app_assets.dart';
import 'package:paysplit/core/session/session_providers.dart';
import 'package:paysplit/features/auth/presentation/controllers/auth_controller.dart';
import 'package:paysplit/features/auth/presentation/widgets/auth_layout.dart';
import 'package:paysplit/theme/app_colors.dart';
import 'package:paysplit/widgets/app_svg_icon.dart';
import 'package:paysplit/widgets/buttons/app_button.dart';
import 'package:paysplit/widgets/buttons/app_text_link.dart';
import 'package:paysplit/widgets/feedback/app_notice.dart';
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
  void initState() {
    super.initState();
    _email.text = ref.read(authControllerProvider).email;
    if (ref.read(sessionControllerProvider).expired) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          showAppNotice(
            context,
            'Your session has ended. Please log in again.',
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final next = await ref
        .read(authControllerProvider.notifier)
        .login(_email.text, _password.text);
    if (!mounted || next == null) return;
    _password.clear();
    if (next == AuthNext.verifyEmail) {
      showAppNotice(
        context,
        'Finish creating your account. We’ve emailed you a new code.',
      );
      context.push('/verify');
    } else {
      context.go('/home');
    }
  }

  void _open(String path) {
    ref.read(authControllerProvider.notifier).clearErrors();
    context.push(path);
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
      topPadding: 42,
      title: 'Welcome back!',
      description: const Text('Enter your email and password to log in.'),
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
            AppButton(label: 'Login', busy: state.busy, onPressed: _submit),
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
                onPressed: () => showAppNotice(
                  context,
                  'Biometric sign-in isn’t available yet. Log in with your password.',
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
