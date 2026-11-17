import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paysplit/core/network/api_client.dart';
import 'package:paysplit/core/network/network_providers.dart';

class SetupDataSource {
  const SetupDataSource(this._client);
  final ApiClient _client;

  Future<Object?> income() => _client.get('/setup/income');
  Future<Object?> saveIncome(Map<String, Object?> body) =>
      _client.put('/setup/income', data: body);
}

final setupDataSourceProvider = Provider<SetupDataSource>(
  (ref) => SetupDataSource(ref.watch(apiClientProvider)),
);
