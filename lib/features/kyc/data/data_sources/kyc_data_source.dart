import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paysplit/core/network/api_client.dart';
import 'package:paysplit/core/network/api_request.dart';
import 'package:paysplit/core/network/network_providers.dart';

class KycDataSource {
  const KycDataSource(this._client);
  final ApiClient _client;

  Future<Object?> countries() =>
      _client.get('/kyc/countries', request: ApiRequest.public);
  Future<Object?> status() => _client.get('/kyc/status');
  Future<Object?> saveProfile(String countryCode, String phoneNumber) =>
      _client.put(
        '/kyc/profile',
        data: {'countryCode': countryCode, 'phoneNumber': phoneNumber},
      );
  Future<Object?> verifyNigeria(String method, String idNumber) => _client.post(
    '/kyc/identity/nigeria',
    data: {'method': method, 'idNumber': idNumber},
  );
  Future<Object?> uploadInternational(
    String documentType,
    ApiFile front,
    ApiFile? back,
  ) => _client.upload(
    '/kyc/identity/international',
    fields: {'documentType': documentType},
    files: [front, ?back],
  );
  Future<Object?> liveness(ApiFile selfie) =>
      _client.upload('/kyc/liveness', files: [selfie]);
}

final kycDataSourceProvider = Provider<KycDataSource>(
  (ref) => KycDataSource(ref.watch(apiClientProvider)),
);
