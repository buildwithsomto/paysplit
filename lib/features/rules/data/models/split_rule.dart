import 'package:flutter/foundation.dart';
import 'package:paysplit/core/formatting/money.dart';
import 'package:paysplit/core/network/api_exception.dart';
import 'package:paysplit/core/network/json.dart';

enum RuleDestinationType {
  wallet,
  beneficiary;

  static RuleDestinationType fromApi(String value) => switch (value) {
    'wallet' => wallet,
    'beneficiary' => beneficiary,
    _ => throw ApiException.invalidResponse,
  };
}

enum AllocationMethod {
  fixed('Fixed Amount'),
  percentage('Percentage');

  const AllocationMethod(this.label);
  final String label;

  static AllocationMethod fromApi(String value) => switch (value) {
    'fixed' => fixed,
    'percentage' => percentage,
    _ => throw ApiException.invalidResponse,
  };

  /// Reads an amount as the user typed it: kobo for [fixed], basis points
  /// for [percentage] (10000 = 100%). Both take at most two decimals, so one
  /// exact parser serves. Null when [text] is not such an amount.
  int? parse(String text) =>
      this == percentage &&
          !RegExp(r'^\d{1,3}(?:\.\d{1,2})?$').hasMatch(text.trim())
      ? null
      : Money.parse(text);
}

enum RuleStatus {
  active('Active'),
  paused('Paused');

  const RuleStatus(this.label);
  final String label;

  static RuleStatus fromApi(String value) => switch (value) {
    'active' => active,
    'paused' => paused,
    _ => throw ApiException.invalidResponse,
  };
}

/// A checked rule form, ready to send.
@immutable
class RuleInput {
  const RuleInput({
    required this.name,
    required this.type,
    required this.destinationId,
    required this.method,
    required this.units,
    required this.priority,
  });
  final String name;
  final RuleDestinationType type;
  final String destinationId;
  final AllocationMethod method;

  /// Kobo for a fixed amount; basis points for a percentage (10000 = 100%).
  final int units;
  final int priority;
}

/// One split rule: where a share of salary goes, how much, and in what order.
///
/// `{id, name, priority, status, destinationType, destination: {id, name},
/// method, value, allocatedThisMonth, createdAt, updatedAt}`.
@immutable
class SplitRule {
  const SplitRule({
    required this.id,
    required this.name,
    required this.type,
    required this.destinationId,
    required this.destinationName,
    required this.method,
    required this.units,
    required this.priority,
    required this.status,
    required this.allocatedThisMonthMinor,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SplitRule.fromJson(Object? value) {
    final json = Json.from(value);
    final destination = json.object('destination');
    final method = AllocationMethod.fromApi(json.string('method'));
    final raw = json.number('value');
    return SplitRule(
      id: json.string('id'),
      name: json.string('name'),
      type: RuleDestinationType.fromApi(json.string('destinationType')),
      destinationId: destination.string('id'),
      destinationName: destination.string('name'),
      method: method,
      // Percent with up to two decimals becomes exact basis points.
      units: method == AllocationMethod.percentage
          ? (raw * 100).round()
          : raw.round(),
      priority: json.integer('priority'),
      status: RuleStatus.fromApi(json.string('status')),
      allocatedThisMonthMinor: json.integer('allocatedThisMonth'),
      createdAt: json.date('createdAt'),
      updatedAt: json.date('updatedAt'),
    );
  }

  /// The order rules run in, which is also the order the server lists them:
  /// lower priority first, then the older rule.
  static int byPriority(SplitRule a, SplitRule b) => a.priority != b.priority
      ? a.priority.compareTo(b.priority)
      : a.createdAt.compareTo(b.createdAt);

  final String id;
  final String name;
  final RuleDestinationType type;
  final String destinationId;

  /// The destination's name as the server reported it with the rule.
  final String destinationName;
  final AllocationMethod method;

  /// Kobo for fixed rules; basis points for percentage rules (10000 = 100%).
  final int units;
  final int priority;
  final RuleStatus status;

  /// Kobo this rule has moved since the start of the month.
  final int allocatedThisMonthMinor;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get allocationLabel => method == AllocationMethod.fixed
      ? Money.format(units)
      : '${units ~/ 100}${units % 100 == 0 ? '' : '.${(units % 100).toString().padLeft(2, '0')}'}%';

  /// The allocation as the user would type it: `50,000` naira, or `12.5`
  /// percent.
  String get editableValue => method == AllocationMethod.fixed
      ? Money.plain(units)
      : '${apiValue(method, units)}';

  /// What this rule takes from [baseMinor] kobo.
  int requestedMinor(int baseMinor) =>
      method == AllocationMethod.fixed ? units : (baseMinor * units) ~/ 10000;

  /// The `value` the API expects: kobo, or a percent such as `12.5`.
  static num apiValue(AllocationMethod method, int units) =>
      method == AllocationMethod.fixed
      ? units
      : units % 100 == 0
      ? units ~/ 100
      : units / 100;
}

/// One rule's share of the expected salary, as a part of the allocation bar.
@immutable
class AllocationSegment {
  const AllocationSegment({required this.name, required this.amountMinor});

  factory AllocationSegment.fromJson(Object? value) {
    final json = Json.from(value);
    return AllocationSegment(
      name: json.string('name'),
      amountMinor: json.integer('amount'),
    );
  }

  /// The rule's name.
  final String name;
  final int amountMinor;
}

/// `GET /split-rules/summary`: the figures behind the allocation bar,
/// `{baselineSalary, totalAllocated, allocatedPercent, remainder,
/// segments: [{name, amount}]}`.
@immutable
class RulesSummary {
  const RulesSummary({
    required this.baselineSalary,
    required this.totalAllocated,
    required this.allocatedPercent,
    required this.remainder,
    required this.segments,
  });

  factory RulesSummary.fromJson(Object? value) {
    final json = Json.from(value);
    return RulesSummary(
      baselineSalary: json.integerOrNull('baselineSalary'),
      totalAllocated: json.integer('totalAllocated'),
      allocatedPercent: json.number('allocatedPercent'),
      remainder: json.integer('remainder'),
      segments: json.list('segments', AllocationSegment.fromJson),
    );
  }

  /// The expected monthly salary in kobo; null until income is set up.
  final int? baselineSalary;

  /// Kobo the active rules take from the baseline, and what is left of it.
  final int totalAllocated, remainder;

  /// [totalAllocated] as a share of the baseline, 0-100.
  final double allocatedPercent;

  /// One entry per active rule, in the order the rules run.
  final List<AllocationSegment> segments;
}

enum SplitOutcome {
  success,
  pending,
  failed,
  skipped;

  /// A transaction's `status` as an outcome for its rule. A transfer that
  /// has neither succeeded nor failed is still on its way.
  static SplitOutcome fromApi(String status) => switch (status) {
    'success' => success,
    'failed' || 'reversed' => failed,
    _ => pending,
  };
}

/// One rule's result within a split run, or its estimate before one.
@immutable
class SplitLine {
  const SplitLine({
    required this.name,
    required this.destination,
    required this.requestedMinor,
    required this.outcome,
    this.priority,
    this.reason,
    this.transactionId,
  });

  /// A transaction the run created: `narration` carries the rule's name.
  factory SplitLine.fromTransaction(Object? value) {
    final json = Json.from(value);
    return SplitLine(
      name: json.stringOrNull('narration') ?? json.string('title'),
      destination: json.object('destination').string('name'),
      requestedMinor: json.integer('amount').abs(),
      outcome: SplitOutcome.fromApi(json.string('status')),
      transactionId: json.string('id'),
    );
  }

  /// A rule the run left out: `{ruleName, amount, reason}`.
  factory SplitLine.fromSkipped(Object? value) {
    final json = Json.from(value);
    return SplitLine(
      name: json.string('ruleName'),
      destination: '',
      requestedMinor: json.integer('amount').abs(),
      outcome: SplitOutcome.skipped,
      reason: switch (json.string('reason')) {
        'insufficient_funds' => insufficientFunds,
        // Any other reason code is shown as words, its underscores
        // turned into spaces.
        final code => _sentence(code),
      },
    );
  }

  /// Why a rule that does not fit the balance is skipped.
  static const insufficientFunds = 'Not enough balance left for this rule.';

  /// The rule's name.
  final String name;

  /// The destination's name; empty for a skipped rule, which names none.
  final String destination;

  /// Kobo the rule asked for; for a completed line, what it moved.
  final int requestedMinor;
  final SplitOutcome outcome;

  /// The rule's priority. Only an estimate carries it.
  final int? priority;
  final String? reason;

  /// The ledger entry this line produced, when there is one.
  final String? transactionId;
}

String _sentence(String code) {
  final words = code.replaceAll('_', ' ').trim();
  return words.isEmpty
      ? words
      : '${words[0].toUpperCase()}${words.substring(1)}.';
}

enum SplitRunStatus {
  completed('Successful'),
  partial('Partially completed'),
  processing('Processing'),
  failed('Failed');

  const SplitRunStatus(this.label);
  final String label;

  static SplitRunStatus fromApi(String value) => switch (value) {
    'completed' => completed,
    'partial' => partial,
    'processing' => processing,
    'failed' => failed,
    _ => throw ApiException.invalidResponse,
  };
}

/// A split run: an automatic split after a salary credit, or Run Now.
///
/// `{id, trigger, status, availableAmount, toWallets, toBeneficiaries, fees,
/// skipped: [...], createdAt}`; the detail and Run Now answers add
/// `transactions`.
@immutable
class SplitExecution {
  SplitExecution({
    required this.id,
    required this.at,
    required this.manual,
    required this.status,
    required this.availableMinor,
    required this.toWalletsMinor,
    required this.toBeneficiariesMinor,
    required this.feesMinor,
    required List<SplitLine> lines,
  }) : lines = List.unmodifiable(lines);

  factory SplitExecution.fromJson(Object? value) {
    final json = Json.from(value);
    return SplitExecution(
      id: json.string('id'),
      at: json.date('createdAt'),
      manual: json.string('trigger') == 'manual',
      status: SplitRunStatus.fromApi(json.string('status')),
      availableMinor: json.integer('availableAmount'),
      toWalletsMinor: json.integer('toWallets'),
      toBeneficiariesMinor: json.integer('toBeneficiaries'),
      feesMinor: json.integer('fees'),
      lines: [
        // Newest first from the server; rules ran in the opposite order.
        // The list endpoint leaves the transactions out.
        ...json.listOrEmpty('transactions', SplitLine.fromTransaction).reversed,
        ...json.list('skipped', SplitLine.fromSkipped),
      ],
    );
  }

  final String id;
  final DateTime at;

  /// True for Run Now (`trigger: manual`); otherwise the run followed a
  /// salary credit.
  final bool manual;
  final SplitRunStatus status;

  /// The salary account balance the run shared out, in kobo.
  final int availableMinor;
  final int toWalletsMinor, toBeneficiariesMinor, feesMinor;

  /// Completed and skipped rules. The list endpoint sends only the skipped.
  final List<SplitLine> lines;

  /// Kobo the run moved out of the salary account.
  int get totalMinor => toWalletsMinor + toBeneficiariesMinor;

  /// Kobo in transfers that have not settled yet.
  int get pendingMinor => lines
      .where((l) => l.outcome == SplitOutcome.pending)
      .fold(0, (sum, l) => sum + l.requestedMinor);
}

/// Thrown by Run Now when no answer came back: the split may have happened.
const splitOutcomeUnknown = ApiException(
  code: 'split_outcome_unknown',
  message:
      'We couldn’t confirm whether the split ran. Check Split History before trying again.',
  kind: ApiFailureKind.network,
);
