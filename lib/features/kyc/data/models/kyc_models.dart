import 'package:paysplit/core/network/api_exception.dart';
import 'package:paysplit/core/network/json.dart';
import 'package:paysplit/features/auth/data/models/auth_models.dart';

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

  /// The API has been seen to send `not_started`, `in_progress`,
  /// `action_required` (after a failed identity attempt) and `approved`.
  /// The review, rejection and re-verification names are not confirmed;
  /// anything unrecognised is treated as action required, which sends the
  /// user back into the flow instead of locking them out.
  factory KycStatus.fromApi(String value) => switch (value) {
    'not_started' => unverified,
    'in_progress' => inProgress,
    'action_required' => actionRequired,
    'approved' => approved,
    'pending_review' => inReview,
    'rejected' => rejected,
    'reverification_required' => reverificationRequired,
    _ => actionRequired,
  };
}

enum IdentityRegion {
  nigeria,
  international;

  static IdentityRegion fromApi(String value) => switch (value) {
    'nigeria' => nigeria,
    'international' => international,
    _ => throw ApiException.invalidResponse,
  };
}

enum IdentityDocument {
  bvn('bvn', 'BVN'),
  nin('nin', 'NIN'),
  driversLicense('drivers_license', 'Drivers License'),
  passport('passport', 'International Passport');

  const IdentityDocument(this.apiValue, this.label);
  final String apiValue;
  final String label;

  static IdentityDocument? fromApi(String? value) =>
      values.where((document) => document.apiValue == value).firstOrNull;
}

/// A country PaySplit supports, with the ID methods accepted there.
class ResidenceCountry {
  const ResidenceCountry({
    required this.code,
    required this.name,
    required this.dialCode,
    required this.region,
    required this.documents,
  });

  factory ResidenceCountry.fromJson(Object? value) {
    final json = Json.from(value);
    return ResidenceCountry(
      code: json.string('code'),
      name: json.string('name'),
      dialCode: json.string('dialCode'),
      region: IdentityRegion.fromApi(json.string('region')),
      documents: json.list(
        'methods',
        (item) =>
            IdentityDocument.fromApi(item is String ? item : null) ??
            (throw ApiException.invalidResponse),
      ),
    );
  }

  final String code, name, dialCode;
  final IdentityRegion region;
  final List<IdentityDocument> documents;

  @override
  bool operator ==(Object other) =>
      other is ResidenceCountry && other.code == code;
  @override
  int get hashCode => code.hashCode;
}

/// One verification step: its outcome and how many tries are left.
///
/// The defaults describe a step before the server's stepper has loaded.
class KycStep {
  const KycStep({
    this.status = 'not_started',
    this.failureReason,
    this.attemptsRemaining,
  });

  factory KycStep.fromJson(Json json) => KycStep(
    status: json.string('status'),
    failureReason: json.stringOrNull('failureReason'),
    attemptsRemaining: json.integer('attemptsRemaining'),
  );

  final String status;

  /// The reason code of a failed attempt.
  final String? failureReason;
  final int? attemptsRemaining;

  bool get passed => status == 'passed';
  bool get failed => status == 'failed';
}

/// The server's view of the three-step "Complete KYC" stepper.
class KycVerification {
  const KycVerification({
    required this.status,
    required this.currentStep,
    required this.profileCompleted,
    required this.identity,
    required this.liveness,
    required this.onboarding,
    this.countryCode,
    this.phoneNumber,
    this.identityMethod,
    this.maskedIdNumber,
  });

  factory KycVerification.fromJson(Object? value) {
    final json = Json.from(value);
    final steps = json.object('steps');
    final profile = steps.object('profile');
    final identity = steps.object('identity');
    return KycVerification(
      status: KycStatus.fromApi(json.string('kycStatus')),
      currentStep: json.string('currentStep'),
      profileCompleted: profile.boolean('completed'),
      countryCode: profile.stringOrNull('countryCode'),
      phoneNumber: profile.stringOrNull('phoneNumber'),
      identity: KycStep.fromJson(identity),
      identityMethod: IdentityDocument.fromApi(identity.stringOrNull('method')),
      maskedIdNumber: identity.stringOrNull('maskedIdNumber'),
      liveness: KycStep.fromJson(steps.object('liveness')),
      onboarding: Onboarding.fromJson(json.object('onboarding')),
    );
  }

  final KycStatus status;

  /// `profile`, `identity` or `liveness`: the step to resume at, or
  /// `completed` once all three have passed.
  final String currentStep;
  final bool profileCompleted;

  /// Null until the profile step is saved.
  final String? countryCode, phoneNumber;

  /// Null until an ID has been submitted.
  final IdentityDocument? identityMethod;
  final String? maskedIdNumber;
  final KycStep identity, liveness;
  final Onboarding onboarding;
}
