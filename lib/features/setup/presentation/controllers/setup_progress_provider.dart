import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paysplit/features/auth/presentation/controllers/account_controller.dart';
import 'package:paysplit/features/kyc/data/models/kyc_models.dart';

/// The server's onboarding progress, shaped for the setup overlay and the
/// dashboard card. This is configuration progress, never financial eligibility.
@immutable
class SetupProgress {
  const SetupProgress({
    required this.identityStatus,
    required this.salaryComplete,
    required this.walletComplete,
    required this.beneficiaryComplete,
    required this.ruleComplete,
    required this.configurationComplete,
    required this.percent,
  });
  final KycStatus identityStatus;
  final bool salaryComplete;
  final bool walletComplete;
  final bool beneficiaryComplete;
  final bool ruleComplete;
  final bool configurationComplete;

  /// Reported by the API (34 after signup, 100 when everything is done).
  final int percent;

  bool get identityComplete => identityStatus == KycStatus.approved;
  int get completedSteps =>
      1 + (identityComplete ? 1 : 0) + (configurationComplete ? 1 : 0);
  double get fraction => percent / 100;
  bool get complete => identityComplete && configurationComplete;

  /// The first unfinished stage of the setup checklist.
  String get configurationPath {
    if (!salaryComplete) return '/setup';
    if (!walletComplete) return '/setup/wallet';
    if (!beneficiaryComplete) return '/setup/beneficiary';
    if (!ruleComplete) return '/setup/rule';
    return '/setup';
  }
}

final setupProgressProvider = Provider<SetupProgress>((ref) {
  final onboarding = ref.watch(onboardingProvider);
  final checklist = onboarding.checklist;
  return SetupProgress(
    identityStatus: KycStatus.fromApi(onboarding.kycStatus),
    salaryComplete: checklist.salaryDateSet,
    walletComplete: checklist.hasWallet,
    beneficiaryComplete: checklist.hasBeneficiary,
    ruleComplete: checklist.hasSplitRule,
    configurationComplete: checklist.completed,
    percent: onboarding.percent,
  );
});
