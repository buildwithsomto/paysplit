import 'package:paysplit/app/navigation/app_navigation_insets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:paysplit/core/presentation/content_phase.dart';
import 'package:paysplit/widgets/feedback/content_status_card.dart';
import 'package:paysplit/features/destinations/presentation/controllers/destinations_controller.dart';
import 'package:paysplit/features/rules/presentation/controllers/rules_controller.dart';
import 'package:paysplit/features/rules/presentation/controllers/split_execution_controller.dart';
import 'package:paysplit/features/rules/presentation/widgets/rules_allocation_card.dart';
import 'package:paysplit/features/setup/presentation/controllers/setup_controller.dart';
import 'package:paysplit/theme/app_colors.dart';
import 'package:paysplit/widgets/app_svg_icon.dart';
import 'package:paysplit/widgets/feedback/skeleton.dart';
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
    final nextPayday = ref.watch(
      setupControllerProvider.select((s) => s.nextPayday),
    );
    final filter = _filter;
    final estimate = nextPayday == null
        ? null
        : DateFormat.yMMMd().format(nextPayday);
    final filtered = rules
        .where((rule) => filter == null || rule.status == filter)
        .toList();
    final status = ref.watch(rulesStatusProvider);
    final showStatus =
        status.phase != ContentPhase.ready &&
        !(status.phase == ContentPhase.refreshing && status.hasData);
    // First load: placeholders in the shape of the allocation card and the
    // rule list, rather than an empty card and "no rules yet".
    if (status.phase == ContentPhase.loading && !status.hasData) {
      return const TabPageLayout(
        title: 'Split Rules',
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: SkeletonLoader(
            label: 'Loading split rules',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonSurface(
                  radius: 20,
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SkeletonBox(width: 130),
                          SkeletonBox(width: 90),
                        ],
                      ),
                      SizedBox(height: 14),
                      SkeletonBox.card(height: 24, radius: 8),
                      SizedBox(height: 14),
                      SkeletonBox(width: 200, height: 10),
                      SizedBox(height: 18),
                      Row(
                        spacing: 8,
                        children: [
                          Expanded(
                            child: SkeletonBox.card(height: 64, radius: 12),
                          ),
                          Expanded(
                            child: SkeletonBox.card(height: 64, radius: 12),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        spacing: 8,
                        children: [
                          Expanded(
                            child: SkeletonBox.card(height: 64, radius: 12),
                          ),
                          Expanded(
                            child: SkeletonBox.card(height: 64, radius: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  spacing: 12,
                  children: [
                    Expanded(child: SkeletonBox.card(height: 48, radius: 12)),
                    Expanded(child: SkeletonBox.card(height: 48, radius: 12)),
                  ],
                ),
                SizedBox(height: 28),
                SkeletonBox(width: 110),
                SizedBox(height: 16),
                SkeletonTiles(),
              ],
            ),
          ),
        ),
      );
    }
    // The first load failed: nothing is known yet, so show only the reason
    // and a retry, not an empty allocation card and "no rules yet".
    if (!status.hasData && status.phase.isFailure) {
      final load = ref.read(rulesControllerProvider.notifier).load;
      return TabPageLayout(
        title: 'Split Rules',
        child: RefreshIndicator(
          onRefresh: load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            children: [
              ContentStatusCard(
                phase: status.phase,
                hasContent: false,
                subject: 'Split rules',
                items: 'rules',
                message: status.message,
                onRetry: load,
              ),
            ],
          ),
        ),
      );
    }
    return TabPageLayout(
      title: 'Split Rules',
      child: RefreshIndicator(
        onRefresh: ref.read(rulesControllerProvider.notifier).load,
        child: SingleChildScrollView(
          restorationId: 'rules_scroll',
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            16,
            10,
            16,
            AppNavigationInsets.bottomOf(context) + 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (status.summary case final summary?) ...[
                RulesAllocationCard(summary: summary),
                const SizedBox(height: 12),
              ],
              if (showStatus) ...[
                ContentStatusCard(
                  phase: status.phase,
                  hasContent: status.hasData,
                  subject: 'Split rules',
                  items: 'rules',
                  message: status.message,
                  updatedAt: status.updatedAt,
                  onRetry: ref.read(rulesControllerProvider.notifier).load,
                ),
                const SizedBox(height: 12),
              ],
              Row(
                spacing: 12,
                children: [
                  Expanded(
                    child: _QuickAction(
                      label: 'Run Now',
                      onPressed: () {
                        // The reason an earlier run failed is not shown again.
                        ref.read(splitExecutionProvider.notifier).clearError();
                        context.push('/run-now');
                      },
                    ),
                  ),
                  Expanded(
                    child: _QuickAction(
                      label: 'Split History',
                      onPressed: () => context.push('/split-history'),
                    ),
                  ),
                ],
              ),
              if (estimate != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Next expected salary: $estimate',
                  style: const TextStyle(fontSize: 12, height: 1.5),
                ),
              ],
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
                        ])
                          Semantics(
                            selected: filter == item.$2,
                            button: true,
                            child: Material(
                              color: filter == item.$2
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
                    filter == null
                        ? 'No split rules yet. Create a rule for a saved wallet or beneficiary.'
                        : 'No ${filter.name} rules.',
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
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF171918),
                                    ),
                                  ),
                                  Text(
                                    // A paused rule says so: it will not run.
                                    rule.status == RuleStatus.paused
                                        ? '${ruleDestinationName(rule, destinations)} · Paused'
                                        : ruleDestinationName(
                                            rule,
                                            destinations,
                                          ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
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
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEEF5F0),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    rule.method.label,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF387647),
                                    ),
                                  ),
                                ),
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
      ),
    );
  }
}

/// A secondary action beside the rule list, in the linked-rule button style.
class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onPressed,
    style: OutlinedButton.styleFrom(
      backgroundColor: AppColors.primaryLight,
      foregroundColor: AppColors.action,
      side: const BorderSide(color: AppColors.primaryBorder),
      minimumSize: const Size(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    ),
    child: Text(label),
  );
}
