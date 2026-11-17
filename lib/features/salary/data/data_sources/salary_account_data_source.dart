import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paysplit/core/network/api_client.dart';
import 'package:paysplit/core/network/network_providers.dart';

class SalaryAccountDataSource {
  const SalaryAccountDataSource(this._client);
  final ApiClient _client;

  Future<Object?> account() => _client.get('/salary-account');
  Future<Object?> addIdentity(String method, String idNumber) => _client.post(
    '/salary-account/identity',
    data: {'method': method, 'idNumber': idNumber},
  );

  /// Dev/QA backends only (`PAYMENTS_SIMULATION=true`).
  Future<Object?> simulateCredit(Map<String, Object?> body) =>
      _client.post('/salary-account/simulate-credit', data: body);
}

final salaryAccountDataSourceProvider = Provider<SalaryAccountDataSource>(
  (ref) => SalaryAccountDataSource(ref.watch(apiClientProvider)),
);
