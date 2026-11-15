import 'package:paysplit/features/rules/presentation/controllers/split_execution_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paysplit/core/formatting/money.dart';
import 'package:paysplit/features/destinations/presentation/controllers/destinations_controller.dart';
import 'package:paysplit/features/rules/presentation/controllers/rules_controller.dart';
import 'package:paysplit/features/rules/presentation/widgets/rule_review_sheet.dart';
import 'package:paysplit/widgets/app_svg_icon.dart';
import 'package:paysplit/widgets/buttons/app_button.dart';
import 'package:paysplit/widgets/layout/app_page_layout.dart';
import 'package:paysplit/widgets/overlays/success_sheet_layout.dart';

class RuleDetailScreen extends ConsumerWidget {
  const RuleDetailScreen({required this.id, super.key});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rule = ref
        .watch(rulesControllerProvider)
        .where((r) => r.id == id)
        .firstOrNull;
    final destinations = ref.watch(destinationsControllerProvider);
    final sampleRuns = ref
        .watch(splitExecutionProvider)
        .executions
        .where((execution) => execution.lines.any((line) => line.ruleId == id))
        .length;
    return AppPageLayout(
      title: 'Details',
      headerTop: 31,
      bodyGap: 17,
      onBack: () => context.canPop() ? context.pop() : context.go('/rules'),
      trailing: rule == null
          ? null
          : PopupMenuButton<String>(
              tooltip: 'Rule actions',
              icon: const AppSvgIcon('assets/icons/rules/c3113.svg'),
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(
                  value: 'status',
                  child: Text(
                    rule.status == RuleStatus.active
                        ? 'Pause'
                        : rule.status == RuleStatus.paused
                        ? 'Resume'
                        : 'Review & activate',
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    'Delete',
                    style: TextStyle(color: Color(0xFFFF383C)),
                  ),
                ),
              ],
              onSelected: (action) async {
                if (action == 'edit') {
                  context.push('/rules/new?id=$id');
                } else if (action == 'status') {
                  if (rule.status == RuleStatus.active) {
                    ref.read(rulesControllerProvider.notifier).pause(id);
                  } else {
                    await reviewRule(context, rule.input, id: id);
                  }
                } else {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete split rule?'),
                      content: const Text(
                        'Remove this rule from future allocations? Historical transactions are retained.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true && context.mounted) {
                    ref.read(rulesControllerProvider.notifier).delete(id);
                    context.canPop() ? context.pop() : context.go('/rules');
                  }
                }
              },
            ),
      child: rule == null
          ? const Text('This rule is no longer available.')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 20,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 12,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9F9F9),
                            border: Border.all(color: const Color(0xFFE4E4E4)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            rule.method == AllocationMethod.fixed
                                ? 'Fixed Amount'
                                : 'Percentage',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Text(
                            Money.format(0),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
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
                            child: const Text(
                              'Allocated this month',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF387647),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const AppSvgIcon(
                        'assets/icons/rules/6a245.svg',
                        width: double.infinity,
                        height: 1,
                      ),
                      RuleReviewRow(label: 'Rule Name', value: rule.name),
                      RuleReviewRow(
                        label: 'Destination',
                        value: ruleDestinationName(rule, destinations),
                      ),
                      RuleReviewRow(
                        label: 'Allocation',
                        value: rule.allocationLabel,
                      ),
                      RuleReviewRow(
                        label: 'Priority',
                        value: '${rule.priority} (1 is highest)',
                      ),
                      RuleReviewRow(
                        label: 'Status',
                        value: rule.status == RuleStatus.active
                            ? 'Active on this device'
                            : rule.status.name,
                      ),
                    ],
                  ),
                ),
                const Text(
                  'No confirmed allocations yet.',
                  style: TextStyle(fontSize: 14, height: 1.5),
                ),
                if (rule.status != RuleStatus.active)
                  AppButton(
                    label: 'Review & Activate',
                    onPressed: () => reviewRule(context, rule.input, id: id),
                  ),
                const Text(
                  'Execution History',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF171918),
                  ),
                ),
                Text(
                  sampleRuns == 0
                      ? 'No executions yet.'
                      : '$sampleRuns sample ${sampleRuns == 1 ? 'run' : 'runs'} · No money moved',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF696969),
                  ),
                ),
                TextButton(
                  onPressed: () => context.push(
                    Uri(
                      path: '/split-history',
                      queryParameters: {'rule': id},
                    ).toString(),
                  ),
                  child: const Text('View Execution History'),
                ),
              ],
            ),
    );
  }
}

class RuleSavedSheet extends ConsumerWidget {
  const RuleSavedSheet({required this.id, super.key});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rule = ref
        .watch(rulesControllerProvider)
        .where((r) => r.id == id)
        .firstOrNull;
    return SuccessSheetLayout(
      title: rule?.status == RuleStatus.active
          ? 'Split Rule Created'
          : 'Split Rule Saved as Draft',
      message: 'Saved locally. No money has moved.',
      onClose: () => context.pop(),
      onHome: () => context.go('/home'),
    );
  }
}
