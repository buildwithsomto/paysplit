import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paysplit/core/network/api_client.dart';
import 'package:paysplit/core/network/network_providers.dart';

class RulesDataSource {
  const RulesDataSource(this._client);
  final ApiClient _client;

  Future<Object?> summary() => _client.get('/split-rules/summary');
  Future<Object?> rules(Map<String, Object?> query) =>
      _client.get('/split-rules', query: query);
  Future<Object?> create(Map<String, Object?> body) =>
      _client.post('/split-rules', data: body);
  Future<Object?> update(String id, Map<String, Object?> body) =>
      _client.patch('/split-rules/${pathSegment(id)}', data: body);
  Future<Object?> delete(String id) =>
      _client.delete('/split-rules/${pathSegment(id)}');

  /// Run Now. Moves money: never retried automatically.
  Future<Object?> run() => _client.post('/split-runs');
  Future<Object?> runs(Map<String, Object?> query) =>
      _client.get('/split-runs', query: query);
  Future<Object?> runDetail(String id) =>
      _client.get('/split-runs/${pathSegment(id)}');
}

final rulesDataSourceProvider = Provider<RulesDataSource>(
  (ref) => RulesDataSource(ref.watch(apiClientProvider)),
);
