import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paysplit/core/network/api_exception.dart';
import 'package:paysplit/widgets/feedback/app_notice.dart';
import 'package:paysplit/widgets/overlays/confirm_sheet.dart';
import 'package:go_router/go_router.dart';
import 'package:paysplit/core/formatting/money.dart';
import 'package:paysplit/features/destinations/presentation/controllers/destinations_controller.dart';
import 'package:paysplit/features/rules/presentation/controllers/rules_controller.dart';
import 'package:paysplit/features/rules/presentation/widgets/rule_review_row.dart';
import 'package:paysplit/widgets/app_svg_icon.dart';
import 'package:paysplit/widgets/layout/app_page_layout.dart';
import 'package:paysplit/widgets/overlays/success_sheet_layout.dart';
import 'package:paysplit/features/setup/presentation/controllers/setup_controller.dart';

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
    // The salary source the rule runs on.
    final employer = ref.watch(
      setupControllerProvider.select((s) => s.employer),
    );
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
                    rule.status == RuleStatus.active ? 'Pause' : 'Resume',
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
                  final pause = rule.status == RuleStatus.active;
                  try {
                    await ref
                        .read(rulesControllerProvider.notifier)
                        .setPaused(id, pause);
                    if (context.mounted) {
                      showAppNotice(
                        context,
                        pause
                            ? 'Rule paused. Splits will skip it.'
                            : 'Rule resumed.',
                      );
                    }
                  } on Object catch (error) {
                    if (context.mounted) {
                      showAppNotice(context, describeError(error));
                    }
                  }
                } else {
                  final confirmed = await showConfirmSheet(
                    context,
                    title: 'Delete split rule?',
                    message:
                        '${rule.name} will stop running on future salary payments. Past transactions stay in your history.',
                    action: 'Delete',
                    destructive: true,
                  );
                  if (!confirmed || !context.mounted) return;
                  try {
                    await ref.read(rulesControllerProvider.notifier).delete(id);
                    if (!context.mounted) return;
                    showAppNotice(context, 'Split rule deleted.');
                    context.canPop() ? context.pop() : context.go('/rules');
                  } on Object catch (error) {
                    if (context.mounted) {
                      showAppNotice(context, describeError(error));
                    }
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
                            rule.method.label,
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
                            Money.format(rule.allocatedThisMonthMinor),
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
                        label: 'Condition',
                        value: employer.isEmpty
                            ? 'Every salary credit'
                            : employer,
                      ),
                      RuleReviewRow(
                        label: 'Method',
                        value: rule.allocationLabel,
                      ),
                      RuleReviewRow(
                        label: 'Priority',
                        value: '${rule.priority}',
                      ),
                      RuleReviewRow(label: 'Status', value: rule.status.label),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/split-history'),
                  child: const Text('View Execution History'),
                ),
              ],
            ),
    );
  }
}

/// Confirms a newly created rule. New rules are always active.
class RuleSavedSheet extends StatelessWidget {
  const RuleSavedSheet({super.key});

  @override
  Widget build(BuildContext context) => SuccessSheetLayout(
    title: 'Split Rule Created',
    message: 'It runs each time your salary arrives.',
    onClose: () => context.pop(),
    onHome: () => context.go('/home'),
  );
}
