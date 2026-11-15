import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paysplit/core/formatting/money.dart';
import 'package:paysplit/features/destinations/presentation/controllers/destinations_controller.dart';
import 'package:paysplit/features/kyc/presentation/controllers/kyc_controller.dart';

enum RuleDestinationType { wallet, beneficiary }

enum AllocationMethod { fixed, percentage }

enum RuleStatus { draft, active, paused }

@immutable
class RuleInput {
  const RuleInput({
    required this.name,
    required this.type,
    required this.destinationId,
    required this.method,
    required this.value,
    required this.priority,
  });
  final String name;
  final RuleDestinationType type;
  final String? destinationId;
  final AllocationMethod method;
  final String value;
  final int priority;
  // Money.parse is also an exact two-decimal parser for percentage basis points.
  int? get units =>
      method == AllocationMethod.percentage &&
          !RegExp(r'^\d{1,3}(?:\.\d{1,2})?$').hasMatch(value.trim())
      ? null
      : Money.parse(value);
}

@immutable
class SplitRule {
  const SplitRule({
    required this.id,
    required this.name,
    required this.type,
    required this.destinationId,
    required this.method,
    required this.units,
    required this.priority,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.order,
  });
  final String id;
  final String name;
  final RuleDestinationType type;
  final String destinationId;
  final AllocationMethod method;

  /// Kobo for fixed rules; basis points for percentage rules (10000 = 100%).
  final int units;
  final int priority;
  final RuleStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int order;
  String get allocationLabel => method == AllocationMethod.fixed
      ? Money.format(units)
      : '${units ~/ 100}${units % 100 == 0 ? '' : '.${(units % 100).toString().padLeft(2, '0')}'}%';
  RuleInput get input => RuleInput(
    name: name,
    type: type,
    destinationId: destinationId,
    method: method,
    value: '${units ~/ 100}.${(units % 100).toString().padLeft(2, '0')}',
    priority: priority,
  );
  int requestedMinor(int originalSalaryMinor) =>
      method == AllocationMethod.fixed
      ? units
      : (originalSalaryMinor * units) ~/ 10000;
}

/// Local configuration only. No funds are reserved, transferred or executed here.
class RulesController extends Notifier<List<SplitRule>> {
  int _sequence = 0;
  @override
  List<SplitRule> build() {
    ref.listen(destinationsControllerProvider, (previous, next) {
      final ids = {
        ...next.wallets.map((w) => w.id),
        ...next.beneficiaries.map((b) => b.id),
      };
      state = List.unmodifiable(
        state.where((rule) => ids.contains(rule.destinationId)),
      );
    });
    return const [];
  }

  SplitRule? forDestination(String id) =>
      state.where((rule) => rule.destinationId == id).firstOrNull;
  String? get activationBlock =>
      ref.read(kycControllerProvider).status == KycStatus.approved
      ? null
      : 'Complete identity verification before activating a rule. You can save a draft now.';

  Map<String, String> validate(RuleInput input, {String? id}) {
    final errors = <String, String>{};
    if (input.name.trim().isEmpty) errors['name'] = 'Enter a rule name.';
    if (input.name.trim().length > 60) {
      errors['name'] = 'Use at most 60 characters.';
    }
    if (input.priority < 1 || input.priority > 10) {
      errors['priority'] = 'Choose a priority from 1 to 10.';
    }
    final destinations = ref.read(destinationsControllerProvider);
    final exists = input.type == RuleDestinationType.wallet
        ? destinations.wallets.any((w) => w.id == input.destinationId)
        : destinations.beneficiaries.any((b) => b.id == input.destinationId);
    if (!exists) errors['destination'] = 'Select a saved destination.';
    if (state.any(
      (rule) => rule.id != id && rule.destinationId == input.destinationId,
    )) {
      errors['destination'] =
          'This destination already has a rule. Reconfigure its existing rule.';
    }
    final units = input.units;
    if (units == null ||
        units <= 0 ||
        (input.method == AllocationMethod.percentage && units > 10000)) {
      errors['value'] = input.method == AllocationMethod.percentage
          ? 'Enter a percentage above 0 and no more than 100, with at most two decimals.'
          : 'Enter an amount greater than zero, with at most two decimals.';
    }
    return Map.unmodifiable(errors);
  }

  SplitRule? save(
    RuleInput input, {
    String? id,
    RuleStatus status = RuleStatus.draft,
  }) {
    if (validate(input, id: id).isNotEmpty ||
        (status == RuleStatus.active && activationBlock != null)) {
      return null;
    }
    final old = state.where((rule) => rule.id == id).firstOrNull;
    final now = DateTime.now();
    final order = old?.order ?? ++_sequence;
    final rule = SplitRule(
      id: old?.id ?? 'rule-$order',
      name: input.name.trim(),
      type: input.type,
      destinationId: input.destinationId!,
      method: input.method,
      units: input.units!,
      priority: input.priority,
      status: status,
      createdAt: old?.createdAt ?? now,
      updatedAt: now,
      order: order,
    );
    final rules = [...state.where((r) => r.id != rule.id), rule]
      ..sort(
        (a, b) => a.priority != b.priority
            ? a.priority.compareTo(b.priority)
            : a.order.compareTo(b.order),
      );
    state = List.unmodifiable(rules);
    return rule;
  }

  void pause(String id) {
    final rule = state.where((r) => r.id == id).firstOrNull;
    if (rule?.status == RuleStatus.active) {
      save(rule!.input, id: id, status: RuleStatus.paused);
    }
  }

  void delete(String id) =>
      state = List.unmodifiable(state.where((rule) => rule.id != id));
}

final rulesControllerProvider =
    NotifierProvider<RulesController, List<SplitRule>>(RulesController.new);

String ruleDestinationName(SplitRule rule, DestinationsState destinations) =>
    rule.type == RuleDestinationType.wallet
    ? destinations.wallets
              .where((w) => w.id == rule.destinationId)
              .firstOrNull
              ?.name ??
          'Removed wallet'
    : destinations.beneficiaries
              .where((b) => b.id == rule.destinationId)
              .firstOrNull
              ?.name ??
          'Removed beneficiary';

/// A non-executing estimate. Each percentage uses the ORIGINAL salary. Rules
/// that cannot be covered in full are skipped, leaving funds for later rules.
List<({SplitRule rule, int amountMinor, bool skipped})> previewAllocations(
  List<SplitRule> rules,
  int salaryMinor,
) {
  var remaining = salaryMinor;
  final ordered = rules.where((r) => r.status == RuleStatus.active).toList()
    ..sort(
      (a, b) => a.priority != b.priority
          ? a.priority.compareTo(b.priority)
          : a.order.compareTo(b.order),
    );
  final result = <({SplitRule rule, int amountMinor, bool skipped})>[];
  for (final rule in ordered) {
    final amount = rule.requestedMinor(salaryMinor);
    final skipped = amount > remaining;
    if (!skipped) remaining -= amount;
    result.add((
      rule: rule,
      amountMinor: skipped ? 0 : amount,
      skipped: skipped,
    ));
  }
  return List.unmodifiable(result);
}
