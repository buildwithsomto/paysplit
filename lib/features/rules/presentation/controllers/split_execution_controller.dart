import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paysplit/features/destinations/presentation/controllers/destinations_controller.dart';
import 'package:paysplit/features/kyc/presentation/controllers/kyc_controller.dart';
import 'package:paysplit/features/rules/presentation/controllers/rules_controller.dart';

enum SplitOutcome { success, pending, failed, skipped }

enum SplitScenario { successful, mixed, pending }

@immutable
class SplitLine {
  const SplitLine({
    required this.ruleId,
    required this.name,
    required this.destination,
    required this.type,
    required this.priority,
    required this.requestedMinor,
    required this.availableBeforeMinor,
    required this.outcome,
    this.actualMinor = 0,
    this.reason,
  });
  final String ruleId, name, destination;
  final RuleDestinationType type;
  final int priority, requestedMinor, availableBeforeMinor, actualMinor;
  final SplitOutcome outcome;
  final String? reason;
}

@immutable
class SplitExecution {
  SplitExecution({
    required this.id,
    required this.at,
    required this.salaryMinor,
    required this.availableMinor,
    required List<SplitLine> lines,
  }) : lines = List.unmodifiable(lines);
  final String id;
  final DateTime at;
  final int salaryMinor, availableMinor;
  final List<SplitLine> lines;
  int total(SplitOutcome status) => lines
      .where((l) => l.outcome == status)
      .fold(
        0,
        (sum, l) =>
            sum +
            (status == SplitOutcome.success ? l.actualMinor : l.requestedMinor),
      );
  int allocated(RuleDestinationType type) => lines
      .where((l) => l.outcome == SplitOutcome.success && l.type == type)
      .fold(0, (sum, l) => sum + l.actualMinor);
  int get remainingMinor =>
      availableMinor -
      total(SplitOutcome.success) -
      total(SplitOutcome.pending);
  String get status => lines.any((l) => l.outcome == SplitOutcome.pending)
      ? 'Pending confirmation'
      : lines.every((l) => l.outcome == SplitOutcome.success)
      ? 'Successful'
      : lines.any((l) => l.outcome == SplitOutcome.success)
      ? 'Partially completed'
      : 'Failed';
}

@immutable
class SplitExecutionState {
  const SplitExecutionState({
    this.sample = false,
    this.salaryMinor = 0,
    this.availableMinor = 0,
    this.scenario = SplitScenario.successful,
    this.consumed = false,
    this.executions = const [],
    this.error,
  });
  final bool sample, consumed;
  final int salaryMinor, availableMinor;
  final SplitScenario scenario;
  final List<SplitExecution> executions;
  final String? error;
  SplitExecutionState copyWith({
    bool? consumed,
    List<SplitExecution>? executions,
    String? error,
  }) => SplitExecutionState(
    sample: sample,
    salaryMinor: salaryMinor,
    availableMinor: availableMinor,
    scenario: scenario,
    consumed: consumed ?? this.consumed,
    executions: List.unmodifiable(executions ?? this.executions),
    error: error,
  );
}

@immutable
class SplitReview {
  const SplitReview({
    required this.signature,
    required this.salaryMinor,
    required this.availableMinor,
    required this.lines,
    required this.blocks,
    required this.sample,
  });
  final String signature;
  final int salaryMinor, availableMinor;
  final List<SplitLine> lines;
  final List<String> blocks;
  final bool sample;
  bool get canPreview => sample && blocks.isEmpty && lines.isNotEmpty;
}

List<SplitRule> _active(List<SplitRule> rules) =>
    rules.where((r) => r.status == RuleStatus.active).toList()..sort(
      (a, b) => a.priority != b.priority
          ? a.priority.compareTo(b.priority)
          : a.order.compareTo(b.order),
    );

BeneficiaryViewData? _beneficiary(
  SplitRule rule,
  DestinationsState destinations,
) => rule.type == RuleDestinationType.beneficiary
    ? destinations.beneficiaries
          .where((b) => b.id == rule.destinationId)
          .firstOrNull
    : null;

String _destinationLabel(SplitRule rule, DestinationsState destinations) {
  final beneficiary = _beneficiary(rule, destinations);
  return beneficiary == null
      ? ruleDestinationName(rule, destinations)
      : '${beneficiary.name} · ${beneficiary.bank} · ${beneficiary.maskedAccount}';
}

/// Presentation simulation only: percentages use the salary baseline, pending
/// allocations reserve their full amount, and confirmed failures release it.
List<SplitLine> simulateSplit(
  List<SplitRule> rules,
  DestinationsState destinations,
  int salaryMinor,
  int availableMinor, {
  SplitScenario scenario = SplitScenario.successful,
}) {
  assert(salaryMinor >= 0 && availableMinor >= 0);
  var remaining = availableMinor;
  final lines = <SplitLine>[];
  for (final (index, rule) in _active(rules).indexed) {
    final requested = rule.requestedMinor(salaryMinor);
    final before = remaining;
    final outcome = requested > remaining
        ? SplitOutcome.skipped
        : scenario == SplitScenario.pending
        ? SplitOutcome.pending
        : scenario == SplitScenario.mixed && index == 1
        ? SplitOutcome.pending
        : scenario == SplitScenario.mixed && index == 2
        ? SplitOutcome.failed
        : SplitOutcome.success;
    if (outcome == SplitOutcome.success || outcome == SplitOutcome.pending) {
      remaining -= requested;
    }
    lines.add(
      SplitLine(
        ruleId: rule.id,
        name: rule.name,
        destination: _destinationLabel(rule, destinations),
        type: rule.type,
        priority: rule.priority,
        requestedMinor: requested,
        availableBeforeMinor: before,
        outcome: outcome,
        actualMinor: outcome == SplitOutcome.success ? requested : 0,
        reason: switch (outcome) {
          SplitOutcome.skipped =>
            'Insufficient eligible funds. No partial allocation.',
          SplitOutcome.failed =>
            'Sample provider rejection. No successful allocation.',
          SplitOutcome.pending =>
            'Awaiting sample confirmation. Do not retry an uncertain allocation.',
          SplitOutcome.success => null,
        },
      ),
    );
  }
  return List.unmodifiable(lines);
}

class SplitExecutionController extends Notifier<SplitExecutionState> {
  int _sequence = 0;
  @override
  SplitExecutionState build() => const SplitExecutionState();
  void loadSample({
    int salaryMinor = 85000000,
    int availableMinor = 40000000,
    SplitScenario scenario = SplitScenario.mixed,
  }) {
    assert(
      salaryMinor > 0 && availableMinor >= 0 && availableMinor <= salaryMinor,
    );
    state = SplitExecutionState(
      sample: true,
      salaryMinor: salaryMinor,
      availableMinor: availableMinor,
      scenario: scenario,
      executions: state.executions,
    );
  }

  SplitReview review() => buildSplitReview(
    state,
    ref.read(rulesControllerProvider),
    ref.read(destinationsControllerProvider),
    ref.read(kycControllerProvider).status,
  );
  String? confirmPreview(String reviewedSignature) {
    final latest = review();
    if (!latest.canPreview || latest.signature != reviewedSignature) {
      state = state.copyWith(
        error: state.consumed
            ? 'This sample pay cycle has already been previewed.'
            : 'The rules or eligibility changed. Review the updated allocations before continuing.',
      );
      return null;
    }
    final execution = SplitExecution(
      id: 'SAMPLE-RUN-${++_sequence}',
      at: DateTime.now(),
      salaryMinor: state.salaryMinor,
      availableMinor: state.availableMinor,
      lines: simulateSplit(
        ref.read(rulesControllerProvider),
        ref.read(destinationsControllerProvider),
        state.salaryMinor,
        state.availableMinor,
        scenario: state.scenario,
      ),
    );
    state = state.copyWith(
      consumed: true,
      executions: [execution, ...state.executions],
    );
    return execution.id;
  }
}

SplitReview buildSplitReview(
  SplitExecutionState state,
  List<SplitRule> rules,
  DestinationsState destinations,
  KycStatus status,
) {
  final active = _active(rules);
  final blocks = <String>[
    if (status != KycStatus.approved)
      'Identity verification must be approved before a financial split can run.',
    if (active.isEmpty)
      'There are no active rules. Review and activate a rule first.',
    if (!state.sample)
      'No confirmed salary funds or payment permissions are connected. Real execution is unavailable.',
    if (state.sample && state.availableMinor == 0)
      'There are no eligible, unallocated sample funds.',
    if (state.consumed)
      'This sample pay cycle was already previewed. Its funds cannot be allocated a second time.',
  ];
  // Structured equality token, kept in memory only. Includes the full payment
  // target so edits with identical names or last four digits invalidate review.
  final signature = jsonEncode([
    state.sample,
    state.salaryMinor,
    state.availableMinor,
    state.scenario.name,
    state.consumed,
    status.name,
    for (final rule in active)
      [
        rule.id,
        rule.name,
        rule.units,
        rule.method.name,
        rule.priority,
        rule.order,
        rule.type.name,
        rule.destinationId,
        _destinationLabel(rule, destinations),
        _beneficiary(rule, destinations)?.accountNumber,
      ],
  ]);
  return SplitReview(
    signature: signature,
    salaryMinor: state.salaryMinor,
    availableMinor: state.availableMinor,
    sample: state.sample,
    blocks: List.unmodifiable(blocks),
    lines: simulateSplit(
      active,
      destinations,
      state.salaryMinor,
      state.availableMinor,
    ),
  );
}

final splitExecutionProvider =
    NotifierProvider<SplitExecutionController, SplitExecutionState>(
      SplitExecutionController.new,
    );
final splitReviewProvider = Provider<SplitReview>(
  (ref) => buildSplitReview(
    ref.watch(splitExecutionProvider),
    ref.watch(rulesControllerProvider),
    ref.watch(destinationsControllerProvider),
    ref.watch(kycControllerProvider).status,
  ),
);
