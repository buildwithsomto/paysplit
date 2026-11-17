import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paysplit/core/network/api_client.dart';
import 'package:paysplit/core/network/api_exception.dart';
import 'package:paysplit/core/presentation/content_phase.dart';
import 'package:paysplit/core/session/session_providers.dart';
import 'package:paysplit/features/auth/presentation/controllers/account_controller.dart';
import 'package:paysplit/features/kyc/data/models/kyc_models.dart';
import 'package:paysplit/features/kyc/data/repositories/kyc_repository.dart';

@immutable
class KycState {
  const KycState({
    this.countries = const [],
    this.country,
    this.dialCode = '+234',
    this.phone = '',
    this.region = IdentityRegion.nigeria,
    this.document = IdentityDocument.bvn,
    this.documentName,
    this.backDocumentName,
    this.errors = const {},
    this.status = KycStatus.unverified,
    this.verification,
    this.phase = ContentPhase.loading,
    this.busy = false,
  });
  final List<ResidenceCountry> countries;
  final ResidenceCountry? country;
  final String dialCode;
  final String phone;
  final IdentityRegion region;
  final IdentityDocument document;
  final String? documentName, backDocumentName;

  /// Keyed by form field; `form` holds a failure that belongs to no field.
  final Map<String, String> errors;
  final KycStatus status;

  /// The server's stepper, once loaded.
  final KycVerification? verification;
  final ContentPhase phase;
  final bool busy;

  /// The ID types accepted for the selected region.
  List<IdentityDocument> get documents => switch (country) {
    final country? when country.region == region => country.documents,
    _ when region == IdentityRegion.nigeria => const [
      IdentityDocument.bvn,
      IdentityDocument.nin,
    ],
    _ => const [IdentityDocument.driversLicense, IdentityDocument.passport],
  };

  KycState copyWith({
    List<ResidenceCountry>? countries,
    ResidenceCountry? country,
    String? dialCode,
    String? phone,
    IdentityRegion? region,
    IdentityDocument? document,
    String? documentName,
    String? backDocumentName,
    bool clearDocument = false,
    bool clearBackDocument = false,
    Map<String, String>? errors,
    KycStatus? status,
    KycVerification? verification,
    ContentPhase? phase,
    bool? busy,
  }) => KycState(
    countries: countries ?? this.countries,
    country: country ?? this.country,
    dialCode: dialCode ?? this.dialCode,
    phone: phone ?? this.phone,
    region: region ?? this.region,
    document: document ?? this.document,
    documentName: clearDocument ? null : documentName ?? this.documentName,
    backDocumentName: clearDocument || clearBackDocument
        ? null
        : backDocumentName ?? this.backDocumentName,
    errors: Map.unmodifiable(errors ?? this.errors),
    status: status ?? this.status,
    verification: verification ?? this.verification,
    phase: phase ?? this.phase,
    busy: busy ?? this.busy,
  );
}

typedef _PickedFile = ({Uint8List bytes, String name, String contentType});

/// The three-step identity verification, backed by `/kyc`.
/// Identity numbers and document bytes never enter shared state.
class KycController extends Notifier<KycState> {
  static const maxUploadBytes = 2 * 1024 * 1024;

  int _generation = 0;
  _PickedFile? _front, _back;

  KycRepository get _repository => ref.read(kycRepositoryProvider);

  @override
  KycState build() {
    final userId = ref.watch(sessionUserIdProvider);
    final generation = ++_generation;
    _front = _back = null;
    ref.onDispose(() => _generation++);
    // Sign-in, setup and dashboard calls all report the KYC status; adopt it
    // without resetting a form the user may be filling in.
    ref.listen(onboardingProvider.select((o) => o.kycStatus), (previous, next) {
      state = state.copyWith(status: KycStatus.fromApi(next));
    });
    if (userId != null) {
      Future.microtask(() {
        if (ref.mounted && generation == _generation) load();
      });
    }
    return KycState(
      status: KycStatus.fromApi(ref.read(onboardingProvider).kycStatus),
      phase: userId == null ? ContentPhase.ready : ContentPhase.loading,
    );
  }

  Future<void> load() async {
    final generation = _generation;
    // Only the first load fills the form from the saved profile; a later
    // refresh must not undo what the user has picked since.
    final firstLoad = state.verification == null;
    state = state.copyWith(
      phase: firstLoad ? ContentPhase.loading : ContentPhase.refreshing,
    );
    try {
      final (countries, verification) = await (
        state.countries.isEmpty
            ? _repository.countries()
            : Future.value(state.countries),
        _repository.status(),
      ).wait;
      if (!ref.mounted || generation != _generation) return;
      state = state.copyWith(countries: countries, phase: ContentPhase.ready);
      _adopt(verification, restoreForm: firstLoad);
    } on Object catch (error) {
      if (!ref.mounted || generation != _generation) return;
      final cause = failureCause(error);
      state = state.copyWith(phase: ContentPhase.failure(cause));
    }
  }

  /// Takes a fresh server stepper and shares its onboarding progress.
  void _adopt(KycVerification verification, {bool restoreForm = false}) {
    ref
        .read(accountControllerProvider.notifier)
        .apply(onboarding: verification.onboarding);
    var next = state.copyWith(
      verification: verification,
      status: verification.status,
    );
    if (restoreForm) {
      final country = state.countries
          .where((c) => c.code == verification.countryCode)
          .firstOrNull;
      if (country != null) {
        final number = verification.phoneNumber ?? '';
        next = next.copyWith(
          country: country,
          dialCode: country.dialCode,
          phone: number.startsWith(country.dialCode)
              ? number.substring(country.dialCode.length)
              : number.replaceAll(RegExp(r'\D'), ''),
          region: country.region,
          document:
              verification.identityMethod ??
              country.documents.firstOrNull ??
              next.document,
        );
      }
    }
    state = next;
  }

  void selectCountry(ResidenceCountry country) {
    state = state.copyWith(
      country: country,
      dialCode: country.dialCode,
      errors: {...state.errors}..remove('country'),
    );
    selectRegion(country.region);
  }

  void selectDialCode(String code) => state = state.copyWith(dialCode: code);

  void selectRegion(IdentityRegion region) {
    _front = _back = null;
    state = state.copyWith(
      region: region,
      clearDocument: true,
      errors: const {},
    );
    state = state.copyWith(document: state.documents.first);
  }

  void selectDocument(IdentityDocument document) {
    _front = _back = null;
    state = state.copyWith(
      document: document,
      clearDocument: true,
      errors: const {},
    );
  }

  void clearError(String key) =>
      state = state.copyWith(errors: {...state.errors}..remove(key));

  /// Step 1: country and mobile number.
  Future<bool> submitBasics(String phone) async {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    final errors = <String, String>{};
    final totalLength = state.dialCode.length - 1 + digits.length;
    if (digits.length < 7 || totalLength > 15) {
      errors['phone'] = 'Enter a valid phone number.';
    }
    final country = state.country;
    if (country == null) errors['country'] = 'Select your residence country.';
    state = state.copyWith(phone: digits, errors: errors);
    if (country == null || errors.isNotEmpty) return false;
    // A leading trunk zero is dropped once the calling code is prefixed.
    final national = digits.replaceFirst(RegExp(r'^0+'), '');
    return _submit(
      () => _repository.saveProfile(
        countryCode: country.code,
        phoneNumber: '${state.dialCode}$national',
      ),
      field: 'phone',
    );
  }

  /// Validates a picked document and keeps its bytes for the upload.
  bool selectFile(String name, Uint8List bytes, {bool back = false}) {
    final type = switch (name.toLowerCase().split('.').last) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      _ => null,
    };
    final error = type == null
        ? 'Choose a JPG or PNG image.'
        : bytes.isEmpty || bytes.length > maxUploadBytes
        ? 'Choose an image smaller than 2 MB.'
        : null;
    final picked = type != null && error == null
        ? (bytes: bytes, name: name, contentType: type)
        : null;
    final key = back ? 'backFile' : 'file';
    final errors = {...state.errors}..remove(key);
    if (error != null) errors[key] = error;
    if (back) {
      _back = picked;
      state = state.copyWith(
        backDocumentName: picked?.name,
        clearBackDocument: picked == null,
        errors: errors,
      );
    } else {
      _front = picked;
      // A new front invalidates a back picked for the previous document.
      _back = null;
      state = state.copyWith(clearDocument: true, errors: errors);
      state = state.copyWith(documentName: picked?.name);
    }
    return error == null;
  }

  void removeFile({bool back = false}) {
    if (back) {
      _back = null;
      state = state.copyWith(clearBackDocument: true);
    } else {
      _front = _back = null;
      state = state.copyWith(clearDocument: true);
    }
  }

  /// Step 2: a BVN/NIN lookup, or an uploaded passport or licence.
  Future<bool> submitIdentity(String identityNumber) async {
    final nigeria = state.region == IdentityRegion.nigeria;
    final front = _front, back = _back;
    final errors = <String, String>{};
    if (nigeria && !RegExp(r'^\d{11}$').hasMatch(identityNumber)) {
      errors['identity'] =
          'Enter the 11 digits of your ${state.document.label}.';
    } else if (!nigeria && front == null) {
      errors['file'] = 'Select an identity document to continue.';
    }
    state = state.copyWith(errors: errors);
    if (errors.isNotEmpty) return false;
    final ok = await _submit(
      () => nigeria || front == null
          ? _repository.verifyNigeria(
              method: state.document,
              idNumber: identityNumber,
            )
          : _repository.uploadInternational(
              document: state.document,
              front: _part('front', front),
              back: back == null ? null : _part('back', back),
            ),
      field: nigeria ? 'identity' : 'file',
    );
    if (ok) {
      _front = _back = null;
      state = state.copyWith(clearDocument: true);
    }
    return ok;
  }

  ApiFile _part(String field, _PickedFile file) => ApiFile(
    field: field,
    bytes: file.bytes,
    filename: file.name,
    contentType: file.contentType,
  );

  /// Step 3: the selfie. Returns false when the check did not pass.
  Future<bool> submitSelfie(
    Uint8List bytes, {
    required String filename,
    required String contentType,
  }) async {
    if (bytes.isEmpty || bytes.length > maxUploadBytes) {
      state = state.copyWith(
        errors: {'selfie': 'That photo is too large. Try again.'},
      );
      return false;
    }
    return _submit(
      () => _repository.submitSelfie(
        ApiFile(
          field: 'selfie',
          bytes: bytes,
          filename: filename,
          contentType: contentType,
        ),
      ),
      field: 'selfie',
    );
  }

  Future<bool> _submit(
    Future<KycVerification> Function() request, {
    required String field,
  }) async {
    if (state.busy) return false;
    final generation = _generation;
    state = state.copyWith(busy: true, errors: const {});
    try {
      final verification = await request();
      if (!ref.mounted || generation != _generation) return false;
      state = state.copyWith(busy: false);
      _adopt(verification);
      return true;
    } on Object catch (error) {
      if (!ref.mounted || generation != _generation) return false;
      final attempts = error is ApiException ? error.attemptsRemaining : null;
      // A rejected attempt changes the server's stepper; keep it in step.
      if (attempts != null) unawaited(load());
      final message = [
        describeError(error),
        if (attempts != null && attempts > 0)
          '$attempts ${attempts == 1 ? 'attempt' : 'attempts'} left.',
      ].join(' ');
      // Server-side rejections belong to the field; outages do not.
      final domain =
          error is ApiException &&
          const [400, 409, 422, 429].contains(error.statusCode);
      state = state.copyWith(
        busy: false,
        errors: {domain ? field : 'form': message},
      );
      return false;
    }
  }
}

final kycControllerProvider = NotifierProvider<KycController, KycState>(
  KycController.new,
);

/// Where an unfinished verification resumes, so a returning user is never
/// asked to repeat a step the server has already accepted.
final kycResumeRouteProvider = Provider<String>((ref) {
  final step = ref.watch(
    kycControllerProvider.select((s) => s.verification?.currentStep),
  );
  return switch (step) {
    'identity' => '/kyc/identity',
    'liveness' => '/kyc/liveness',
    _ => '/kyc',
  };
});
