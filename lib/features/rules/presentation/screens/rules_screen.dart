import 'package:paysplit/app/navigation/app_navigation_insets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:paysplit/features/destinations/presentation/controllers/destinations_controller.dart';
import 'package:paysplit/features/rules/presentation/controllers/rules_controller.dart';
import 'package:paysplit/features/rules/presentation/widgets/rules_allocation_card.dart';
import 'package:paysplit/features/setup/presentation/controllers/setup_controller.dart';
import 'package:paysplit/theme/app_colors.dart';
import 'package:paysplit/widgets/app_svg_icon.dart';
import 'package:paysplit/widgets/layout/tab_page_layout.dart';

class RulesScreen extends ConsumerStatefulWidget {
  const RulesScreen({super.key});
  @override
  ConsumerState<RulesScreen> createState() => _RulesScreenState();
}

class _RulesScreenState extends ConsumerState<RulesScreen>
    with RestorationMixin {
  final _selection = RestorableEnumN<RuleStatus>(
    null,
    values: RuleStatus.values,
  );
  RuleStatus? get _filter => _selection.value;
  @override
  String get restorationId => 'rules_view';
  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_selection, 'status');
  }

  @override
  void dispose() {
    _selection.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rules = ref.watch(rulesControllerProvider);
    final destinations = ref.watch(destinationsControllerProvider);
    final setup = ref.watch(setupControllerProvider);
    final payDay = setup.payDay;
    final estimate = payDay == null
        ? null
        : DateFormat.yMMMd().format(
            SetupController.nextExpectedDate(DateTime.now(), payDay),
          );
    final filtered = rules
        .where((rule) => _filter == null || rule.status == _filter)
        .toList();
    return TabPageLayout(
      title: 'Split Rules',
      child: SingleChildScrollView(
        restorationId: 'rules_scroll',
        padding: EdgeInsets.fromLTRB(
          16,
          10,
          16,
          AppNavigationInsets.bottomOf(context) + 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RulesAllocationCard(rules: rules, salaryMinor: setup.salaryMinor),
            const SizedBox(height: 12),
            if (estimate != null)
              Text(
                'Next expected split: $estimate, after salary is confirmed.',
              ),
            Wrap(
              spacing: 12,
              children: [
                TextButton(
                  onPressed: () => context.push('/run-now'),
                  child: const Text('Run Now'),
                ),
                TextButton(
                  onPressed: () => context.push('/split-history'),
                  child: const Text('Split History'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Salary Rules',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF171918),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              runSpacing: 10,
              spacing: 8,
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F3F3),
                    border: Border.all(color: const Color(0xFFE4E4E4)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Wrap(
                    children: [
                      for (final item in <(String, RuleStatus?)>[
                        ('All', null),
                        ('Active', RuleStatus.active),
                        ('Paused', RuleStatus.paused),
                        ('Draft', RuleStatus.draft),
                      ])
                        Semantics(
                          selected: _filter == item.$2,
                          button: true,
                          child: Material(
                            color: _filter == item.$2
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            child: InkWell(
                              onTap: () =>
                                  setState(() => _selection.value = item.$2),
                              borderRadius: BorderRadius.circular(10),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minWidth: 48,
                                  minHeight: 48,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 14,
                                  ),
                                  child: Text(
                                    item.$1,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      height: 1.4,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => context.push('/rules/new'),
                  icon: const AppSvgIcon(
                    'assets/icons/rules/b7b2d.svg',
                    size: 16,
                  ),
                  label: const Text('Add New Rule'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.action,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                    ),
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (filtered.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _filter == null
                      ? 'No split rules yet. Create a rule for a saved wallet or beneficiary.'
                      : 'No ${_filter!.name} rules.',
                  textAlign: TextAlign.center,
                ),
              ),
            for (final rule in filtered)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () => context.push('/rules/${rule.id}'),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 16,
                      ),
                      child: Row(
                        spacing: 8,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: 4,
                              children: [
                                Text(
                                  rule.name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF171918),
                                  ),
                                ),
                                Text(
                                  ruleDestinationName(rule, destinations),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF696969),
                                  ),
                                ),
                                Text(
                                  'Priority ${rule.priority} · ${rule.status.name}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF696969),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Flexible(
                            flex: 2,
                            fit: FlexFit.tight,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              spacing: 4,
                              children: [
                                Text(
                                  rule.allocationLabel,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF171918),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEEF5F0),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    rule.method == AllocationMethod.fixed
                                        ? 'Fixed Amount'
                                        : 'Percentage',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF387647),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const AppSvgIcon(
                            'assets/icons/rules/c1ae0.svg',
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
