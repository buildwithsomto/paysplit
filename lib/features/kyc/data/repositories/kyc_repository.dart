import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paysplit/core/network/api_client.dart';
import 'package:paysplit/core/network/json.dart';
import 'package:paysplit/features/kyc/data/data_sources/kyc_data_source.dart';
import 'package:paysplit/features/kyc/data/models/kyc_models.dart';

class KycRepository {
  const KycRepository(this._source);
  final KycDataSource _source;

  Future<List<ResidenceCountry>> countries() async =>
      jsonList(await _source.countries(), ResidenceCountry.fromJson);

  Future<KycVerification> status() async =>
      KycVerification.fromJson(await _source.status());

  Future<KycVerification> saveProfile({
    required String countryCode,
    required String phoneNumber,
  }) async => KycVerification.fromJson(
    await _source.saveProfile(countryCode, phoneNumber),
  );

  Future<KycVerification> verifyNigeria({
    required IdentityDocument method,
    required String idNumber,
  }) async => KycVerification.fromJson(
    await _source.verifyNigeria(method.apiValue, idNumber),
  );

  Future<KycVerification> uploadInternational({
    required IdentityDocument document,
    required ApiFile front,
    ApiFile? back,
  }) async {
    await _source.uploadInternational(document.apiValue, front, back);
    return status();
  }

  /// A passing selfie approves KYC; the answer is the updated stepper.
  Future<KycVerification> submitSelfie(ApiFile selfie) async =>
      KycVerification.fromJson(await _source.liveness(selfie));
}

final kycRepositoryProvider = Provider<KycRepository>(
  (ref) => KycRepository(ref.watch(kycDataSourceProvider)),
);
