import 'package:paysplit/core/network/json.dart';
import 'package:paysplit/core/session/auth_session.dart';

/// The signed-in person as the API describes them.
class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    this.countryCode,
    this.profileImageUrl,
  });

  factory AppUser.fromJson(Object? value) {
    final json = Json.from(value);
    return AppUser(
      id: json.string('id'),
      email: json.string('email'),
      firstName: json.string('firstName'),
      lastName: json.string('lastName'),
      phoneNumber: json.stringOrNull('phoneNumber'),
      countryCode: json.stringOrNull('countryCode'),
      profileImageUrl: json.stringOrNull('profileImageUrl'),
    );
  }

  final String id, email, firstName, lastName;

  /// Set by the KYC profile step.
  final String? phoneNumber, countryCode;

  /// Null while the user has no profile picture.
  final String? profileImageUrl;
  String get fullName => '$firstName $lastName'.trim();

  /// [profileImageUrl] is a callback so the picture can also be cleared:
  /// `copyWith(profileImageUrl: () => null)`.
  AppUser copyWith({String? Function()? profileImageUrl}) => AppUser(
    id: id,
    email: email,
    firstName: firstName,
    lastName: lastName,
    phoneNumber: phoneNumber,
    countryCode: countryCode,
    profileImageUrl: profileImageUrl == null
        ? this.profileImageUrl
        : profileImageUrl(),
  );

  @override
  String toString() => 'AppUser([redacted])';
}

/// The four-step "Complete your account setup" checklist.
class SetupChecklist {
  const SetupChecklist({
    this.salaryDateSet = false,
    this.hasWallet = false,
    this.hasBeneficiary = false,
    this.hasSplitRule = false,
    this.completed = false,
  });

  factory SetupChecklist.fromJson(Json json) => SetupChecklist(
    salaryDateSet: json.boolean('salaryDateSet'),
    hasWallet: json.boolean('hasWallet'),
    hasBeneficiary: json.boolean('hasBeneficiary'),
    hasSplitRule: json.boolean('hasSplitRule'),
    completed: json.boolean('completed'),
  );

  final bool salaryDateSet, hasWallet, hasBeneficiary, hasSplitRule;

  /// Every step above is done.
  final bool completed;
}

/// Server-owned onboarding progress. It is returned by sign-in, KYC, setup
/// and dashboard calls, so every one of them can refresh the same state.
///
/// The defaults describe an account whose progress has not loaded yet.
class Onboarding {
  const Onboarding({
    this.kycStatus = 'not_started',
    this.checklist = const SetupChecklist(),
    this.percent = 0,
  });

  factory Onboarding.fromJson(Object? value) {
    final json = Json.from(value);
    return Onboarding(
      kycStatus: json.string('kycStatus'),
      checklist: SetupChecklist.fromJson(json.object('setupChecklist')),
      percent: json.object('progress').integer('percent'),
    );
  }

  /// The overall verification status, for example `approved`.
  final String kycStatus;
  final SetupChecklist checklist;

  /// Signup, KYC and setup together, 0-100.
  final int percent;

  bool get kycApproved => kycStatus == 'approved';
}

/// A code was emailed; [resendAvailableIn] drives the resend countdown.
class CodeDelivery {
  const CodeDelivery(this.resendAvailableIn);

  factory CodeDelivery.fromJson(Object? value) {
    final seconds =
        Json.fromOrNull(value)?.integerOrNull('resendAvailableInSeconds') ?? 60;
    return CodeDelivery(Duration(seconds: seconds.clamp(0, 3600)));
  }

  final Duration resendAvailableIn;
}

/// Proof that the email was verified, exchanged for a password and a session.
class EmailVerification {
  const EmailVerification(this.setupToken);

  factory EmailVerification.fromJson(Object? value) =>
      EmailVerification(Json.from(value).string('setupToken'));

  final String setupToken;

  @override
  String toString() => 'EmailVerification([redacted])';
}

class Account {
  const Account(this.user, this.onboarding);

  factory Account.fromJson(Object? value) {
    final json = Json.from(value);
    return Account(
      AppUser.fromJson(json.object('user')),
      Onboarding.fromJson(json.object('onboarding')),
    );
  }

  final AppUser user;
  final Onboarding onboarding;
}

class SignedIn {
  const SignedIn(this.session, this.account);

  factory SignedIn.fromJson(Object? value, {required DateTime now}) => SignedIn(
    AuthSession.fromResponse(value, now: now),
    Account.fromJson(value),
  );

  final AuthSession session;
  final Account account;

  @override
  String toString() => 'SignedIn([redacted])';
}
