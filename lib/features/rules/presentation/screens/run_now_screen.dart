import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:paysplit/core/formatting/money.dart';
import 'package:paysplit/core/network/api_exception.dart';
import 'package:paysplit/core/presentation/content_phase.dart';
import 'package:paysplit/features/rules/presentation/controllers/rules_controller.dart';
import 'package:paysplit/features/rules/presentation/controllers/split_execution_controller.dart';
import 'package:paysplit/features/rules/presentation/widgets/rule_review_row.dart';
import 'package:paysplit/features/salary/presentation/controllers/salary_account_controller.dart';
import 'package:paysplit/theme/app_colors.dart';
import 'package:paysplit/theme/app_typography.dart';
import 'package:paysplit/widgets/app_svg_icon.dart';
import 'package:paysplit/widgets/buttons/app_button.dart';
import 'package:paysplit/widgets/buttons/app_text_link.dart';
import 'package:paysplit/widgets/feedback/content_status_card.dart';
import 'package:paysplit/widgets/feedback/empty_state.dart';
import 'package:paysplit/widgets/feedback/skeleton.dart';
import 'package:paysplit/widgets/layout/app_page_layout.dart';
import 'package:paysplit/widgets/overlays/confirm_sheet.dart';

/// "Run Now": splits the salary account balance by the active rules.
class RunNowScreen extends ConsumerWidget {
  const RunNowScreen({super.key});

  Future<void> _run(
    BuildContext context,
    WidgetRef ref,
    SplitReview review,
  ) async {
    final confirmed = await showConfirmSheet(
      context,
      title: 'Run split now?',
      message:
          '${Money.format(review.allocatedMinor)} will leave your salary account and go to your wallets and beneficiaries. This can’t be undone.',
      action: 'Run Split',
    );
    if (!confirmed || !context.mounted) return;
    final id = await ref.read(splitExecutionProvider.notifier).runNow();
    if (id != null && context.mounted) {
      context.pushReplacement('/split-history/$id');
    }
  }

  /// Retry reloads everything the estimate is made from.
  static void _reload(WidgetRef ref) {
    ref.read(rulesControllerProvider.notifier).load();
    ref.read(salaryAccountProvider.notifier).load();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final review = ref.watch(splitReviewProvider);
    final execution = ref.watch(splitExecutionProvider);
    final rulesStatus = ref.watch(rulesStatusProvider);
    final active = review.lines.length;
    final staying = review.availableMinor - review.allocatedMinor;
    // The rules never loaded, so the balance and the rule count are unknown.
    // Say that, rather than "₦0" and "no active rules".
    final unknown = !rulesStatus.hasData && rulesStatus.phase.isFailure;
    return AppPageLayout(
      title: 'Run Now',
      onBack: () => context.canPop() ? context.pop() : context.go('/rules'),
      bottom: AppButton(
        label: 'Run Split Now',
        busy: execution.running,
        onPressed: review.canRun ? () => _run(context, ref, review) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!unknown)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              decoration: _heroDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Salary Account Balance',
                    style: TextStyle(fontSize: 14, height: 1.2),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    review.balanceKnown
                        ? Money.format(review.availableMinor)
                        : '—',
                    style: const TextStyle(
                      fontFamily: 'Arimo',
                      color: Color(0xFF171918),
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    !review.balanceKnown
                        ? 'Balance not loaded'
                        : active == 0
                        ? 'No active rules to run'
                        : 'Shared across $active active ${active == 1 ? 'rule' : 'rules'}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                      color: Color(0xFF555653),
                    ),
                  ),
                ],
              ),
            ),
          if (rulesStatus.phase.isFailure) ...[
            if (!unknown) const SizedBox(height: 16),
            ContentStatusCard(
              phase: rulesStatus.phase,
              hasContent: rulesStatus.hasData,
              subject: 'Split rules',
              items: 'rules',
              message: rulesStatus.message,
              updatedAt: rulesStatus.updatedAt,
              onRetry: () => _reload(ref),
            ),
          ],
          if (execution.error case final error?) ...[
            const SizedBox(height: 16),
            _Notice(
              message: error,
              alert: true,
              action: execution.errorCode == 'KYC_REQUIRED'
                  ? ('Complete verification', '/kyc/result')
                  : ('View Split History', '/split-history'),
            ),
          ],
          if (!unknown)
            for (final block in review.blocks) ...[
              const SizedBox(height: 16),
              _Notice(message: block.message, action: block.action),
            ],
          if (review.lines.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text('What will happen', style: _sectionTitle),
            const SizedBox(height: 12),
            _Card(
              children: [
                for (final (index, line) in review.lines.indexed) ...[
                  if (index > 0) const Divider(height: 1, color: _divider),
                  _LineRow(line: line, planned: true),
                ],
                const Divider(height: 1, color: _divider),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: RuleReviewRow(
                    label: 'Stays in salary account',
                    value: Money.format(staying < 0 ? 0 : staying),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'An estimate from your current balance. Rules run in priority order; transfers to beneficiaries can take a few minutes.',
              style: TextStyle(fontSize: 12, height: 1.5),
            ),
          ],
          const SizedBox(height: 8),
          Center(
            child: AppTextLink(
              label: 'View Split History',
              onPressed: () => context.push('/split-history'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Every split run, automatic and Run Now, newest first.
class SplitHistoryScreen extends ConsumerWidget {
  const SplitHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(splitExecutionProvider);
    final controller = ref.read(splitExecutionProvider.notifier);
    final showStatus =
        state.phase != ContentPhase.ready &&
        !(state.phase == ContentPhase.refreshing && state.hasData);
    return AppPageLayout(
      title: 'Split History',
      onBack: () => context.canPop() ? context.pop() : context.go('/rules'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          if (showStatus)
            ContentStatusCard(
              phase: state.phase,
              hasContent: state.executions.isNotEmpty,
              subject: 'Split history',
              items: 'split runs',
              message: state.message,
              onRetry: controller.load,
              skeleton: const SkeletonTiles(count: 4),
            ),
          if (state.executions.isEmpty && state.phase == ContentPhase.ready)
            const EmptyState(
              title: 'No Splits Yet',
              message: 'Each time your salary is split, the run appears here.',
            ),
          for (final run in state.executions)
            Semantics(
              button: true,
              container: true,
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () => context.push('/split-history/${run.id}'),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    child: Row(
                      spacing: 12,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 4,
                            children: [
                              Text(
                                run.manual ? 'Run Now' : 'Automatic split',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF171918),
                                ),
                              ),
                              Text(
                                DateFormat('MMM d, y · h:mm a').format(run.at),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF696969),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          spacing: 6,
                          children: [
                            Text(
                              Money.format(run.totalMinor),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF171918),
                              ),
                            ),
                            _StatusChip.run(run.status),
                          ],
                        ),
                        const AppSvgIcon(
                          'assets/icons/destinations/c1ae0.svg',
                          width: 18,
                          height: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (state.loadMoreError case final error?)
            Semantics(
              liveRegion: true,
              child: Text(
                error,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: AppColors.error),
              ),
            ),
          if (state.hasMore)
            Center(
              child: state.loadingMore
                  ? const SkeletonLoader(
                      label: 'Loading more splits',
                      child: SkeletonTiles(count: 1),
                    )
                  : TextButton(
                      onPressed: controller.loadMore,
                      child: const Text('Load more'),
                    ),
            ),
        ],
      ),
    );
  }
}

/// One split run: its totals and what happened to each rule.
class SplitExecutionScreen extends ConsumerWidget {
  const SplitExecutionScreen({required this.id, super.key});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(splitRunDetailProvider(id));
    // The list row shows at once; the detail call adds the per-rule lines.
    final run =
        detail.value ??
        ref.watch(
          splitExecutionProvider.select(
            (s) => s.executions.where((e) => e.id == id).firstOrNull,
          ),
        );
    final pending = run?.pendingMinor ?? 0;
    return AppPageLayout(
      title: 'Split Details',
      onBack: () =>
          context.canPop() ? context.pop() : context.go('/split-history'),
      child: run == null
          ? detail.isLoading
                ? const SkeletonLoader(
                    label: 'Loading split',
                    child: Column(
                      spacing: 16,
                      children: [
                        SkeletonBox.card(height: 150),
                        SkeletonDetail(rows: 3),
                      ],
                    ),
                  )
                : _Notice(
                    message: describeError(
                      detail.error ?? ApiException.invalidResponse,
                      fallback: 'This split couldn’t be loaded.',
                    ),
                    alert: true,
                    onRetry: () => ref.invalidate(splitRunDetailProvider(id)),
                  )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                  decoration: _heroDecoration,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              run.manual ? 'Run Now' : 'Automatic split',
                              style: const TextStyle(fontSize: 14, height: 1.2),
                            ),
                          ),
                          _StatusChip.run(run.status),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        Money.format(run.totalMinor),
                        style: const TextStyle(
                          fontFamily: 'Arimo',
                          color: Color(0xFF171918),
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        DateFormat('MMM d, y · h:mm a').format(run.at),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                          color: Color(0xFF555653),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _Card(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        spacing: 14,
                        children: [
                          RuleReviewRow(
                            label: 'Balance before split',
                            value: Money.format(run.availableMinor),
                          ),
                          RuleReviewRow(
                            label: 'To wallets',
                            value: Money.format(run.toWalletsMinor),
                          ),
                          RuleReviewRow(
                            label: 'To beneficiaries',
                            value: Money.format(run.toBeneficiariesMinor),
                          ),
                          if (run.feesMinor > 0)
                            RuleReviewRow(
                              label: 'Fees',
                              value: Money.format(run.feesMinor),
                            ),
                          if (pending > 0)
                            RuleReviewRow(
                              label: 'Still processing',
                              value: Money.format(pending),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (pending > 0) ...[
                  const SizedBox(height: 16),
                  const _Notice(
                    message:
                        'Some transfers are still processing. You’ll be notified when they complete; there’s no need to run the split again.',
                  ),
                ],
                // The list row knows only the skipped rules. The lines are
                // shown once the full run has loaded, so the breakdown is
                // never a partial one.
                if (detail.isLoading && !detail.hasValue) ...[
                  const SizedBox(height: 24),
                  const SkeletonLoader(
                    label: 'Loading breakdown',
                    child: SkeletonTiles(),
                  ),
                ] else if (!detail.hasValue) ...[
                  const SizedBox(height: 16),
                  _Notice(
                    message: describeError(
                      detail.error ?? ApiException.invalidResponse,
                      fallback: 'The breakdown couldn’t be loaded.',
                    ),
                    alert: true,
                    onRetry: () => ref.invalidate(splitRunDetailProvider(id)),
                  ),
                ] else if (run.lines.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Text('Breakdown', style: _sectionTitle),
                  const SizedBox(height: 12),
                  _Card(
                    children: [
                      for (final (index, line) in run.lines.indexed) ...[
                        if (index > 0)
                          const Divider(height: 1, color: _divider),
                        _LineRow(
                          line: line,
                          onTap: line.transactionId == null
                              ? null
                              : () => context.push(
                                  '/transactions/${line.transactionId}',
                                ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
    );
  }
}

const _sectionTitle = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w500,
  color: Color(0xFF171918),
);
const _divider = Color(0xFFF0F1F5);
const _heroDecoration = BoxDecoration(
  border: Border.fromBorderSide(BorderSide(color: Color(0xFFD6EDFD))),
  borderRadius: BorderRadius.all(Radius.circular(16)),
  gradient: LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFEAF6FF), Color(0xFFF8FCFF)],
  ),
);

/// One rule within a run or an estimate.
class _LineRow extends StatelessWidget {
  const _LineRow({required this.line, this.planned = false, this.onTap});
  final SplitLine line;

  /// An estimate before the run, rather than a result.
  final bool planned;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final skipped = line.outcome == SplitOutcome.skipped;
    final detail = [
      if (line.destination.isNotEmpty) line.destination,
      if (line.priority case final priority?) 'Priority $priority',
    ].join(' · ');
    final reason = line.outcome == SplitOutcome.success ? null : line.reason;
    return Semantics(
      button: onTap != null,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 4,
                  children: [
                    Text(
                      line.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: skipped
                            ? AppColors.placeholder
                            : const Color(0xFF171918),
                      ),
                    ),
                    if (detail.isNotEmpty)
                      Text(
                        detail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF696969),
                        ),
                      ),
                    if (reason != null)
                      Text(
                        reason,
                        style: const TextStyle(fontSize: 12, height: 1.4),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                spacing: 6,
                children: [
                  Text(
                    Money.format(line.requestedMinor),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: skipped
                          ? AppColors.placeholder
                          : const Color(0xFF171918),
                      decoration: skipped ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (!planned || skipped) _StatusChip.line(line.outcome),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// What a status chip's colours say about the result.
enum _Tone { good, bad, neutral, waiting }

class _StatusChip extends StatelessWidget {
  const _StatusChip(this.label, this.tone);

  /// The status of a whole run.
  _StatusChip.run(SplitRunStatus status)
    : this(status.label, switch (status) {
        SplitRunStatus.completed => _Tone.good,
        SplitRunStatus.failed => _Tone.bad,
        SplitRunStatus.partial || SplitRunStatus.processing => _Tone.waiting,
      });

  /// What happened to one rule within a run.
  _StatusChip.line(SplitOutcome outcome)
    : this(
        switch (outcome) {
          SplitOutcome.success => 'Successful',
          SplitOutcome.pending => 'Processing',
          SplitOutcome.failed => 'Failed',
          SplitOutcome.skipped => 'Skipped',
        },
        switch (outcome) {
          SplitOutcome.success => _Tone.good,
          SplitOutcome.pending => _Tone.waiting,
          SplitOutcome.failed => _Tone.bad,
          SplitOutcome.skipped => _Tone.neutral,
        },
      );

  final String label;
  final _Tone tone;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (tone) {
      _Tone.good => (const Color(0xFFEEF5F0), const Color(0xFF387647)),
      _Tone.bad => (const Color(0xFFFEF3F2), AppColors.error),
      _Tone.neutral => (const Color(0xFFF2F4F7), AppColors.body),
      _Tone.waiting => (const Color(0xFFFFF6E5), const Color(0xFFB54708)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(fontSize: 12, color: foreground)),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    ),
  );
}

/// A short explanation with at most one next step.
class _Notice extends StatelessWidget {
  const _Notice({
    required this.message,
    this.alert = false,
    this.action,
    this.onRetry,
  });
  final String message;
  final bool alert;

  /// A link label and the route it opens.
  final (String, String)? action;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    liveRegion: alert,
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: alert ? const Color(0xFFFEF3F2) : AppColors.primaryLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: alert ? const Color(0xFFFDA29B) : AppColors.primaryBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 4,
        children: [
          Text(
            message,
            style: AppTypography.body.copyWith(
              color: alert ? AppColors.error : AppColors.body,
            ),
          ),
          if (action case (final label, final route))
            AppTextLink(label: label, onPressed: () => context.push(route)),
          if (onRetry != null)
            AppTextLink(label: 'Try again', onPressed: onRetry),
        ],
      ),
    ),
  );
}
