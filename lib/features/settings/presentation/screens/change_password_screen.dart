import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paysplit/features/settings/presentation/controllers/settings_controller.dart';
import 'package:paysplit/widgets/buttons/app_button.dart';
import 'package:paysplit/widgets/feedback/preview_notice.dart';
import 'package:paysplit/widgets/inputs/app_input_field.dart';
import 'package:paysplit/widgets/layout/app_page_layout.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});
  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  Map<String, String> _errors = {};
  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    super.dispose();
  }

  void _submit() {
    final errors = validatePasswordChange(_current.text, _next.text);
    setState(() => _errors = errors);
    if (errors.isNotEmpty) {
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    _current.clear();
    _next.clear();
    showPreviewNotice(context, 'Password changes are unavailable.');
  }

  @override
  Widget build(BuildContext context) => AppPageLayout(
    title: 'Password',
    headerTop: 17,
    bodyGap: 35,
    onBack: () => context.canPop() ? context.pop() : context.go('/profile'),
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
            error: _errors['current'],
            autofillHints: const [AutofillHints.password],
            onChanged: (_) =>
                setState(() => _errors = {..._errors}..remove('current')),
          ),
          const SizedBox(height: 20),
          AppInputField(
            label: 'New Password',
            labelGap: 6,
            controller: _next,
            password: true,
            error: _errors['next'],
            autofillHints: const [AutofillHints.newPassword],
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            onChanged: (_) =>
                setState(() => _errors = {..._errors}..remove('next')),
          ),
          const SizedBox(height: 120),
          AppButton(label: 'Change Password', onPressed: _submit),
          const SizedBox(height: 16),
          const Text(
            'Use at least 8 characters.',
            style: TextStyle(fontSize: 12, height: 1.5),
          ),
        ],
      ),
    ),
  );
}
