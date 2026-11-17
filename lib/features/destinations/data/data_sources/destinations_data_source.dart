import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paysplit/core/network/api_client.dart';
import 'package:paysplit/core/network/api_request.dart';
import 'package:paysplit/core/network/network_providers.dart';

/// Wallets, beneficiaries and the reference lists their forms need.
class DestinationsDataSource {
  const DestinationsDataSource(this._client);
  final ApiClient _client;

  Future<Object?> categories() =>
      _client.get('/categories', request: ApiRequest.public);

  // Wallets
  Future<Object?> wallets() => _client.get('/wallets');
  Future<Object?> accentColors() => _client.get('/wallets/accent-colors');
  Future<Object?> wallet(String id) =>
      _client.get('/wallets/${pathSegment(id)}');
  Future<Object?> createWallet(Map<String, Object?> body) =>
      _client.post('/wallets', data: body);
  Future<Object?> updateWallet(String id, Map<String, Object?> body) =>
      _client.patch('/wallets/${pathSegment(id)}', data: body);
  Future<Object?> deleteWallet(String id) =>
      _client.delete('/wallets/${pathSegment(id)}');
  Future<Object?> walletActivity(Map<String, Object?> query) =>
      _client.get('/wallets/activity', query: query);
  Future<Object?> walletTransactions(String id, Map<String, Object?> query) =>
      _client.get('/wallets/${pathSegment(id)}/transactions', query: query);
  Future<Object?> moveFromWallet(String id, int amount) => _client.post(
    '/wallets/${pathSegment(id)}/move',
    data: {'amount': amount},
  );

  // Beneficiaries
  Future<Object?> banks() => _client.get('/banks');
  Future<Object?> resolveAccount(String bankCode, String accountNumber) =>
      _client.post(
        '/beneficiaries/resolve',
        data: {'bankCode': bankCode, 'accountNumber': accountNumber},
      );
  Future<Object?> beneficiaries(Map<String, Object?> query) =>
      _client.get('/beneficiaries', query: query);
  Future<Object?> createBeneficiary(Map<String, Object?> body) =>
      _client.post('/beneficiaries', data: body);
  Future<Object?> beneficiary(String id) =>
      _client.get('/beneficiaries/${pathSegment(id)}');
  Future<Object?> updateBeneficiary(String id, Map<String, Object?> body) =>
      _client.patch('/beneficiaries/${pathSegment(id)}', data: body);
  Future<Object?> deleteBeneficiary(String id) =>
      _client.delete('/beneficiaries/${pathSegment(id)}');
  Future<Object?> beneficiaryTransactions(
    String id,
    Map<String, Object?> query,
  ) => _client.get(
    '/beneficiaries/${pathSegment(id)}/transactions',
    query: query,
  );
}

final destinationsDataSourceProvider = Provider<DestinationsDataSource>(
  (ref) => DestinationsDataSource(ref.watch(apiClientProvider)),
);
