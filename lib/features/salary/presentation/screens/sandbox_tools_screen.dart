import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paysplit/core/formatting/money.dart';
import 'package:paysplit/features/salary/presentation/controllers/salary_account_controller.dart';
import 'package:paysplit/theme/app_typography.dart';
import 'package:paysplit/widgets/buttons/app_button.dart';
import 'package:paysplit/widgets/feedback/app_notice.dart';
import 'package:paysplit/widgets/inputs/app_input_field.dart';
import 'package:paysplit/widgets/layout/app_page_layout.dart';

/// Tools that only a dev or QA backend supports. The route exists only when
/// [AppConfig.sandboxToolsEnabled] is set.
class SandboxToolsScreen extends StatelessWidget {
  const SandboxToolsScreen({super.key});

  @override
  Widget build(BuildContext context) => AppPageLayout(
    title: 'Sandbox Tools',
    onBack: () => context.canPop() ? context.pop() : context.go('/home'),
    child: const _SimulateCredit(),
  );
}

/// `POST /salary-account/simulate-credit`: a dev/QA backend runs its real
/// salary-credit flow (notification, automatic split) with simulated money.
class _SimulateCredit extends ConsumerStatefulWidget {
  const _SimulateCredit();
  @override
  ConsumerState<_SimulateCredit> createState() => _SimulateCreditState();
}

class _SimulateCreditState extends ConsumerState<_SimulateCredit> {
  final _amount = TextEditingController(text: '850,000');
  final _sender = TextEditingController(text: 'Talent Nation');
  final _narration = TextEditingController(text: 'Salary');
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _amount.dispose();
    _sender.dispose();
    _narration.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final amount = Money.parse(_amount.text);
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter an amount greater than zero.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final message = await ref
        .read(salaryAccountProvider.notifier)
        .simulateCredit(
          amount: amount,
          senderName: _sender.text.trim().isEmpty ? null : _sender.text.trim(),
          narration: _narration.text.trim().isEmpty
              ? null
              : _narration.text.trim(),
        );
    if (!mounted) return;
    setState(() => _busy = false);
    showAppNotice(context, message);
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 12,
    children: [
      const Text('Simulate Salary Credit', style: AppTypography.heading),
      const Text(
        'Available on the test backend only. Credits your salary account '
        'with simulated money and runs your active split rules, the way a '
        'real salary payment would.',
        style: AppTypography.body,
      ),
      const SizedBox(height: 4),
      AppInputField(
        label: 'Amount (₦)',
        controller: _amount,
        error: _error,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d,.]'))],
      ),
      AppInputField(label: 'Sender', controller: _sender),
      AppInputField(
        label: 'Narration',
        controller: _narration,
        textInputAction: TextInputAction.done,
      ),
      AppButton(label: 'Simulate Credit', busy: _busy, onPressed: _submit),
    ],
  );
}
