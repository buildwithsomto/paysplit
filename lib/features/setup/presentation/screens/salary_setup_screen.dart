import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paysplit/features/setup/presentation/controllers/setup_controller.dart';
import 'package:paysplit/features/setup/presentation/widgets/setup_layout.dart';
import 'package:paysplit/widgets/buttons/app_button.dart';
import 'package:paysplit/widgets/feedback/app_notice.dart';
import 'package:paysplit/widgets/inputs/app_input_field.dart';
import 'package:paysplit/widgets/inputs/app_select_field.dart';
import 'package:paysplit/widgets/overlays/choice_sheet.dart';

class SalarySetupScreen extends ConsumerStatefulWidget {
  const SalarySetupScreen({super.key});
  @override
  ConsumerState<SalarySetupScreen> createState() => _SalarySetupScreenState();
}

class _SalarySetupScreenState extends ConsumerState<SalarySetupScreen> {
  late final TextEditingController _employer;
  late final TextEditingController _salary;
  @override
  void initState() {
    super.initState();
    final state = ref.read(setupControllerProvider);
    _employer = TextEditingController(text: state.employer);
    _salary = TextEditingController(text: state.salaryInput);
  }

  @override
  void dispose() {
    _employer.dispose();
    _salary.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final saved = await ref.read(setupControllerProvider.notifier).save();
    if (!mounted || !saved) return;
    context.push('/setup/wallet');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(setupControllerProvider);
    final controller = ref.read(setupControllerProvider.notifier);
    // The saved income arrives after the first frame on a cold open.
    ref.listen(setupControllerProvider, (previous, next) {
      if (previous?.saved != true && next.saved) {
        if (_employer.text.isEmpty) _employer.text = next.employer;
        if (_salary.text.isEmpty) _salary.text = next.salaryInput;
      }
      final failure = next.errors['form'];
      if (failure != null && failure != previous?.errors['form']) {
        showAppNotice(context, failure);
      }
    });
    return SetupLayout(
      step: 1,
      title: 'Salary Income Source',
      onBack: () => context.canPop() ? context.pop() : context.go('/home'),
      bottom: AppButton(label: 'Next', busy: state.busy, onPressed: _next),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          AppInputField(
            label: 'Employer',
            controller: _employer,
            hint: 'e.g Talent Nation',
            error: state.errors['employer'],
            onChanged: controller.updateEmployer,
          ),
          AppInputField(
            label: 'Monthly Salary Amount (₦)',
            controller: _salary,
            hint: 'e.g 850,000',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            error: state.errors['salary'],
            onChanged: controller.updateSalary,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          ),
          AppSelectField(
            label: 'Expected Payday of Month',
            hint: 'Select',
            value: state.payDay == null ? null : 'Day ${state.payDay}',
            error: state.errors['day'],
            onPressed: () async {
              FocusManager.instance.primaryFocus?.unfocus();
              final day = await showChoiceSheet<int>(
                context,
                title: 'Expected Payday of Month',
                choices: List.generate(31, (i) => i + 1),
                label: (day) => 'Day $day',
                selected: state.payDay,
              );
              if (day != null) controller.setPayDay(day);
            },
          ),
          if (state.payDay case final day? when day > 28)
            const Text(
              'In shorter months your payday falls on the last day. Splits run when your salary arrives.',
              style: TextStyle(fontSize: 12),
            ),
        ],
      ),
    );
  }
}
