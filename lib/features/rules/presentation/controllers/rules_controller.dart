import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paysplit/core/network/api_exception.dart';
import 'package:paysplit/core/presentation/content_phase.dart';
import 'package:paysplit/core/session/ledger_version.dart';
import 'package:paysplit/core/session/session_providers.dart';
import 'package:paysplit/features/auth/presentation/controllers/account_controller.dart';
import 'package:paysplit/features/destinations/presentation/controllers/destinations_controller.dart';
import 'package:paysplit/features/home/presentation/controllers/dashboard_controller.dart';
import 'package:paysplit/features/rules/data/models/split_rule.dart';
import 'package:paysplit/features/rules/data/repositories/rules_repository.dart';

export 'package:paysplit/features/rules/data/models/split_rule.dart'
    show
        AllocationMethod,
        AllocationSegment,
        RuleDestinationType,
        RuleInput,
        RuleStatus,
        RulesSummary,
        SplitRule;

/// How the rule list currently stands with the API.
@immutable
class RulesStatus {
  const RulesStatus({
    this.phase = ContentPhase.loading,
    this.message,
    this.updatedAt,
    this.summary,
  });
  final ContentPhase phase;

  /// The API's explanation of the last failed load.
  final String? message;

  /// Null until the first successful load.
  final DateTime? updatedAt;
  final RulesSummary? summary;

  bool get hasData => updatedAt != null;
}

class RulesStatusController extends Notifier<RulesStatus> {
  @override
  RulesStatus build() => const RulesStatus();
  void set(RulesStatus status) => state = status;
}

final rulesStatusProvider =
    NotifierProvider<RulesStatusController, RulesStatus>(
      RulesStatusController.new,
    );

/// The user's split rules in priority order, backed by `/split-rules`.
/// Writes throw [ApiException] so the form can place the server's answer.
class RulesController extends Notifier<List<SplitRule>> {
  int _generation = 0;
  Future<void>? _loading;

  RulesRepository get _repository => ref.read(rulesRepositoryProvider);

  void _status(RulesStatus status) =>
      ref.read(rulesStatusProvider.notifier).set(status);

  @override
  List<SplitRule> build() {
    final userId = ref.watch(sessionUserIdProvider);
    final generation = ++_generation;
    ref.listen(ledgerVersionProvider, (_, _) => load());
    _loading = null;
    ref.onDispose(() => _generation++);
    // Deleting a wallet or beneficiary deletes its rule on the server too,
    // so the rules are read again when one of their destinations goes.
    ref.listen(destinationsControllerProvider, (previous, next) {
      if (previous == null || !previous.hasData || !next.hasData) return;
      final remaining = {
        ...next.wallets.map((w) => w.id),
        ...next.beneficiaries.map((b) => b.id),
      };
      final gone = {
        ...previous.wallets.map((w) => w.id),
        ...previous.beneficiaries.map((b) => b.id),
      }.difference(remaining);
      if (state.any((rule) => gone.contains(rule.destinationId))) _reload();
    });
    Future.microtask(() {
      if (!ref.mounted || generation != _generation) return;
      _status(
        RulesStatus(
          phase: userId == null ? ContentPhase.ready : ContentPhase.loading,
        ),
      );
      if (userId != null) load();
    });
    return const [];
  }

  /// First load, pull-to-refresh and Retry. Concurrent callers share one run.
  Future<void> load() =>
      _loading ??= _load().whenComplete(() => _loading = null);

  /// Reads the rules and their summary again after something changed them.
  /// A load already in flight may have been answered before the change, so
  /// it is left to finish and a new one follows it.
  Future<void> _reload() async {
    await _loading;
    if (ref.mounted) await load();
  }

  Future<void> _load() async {
    if (ref.read(sessionUserIdProvider) == null) return;
    final generation = _generation;
    final before = ref.read(rulesStatusProvider);
    _status(
      RulesStatus(
        phase: before.hasData ? ContentPhase.refreshing : ContentPhase.loading,
        updatedAt: before.updatedAt,
        summary: before.summary,
      ),
    );
    try {
      final (rules, summary) = await (
        _repository.rules(),
        _repository.summary(),
      ).wait;
      if (!ref.mounted || generation != _generation) return;
      state = List.unmodifiable(rules);
      _status(
        RulesStatus(
          phase: ContentPhase.ready,
          updatedAt: DateTime.now(),
          summary: summary,
        ),
      );
    } on Object catch (error) {
      if (!ref.mounted || generation != _generation) return;
      final cause = failureCause(error);
      // Keep the last loaded rules on screen; only the status changes.
      _status(
        RulesStatus(
          phase: ContentPhase.failure(cause),
          message: describeError(cause),
          updatedAt: before.updatedAt,
          summary: before.summary,
        ),
      );
    }
  }

  /// Checks the rule form before anything is sent. Returns the rule to
  /// send, or the reasons it cannot be sent, keyed by form field. [id] is
  /// the rule being edited, if any.
  ({RuleInput? input, Map<String, String> errors}) check({
    required String name,
    required RuleDestinationType type,
    required String? destinationId,
    required AllocationMethod method,
    required String value,
    required int priority,
    String? id,
  }) {
    final errors = <String, String>{};
    final trimmed = name.trim();
    if (trimmed.isEmpty) errors['name'] = 'Enter a rule name.';
    if (trimmed.length > 80) errors['name'] = 'Use at most 80 characters.';
    if (priority < 1 || priority > 100) {
      errors['priority'] = 'Choose a priority from 1 to 100.';
    }
    final destinations = ref.read(destinationsControllerProvider);
    final exists = type == RuleDestinationType.wallet
        ? destinations.wallets.any((w) => w.id == destinationId)
        : destinations.beneficiaries.any((b) => b.id == destinationId);
    if (!exists) errors['destination'] = 'Select a saved destination.';
    if (state.any(
      (rule) => rule.id != id && rule.destinationId == destinationId,
    )) {
      errors['destination'] =
          'This destination already has a rule. Edit that rule instead.';
    }
    final units = method.parse(value);
    if (units == null ||
        units <= 0 ||
        (method == AllocationMethod.percentage && units > 10000)) {
      errors['value'] = method == AllocationMethod.percentage
          ? 'Enter a percentage above 0 and up to 100, with at most two decimals.'
          : 'Enter an amount greater than zero.';
    }
    if (errors.isNotEmpty || destinationId == null || units == null) {
      return (input: null, errors: Map.unmodifiable(errors));
    }
    return (
      input: RuleInput(
        name: trimmed,
        type: type,
        destinationId: destinationId,
        method: method,
        units: units,
        priority: priority,
      ),
      errors: const {},
    );
  }

  /// Puts a server answer on the form field it is about.
  static Map<String, String> placeError(Object error) {
    final message = describeError(error);
    if (error is! ApiException) return {'form': message};
    return switch (error.code) {
      'KYC_REQUIRED' => {'kyc': message},
      'DESTINATION_HAS_RULE' ||
      'DESTINATION_NOT_FOUND' => {'destination': message},
      'ALLOCATION_EXCEEDS_SALARY' || 'INVALID_RULE_VALUE' => {'value': message},
      _ when error.fieldError('name') != null => {
        'name': 'Check the rule name and try again.',
      },
      _ when error.fieldError('priority') != null => {
        'priority': 'Choose a priority from 1 to 100.',
      },
      _ when error.fieldError('value') != null => {
        'value': 'Enter a valid amount.',
      },
      _ => {'form': message},
    };
  }

  /// Creates the rule, or updates it when [id] is given.
  Future<SplitRule> save(RuleInput input, {String? id}) async {
    final generation = _generation;
    final SplitRule rule;
    if (id == null) {
      final created = await _repository.create(input);
      rule = created.rule;
      if (ref.mounted && generation == _generation) {
        ref
            .read(accountControllerProvider.notifier)
            .apply(onboarding: created.onboarding);
      }
    } else {
      rule = await _repository.update(id, input);
    }
    if (ref.mounted && generation == _generation) {
      _adopt(rule);
      _changed();
    }
    return rule;
  }

  Future<SplitRule> setPaused(String id, bool paused) async {
    final rule = await _repository.setStatus(
      id,
      paused ? RuleStatus.paused : RuleStatus.active,
    );
    if (ref.mounted) {
      _adopt(rule);
      _changed();
    }
    return rule;
  }

  Future<void> delete(String id) async {
    final generation = _generation;
    await _repository.delete(id);
    if (!ref.mounted || generation != _generation) return;
    state = List.unmodifiable(state.where((rule) => rule.id != id));
    ref.read(accountControllerProvider.notifier).load();
    _changed();
  }

  /// Shows a saved [rule] at once, in its place in the running order.
  void _adopt(SplitRule rule) {
    state = List.unmodifiable(
      <SplitRule>[...state.where((r) => r.id != rule.id), rule]
        ..sort(SplitRule.byPriority),
    );
  }

  /// Totals here and elsewhere depend on the rules: read them again.
  void _changed() {
    ref.read(dashboardControllerProvider.notifier).load();
    ref.read(destinationsControllerProvider.notifier).load();
    _reload();
  }
}

final rulesControllerProvider =
    NotifierProvider<RulesController, List<SplitRule>>(RulesController.new);

/// The destination's current name. The loaded wallet or beneficiary is
/// asked first, since it may have been renamed since the rule was read.
String ruleDestinationName(SplitRule rule, DestinationsState destinations) =>
    (rule.type == RuleDestinationType.wallet
        ? destinations.wallet(rule.destinationId)?.name
        : destinations.beneficiary(rule.destinationId)?.name) ??
    rule.destinationName;
