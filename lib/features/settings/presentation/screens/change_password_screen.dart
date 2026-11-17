import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paysplit/features/settings/presentation/controllers/change_password_controller.dart';
import 'package:paysplit/widgets/buttons/app_button.dart';
import 'package:paysplit/widgets/feedback/app_notice.dart';
import 'package:paysplit/widgets/inputs/app_input_field.dart';
import 'package:paysplit/widgets/layout/app_page_layout.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});
  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _current = TextEditingController();
  final _next = TextEditingController();

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final changed = await ref
        .read(changePasswordProvider.notifier)
        .submit(_current.text, _next.text);
    if (!mounted || !changed) return;
    _current.clear();
    _next.clear();
    showAppNotice(
      context,
      'Password changed. Your other devices have been signed out.',
    );
    context.canPop() ? context.pop() : context.go('/profile');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(changePasswordProvider);
    final controller = ref.read(changePasswordProvider.notifier);
    ref.listen(changePasswordProvider.select((s) => s.errors['form']), (
      previous,
      next,
    ) {
      if (next != null) showAppNotice(context, next);
    });
    return AppPageLayout(
      title: 'Password',
      headerTop: 17,
      bodyGap: 35,
      onBack: () => context.canPop() ? context.pop() : context.go('/profile'),
      bottom: AppButton(
        label: 'Change Password',
        busy: state.busy,
        onPressed: _submit,
      ),
      child: AutofillGroup(
        onDisposeAction: AutofillContextAction.cancel,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppInputField(
              label: 'Current Password',
              labelGap: 6,
              controller: _current,
              password: true,
              error: state.errors['current'],
              autofillHints: const [AutofillHints.password],
              onChanged: (_) => controller.clearError('current'),
            ),
            const SizedBox(height: 20),
            AppInputField(
              label: 'New Password',
              labelGap: 6,
              controller: _next,
              password: true,
              error: state.errors['next'],
              autofillHints: const [AutofillHints.newPassword],
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              onChanged: (_) => controller.clearError('next'),
            ),
            // The field's own error says the same thing once it is showing.
            if (state.errors['next'] == null) ...[
              const SizedBox(height: 8),
              const Text(
                'Use 8 or more characters with upper and lower case letters, a number and a symbol.',
                style: TextStyle(fontSize: 12, height: 1.5),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
