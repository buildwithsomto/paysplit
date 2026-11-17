import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paysplit/core/network/api_client.dart';
import 'package:paysplit/core/network/network_providers.dart';

class DashboardDataSource {
  const DashboardDataSource(this._client);
  final ApiClient _client;

  Future<Object?> summary() => _client.get('/dashboard/summary');

  /// [from] is `YYYY-MM-DD`; the range runs up to today.
  Future<Object?> cashFlow({required String from}) =>
      _client.get('/dashboard/cash-flow', query: {'from': from});
}

final dashboardDataSourceProvider = Provider<DashboardDataSource>(
  (ref) => DashboardDataSource(ref.watch(apiClientProvider)),
);
