import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paysplit/core/network/api_client.dart';
import 'package:paysplit/core/network/network_providers.dart';

class HistoryDataSource {
  const HistoryDataSource(this._client);
  final ApiClient _client;

  Future<Object?> transactions(Map<String, Object?> query) =>
      _client.get('/transactions', query: query);
  Future<Object?> transaction(String id) =>
      _client.get('/transactions/${pathSegment(id)}');

  /// The statement as CSV text, with the same filters as the list.
  Future<String> export(Map<String, Object?> query) =>
      _client.getText('/transactions/export', query: query);
}

final historyDataSourceProvider = Provider<HistoryDataSource>(
  (ref) => HistoryDataSource(ref.watch(apiClientProvider)),
);
