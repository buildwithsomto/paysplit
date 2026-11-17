import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paysplit/core/network/api_exception.dart';
import 'package:paysplit/core/network/json.dart';
import 'package:paysplit/features/auth/data/models/auth_models.dart';
import 'package:paysplit/features/rules/data/data_sources/rules_data_source.dart';
import 'package:paysplit/features/rules/data/models/split_rule.dart';

class RulesRepository {
  const RulesRepository(this._source);
  final RulesDataSource _source;

  /// The API returns at most 100 rules per page; the list stops at
  /// [_maxPages] pages.
  static const _pageSize = 100;
  static const _maxPages = 5;

  Future<RulesSummary> summary() async =>
      RulesSummary.fromJson(await _source.summary());

  /// Every rule, in the server's priority order.
  Future<List<SplitRule>> rules() async {
    final all = <SplitRule>[];
    for (var page = 1; page <= _maxPages; page++) {
      final result = ApiPage.fromJson(
        await _source.rules({'page': page, 'limit': _pageSize}),
        SplitRule.fromJson,
      );
      all.addAll(result.items);
      if (!result.hasNextPage) break;
    }
    return all;
  }

  Map<String, Object?> _body(RuleInput input) => {
    'name': input.name,
    'priority': input.priority,
    'destinationType': input.type.name,
    if (input.type == RuleDestinationType.wallet)
      'walletId': input.destinationId
    else
      'beneficiaryId': input.destinationId,
    'method': input.method.name,
    'value': SplitRule.apiValue(input.method, input.units),
  };

  /// Creates an active rule. The answer is `{rule, onboarding}`: a first
  /// rule completes a setup step.
  Future<({SplitRule rule, Onboarding onboarding})> create(
    RuleInput input,
  ) async {
    final answer = Json.from(await _source.create(_body(input)));
    return (
      rule: SplitRule.fromJson(answer.object('rule')),
      onboarding: Onboarding.fromJson(answer.object('onboarding')),
    );
  }

  /// Edits a rule; its status is left as it is.
  Future<SplitRule> update(String id, RuleInput input) async =>
      SplitRule.fromJson(await _source.update(id, _body(input)));

  /// Pauses or resumes a rule without touching its allocation.
  Future<SplitRule> setStatus(String id, RuleStatus status) async =>
      SplitRule.fromJson(await _source.update(id, {'status': status.name}));

  Future<void> delete(String id) async {
    await _source.delete(id);
  }

  /// Run Now. A connection failure after sending, or an answer that cannot
  /// be read, leaves the outcome unknown, so it is reported as such and never
  /// retried here.
  Future<SplitExecution> run() async {
    try {
      return SplitExecution.fromJson(await _source.run());
    } on ApiException catch (error) {
      if (error.isConnectivity ||
          error.kind == ApiFailureKind.invalidResponse) {
        throw splitOutcomeUnknown;
      }
      rethrow;
    }
  }

  Future<ApiPage<SplitExecution>> runs({
    required int page,
    int limit = 20,
  }) async => ApiPage.fromJson(
    await _source.runs({'page': page, 'limit': limit}),
    SplitExecution.fromJson,
  );

  Future<SplitExecution> runDetail(String id) async =>
      SplitExecution.fromJson(await _source.runDetail(id));
}

final rulesRepositoryProvider = Provider<RulesRepository>(
  (ref) => RulesRepository(ref.watch(rulesDataSourceProvider)),
);
