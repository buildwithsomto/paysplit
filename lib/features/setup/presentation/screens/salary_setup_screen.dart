import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paysplit/features/setup/presentation/controllers/setup_controller.dart';
import 'package:paysplit/features/setup/presentation/widgets/setup_layout.dart';
import 'package:paysplit/widgets/buttons/app_button.dart';
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

  void _next() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (ref.read(setupControllerProvider.notifier).validate()) {
      context.push('/setup/wallet');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(setupControllerProvider);
    final controller = ref.read(setupControllerProvider.notifier);
    return SetupLayout(
      step: 1,
      title: 'Salary Income Source',
      onBack: () => context.canPop() ? context.pop() : context.go('/home'),
      bottom: AppButton(label: 'Next', onPressed: _next),
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
            label: 'Expected Pay Day',
            hint: 'Select day of the month',
            value: state.payDay == null ? null : 'Day ${state.payDay}',
            error: state.errors['day'],
            onPressed: () async {
              FocusManager.instance.primaryFocus?.unfocus();
              final day = await showChoiceSheet<int>(
                context,
                title: 'Expected pay day',
                choices: List.generate(31, (i) => i + 1),
                label: (day) => 'Day $day',
                selected: state.payDay,
              );
              if (day != null) controller.setPayDay(day);
            },
          ),
          if (state.payDay != null && state.payDay! > 28)
            const Text(
              'For shorter months, we use the last day. Splits only run after salary funds are confirmed.',
              style: TextStyle(fontSize: 12),
            ),
        ],
      ),
    );
  }
}
