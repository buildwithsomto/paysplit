import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:paysplit/core/formatting/money.dart';
import 'package:paysplit/features/rules/presentation/controllers/rules_controller.dart';
import 'package:paysplit/features/rules/presentation/controllers/split_execution_controller.dart';
import 'package:paysplit/features/rules/presentation/widgets/rule_review_sheet.dart';
import 'package:paysplit/widgets/buttons/app_button.dart';
import 'package:paysplit/widgets/layout/app_page_layout.dart';

class RunNowScreen extends ConsumerWidget {
  const RunNowScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final review = ref.watch(splitReviewProvider);
    final error = ref.watch(splitExecutionProvider.select((s) => s.error));
    return AppPageLayout(
      title: 'Run Now',
      onBack: () => context.canPop() ? context.pop() : context.go('/rules'),
      bottom: AppButton(
        label: review.sample ? 'Confirm Preview' : 'Confirm Split',
        onPressed: review.canPreview
            ? () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Preview this split?'),
                    content: const Text(
                      'This runs a local demonstration of the reviewed rules. No real funds move, and no transaction or receipt is created.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Preview split'),
                      ),
                    ],
                  ),
                );
                if (confirmed != true || !context.mounted) {
                  return;
                }
                final id = ref
                    .read(splitExecutionProvider.notifier)
                    .confirmPreview(review.signature);
                if (id != null) {
                  context.pushReplacement('/split-history/$id');
                }
              }
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          const Text(
            'Review your allocations',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          Text(
            review.sample
                ? 'SAMPLE · Manual split review. This does not represent an available bank balance.'
                : 'Only active rules and confirmed, unallocated salary funds can be used.',
          ),
          if (review.sample)
            _SummaryCard(
              children: [
                RuleReviewRow(
                  label: 'Original salary',
                  value: Money.format(review.salaryMinor),
                ),
                RuleReviewRow(
                  label: 'Eligible unallocated funds',
                  value: Money.format(review.availableMinor),
                ),
                RuleReviewRow(
                  label: 'Already unavailable',
                  value: Money.format(
                    review.salaryMinor - review.availableMinor,
                  ),
                ),
              ],
            ),
          for (final block in review.blocks) _MessageCard(message: block),
          if (review.sample && review.lines.isNotEmpty) ...[
            const Text(
              'Priority order · 1 is highest',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const Text(
              'Percentages use the original salary. Estimates assume earlier allocations succeed; later allocations may change if an earlier one fails. Uncertain allocations remain reserved.',
            ),
            for (final line in review.lines)
              _AllocationCard(line: line, planned: true),
          ],
          if (error != null)
            Text(error, style: const TextStyle(color: Color(0xFFB42318))),
          TextButton(
            onPressed: () => context.push('/split-history'),
            child: const Text('View Split History'),
          ),
        ],
      ),
    );
  }
}

class SplitHistoryScreen extends ConsumerWidget {
  const SplitHistoryScreen({this.ruleId, super.key});
  final String? ruleId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final executions = ref
        .watch(splitExecutionProvider.select((s) => s.executions))
        .where(
          (e) => ruleId == null || e.lines.any((line) => line.ruleId == ruleId),
        )
        .toList(growable: false);
    return AppPageLayout(
      title: 'Split History',
      onBack: () => context.canPop() ? context.pop() : context.go('/rules'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          if (ruleId != null)
            const Text(
              'Runs containing this rule. Summary totals cover each whole run.',
            ),
          if (executions.isEmpty)
            const _MessageCard(
              message:
                  'No split executions yet. Completed and pending runs will appear here with their allocation breakdowns.',
            ),
          for (final execution in executions)
            Semantics(
              button: true,
              container: true,
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () => context.push('/split-history/${execution.id}'),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 12,
                      children: [
                        Text(
                          'Manual split · ${execution.status}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${DateFormat.yMMMd().add_jm().format(execution.at)} · Local time',
                        ),
                        RuleReviewRow(
                          label: 'Salary baseline',
                          value: Money.format(execution.salaryMinor),
                        ),
                        RuleReviewRow(
                          label: 'Allocated to wallets',
                          value: Money.format(
                            execution.allocated(RuleDestinationType.wallet),
                          ),
                        ),
                        RuleReviewRow(
                          label: 'Transferred to people',
                          value: Money.format(
                            execution.allocated(
                              RuleDestinationType.beneficiary,
                            ),
                          ),
                        ),
                        RuleReviewRow(
                          label: 'Unallocated remainder',
                          value: Money.format(execution.remainingMinor),
                        ),
                        Text(
                          '${execution.id} · SAMPLE ONLY',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class SplitExecutionScreen extends ConsumerWidget {
  const SplitExecutionScreen({required this.id, super.key});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final execution = ref
        .watch(splitExecutionProvider)
        .executions
        .where((e) => e.id == id)
        .firstOrNull;
    return AppPageLayout(
      title: 'Split Details',
      onBack: () =>
          context.canPop() ? context.pop() : context.go('/split-history'),
      child: execution == null
          ? const Text(
              'This split is unavailable. Return to Split History to choose a record.',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 16,
              children: [
                const Text(
                  'SAMPLE — NO MONEY MOVED',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  execution.status,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Manual split · ${DateFormat.yMMMd().add_jm().format(execution.at)} · Local time',
                ),
                _SummaryCard(
                  children: [
                    RuleReviewRow(label: 'Reference', value: execution.id),
                    RuleReviewRow(
                      label: 'Original salary',
                      value: Money.format(execution.salaryMinor),
                    ),
                    RuleReviewRow(
                      label: 'Eligible at start',
                      value: Money.format(execution.availableMinor),
                    ),
                    RuleReviewRow(
                      label: 'Successful allocations',
                      value: Money.format(
                        execution.total(SplitOutcome.success),
                      ),
                    ),
                    RuleReviewRow(
                      label: 'Pending / reserved',
                      value: Money.format(
                        execution.total(SplitOutcome.pending),
                      ),
                    ),
                    RuleReviewRow(
                      label: 'Unallocated remainder',
                      value: Money.format(execution.remainingMinor),
                    ),
                  ],
                ),
                if (execution.total(SplitOutcome.pending) > 0)
                  const _MessageCard(
                    message:
                        'Some allocations are awaiting confirmation. They are not counted as successful. Check their final status before trying again; this preview cannot contact a provider.',
                  ),
                for (final line in execution.lines) _AllocationCard(line: line),
                const Text(
                  'These are simulated outcomes. No transaction receipts exist for this preview. Live records will link to their authoritative transactions and supported receipts.',
                ),
                TextButton(
                  onPressed: () => context.go('/split-history'),
                  child: const Text('View Split History'),
                ),
              ],
            ),
    );
  }
}

class _AllocationCard extends StatelessWidget {
  const _AllocationCard({required this.line, this.planned = false});
  final SplitLine line;
  final bool planned;
  @override
  Widget build(BuildContext context) => _SummaryCard(
    children: [
      Text(
        line.name,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      Text('${line.destination} · Priority ${line.priority}'),
      Text(
        planned
            ? line.outcome == SplitOutcome.skipped
                  ? 'Expected: skipped'
                  : 'Expected: ready to allocate'
            : 'Sample status: ${line.outcome.name}',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: line.outcome == SplitOutcome.failed
              ? const Color(0xFFB42318)
              : const Color(0xFF344054),
        ),
      ),
      RuleReviewRow(
        label: 'Requested',
        value: Money.format(line.requestedMinor),
      ),
      RuleReviewRow(
        label: 'Available at this step',
        value: Money.format(line.availableBeforeMinor),
      ),
      RuleReviewRow(
        label: planned ? 'Expected allocation' : 'Successful allocation',
        value: Money.format(line.actualMinor),
      ),
      if (line.reason != null)
        Text(line.reason!, style: const TextStyle(fontSize: 12, height: 1.5)),
    ],
  );
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: children,
    ),
  );
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFEBF6FE),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(message),
  );
}
