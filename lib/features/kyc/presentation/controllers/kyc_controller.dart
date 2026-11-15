import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum IdentityRegion { nigeria, international }

enum IdentityDocument { bvn, nin, driversLicense, passport }

enum KycStatus {
  unverified('Not started'),
  inProgress('In progress'),
  inReview('Pending review'),
  actionRequired('Action required'),
  approved('Approved'),
  rejected('Rejected'),
  reverificationRequired('Re-verification required');

  const KycStatus(this.label);
  final String label;

  /// Previously verified details cannot be silently changed from Profile.
  bool get identityFieldsLocked =>
      this == approved || this == inReview || this == reverificationRequired;
}

@immutable
class ResidenceCountry {
  const ResidenceCountry(this.name, this.dialCode);
  final String name;
  final String dialCode;
}

/// Representative preview options; supported regions come from the API later.
const previewCountries = [
  ResidenceCountry('Nigeria', '+234'),
  ResidenceCountry('Ghana', '+233'),
  ResidenceCountry('Kenya', '+254'),
  ResidenceCountry('South Africa', '+27'),
  ResidenceCountry('United Kingdom', '+44'),
  ResidenceCountry('United States', '+1'),
  ResidenceCountry('Canada', '+1'),
  ResidenceCountry('Germany', '+49'),
];

@immutable
class KycState {
  const KycState({
    this.country,
    this.dialCode = '+234',
    this.phone = '',
    this.region = IdentityRegion.nigeria,
    this.document = IdentityDocument.bvn,
    this.documentName,
    this.errors = const {},
    this.status = KycStatus.unverified,
  });
  final ResidenceCountry? country;
  final String dialCode;
  final String phone;
  final IdentityRegion region;
  final IdentityDocument document;
  final String? documentName;
  final Map<String, String> errors;
  final KycStatus status;

  KycState copyWith({
    ResidenceCountry? country,
    String? dialCode,
    String? phone,
    IdentityRegion? region,
    IdentityDocument? document,
    String? documentName,
    bool clearDocument = false,
    Map<String, String>? errors,
    KycStatus? status,
  }) => KycState(
    country: country ?? this.country,
    dialCode: dialCode ?? this.dialCode,
    phone: phone ?? this.phone,
    region: region ?? this.region,
    document: document ?? this.document,
    documentName: clearDocument ? null : documentName ?? this.documentName,
    errors: Map.unmodifiable(errors ?? this.errors),
    status: status ?? this.status,
  );
}

class KycController extends Notifier<KycState> {
  @override
  KycState build() => const KycState();

  void selectCountry(ResidenceCountry country) {
    state = state.copyWith(
      country: country,
      dialCode: country.dialCode,
      errors: {...state.errors}..remove('country'),
    );
    selectRegion(
      country.name == 'Nigeria'
          ? IdentityRegion.nigeria
          : IdentityRegion.international,
    );
  }

  void selectDialCode(String code) => state = state.copyWith(dialCode: code);

  void updateProfilePhone(String phone) => state = state.copyWith(phone: phone);

  void selectRegion(IdentityRegion region) => state = state.copyWith(
    region: region,
    document: region == IdentityRegion.nigeria
        ? IdentityDocument.bvn
        : IdentityDocument.driversLicense,
    clearDocument: true,
    errors: const {},
  );

  void selectDocument(IdentityDocument document) => state = state.copyWith(
    document: document,
    clearDocument: true,
    errors: const {},
  );

  void clearError(String key) =>
      state = state.copyWith(errors: {...state.errors}..remove(key));

  bool validateBasics(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    final errors = <String, String>{};
    final totalLength = state.dialCode.length - 1 + digits.length;
    if (digits.length < 7 || totalLength > 15) {
      errors['phone'] = 'Enter a valid phone number.';
    }
    if (state.country == null) {
      errors['country'] = 'Select your residence country.';
    }
    state = state.copyWith(
      phone: digits,
      errors: errors,
      status: errors.isEmpty && state.status == KycStatus.unverified
          ? KycStatus.inProgress
          : state.status,
    );
    return errors.isEmpty;
  }

  bool selectFile(String name, int size) {
    final extension = name.toLowerCase().split('.').last;
    final error = !['jpg', 'jpeg', 'png', 'pdf'].contains(extension)
        ? 'Choose a JPG, PNG or PDF file.'
        : size <= 0 || size > 10 * 1024 * 1024
        ? 'Choose a non-empty file smaller than 10 MB.'
        : null;
    state = state.copyWith(
      documentName: error == null ? name : null,
      clearDocument: error != null,
      errors: {'file': ?error},
    );
    return error == null;
  }

  void removeFile() => state = state.copyWith(clearDocument: true);

  bool validateIdentity(String identityNumber) {
    final errors = <String, String>{};
    if (state.region == IdentityRegion.nigeria &&
        !RegExp(r'^\d{11}$').hasMatch(identityNumber)) {
      errors['identity'] =
          'Enter the 11 digits of your ${documentLabel(state.document)}.';
    } else if (state.region == IdentityRegion.international &&
        state.documentName == null) {
      errors['file'] = 'Select an identity document to continue.';
    }
    state = state.copyWith(errors: errors);
    // Identity numbers are deliberately not retained in shared state.
    return errors.isEmpty;
  }

  void previewOutcome(KycStatus status) =>
      state = state.copyWith(status: status);

  static String documentLabel(IdentityDocument document) => switch (document) {
    IdentityDocument.bvn => 'BVN',
    IdentityDocument.nin => 'NIN',
    IdentityDocument.driversLicense => 'Drivers License',
    IdentityDocument.passport => 'International Passport',
  };
}

final kycControllerProvider = NotifierProvider<KycController, KycState>(
  KycController.new,
);
