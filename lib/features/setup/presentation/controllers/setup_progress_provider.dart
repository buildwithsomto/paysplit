import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paysplit/features/destinations/presentation/controllers/destinations_controller.dart';
import 'package:paysplit/features/kyc/presentation/controllers/kyc_controller.dart';
import 'package:paysplit/features/rules/presentation/controllers/rules_controller.dart';
import 'package:paysplit/features/setup/presentation/controllers/setup_controller.dart';

/// Derived completion for the local, post-signup UI preview.
/// This is configuration progress, never financial eligibility.
@immutable
class SetupProgress {
  const SetupProgress({
    required this.identityStatus,
    required this.salaryComplete,
    required this.walletComplete,
    required this.beneficiaryComplete,
    required this.ruleComplete,
  });
  final KycStatus identityStatus;
  final bool salaryComplete;
  final bool walletComplete;
  final bool beneficiaryComplete;
  final bool ruleComplete;

  bool get identityComplete => identityStatus == KycStatus.approved;
  bool get configurationComplete =>
      salaryComplete && walletComplete && beneficiaryComplete && ruleComplete;
  // The checklist is reached after signup/login, or explicitly from showcase.
  int get completedSteps =>
      1 + (identityComplete ? 1 : 0) + (configurationComplete ? 1 : 0);
  double get fraction => completedSteps / 3;
  int get percent => (fraction * 100).round();
  bool get complete => completedSteps == 3;
}

final setupProgressProvider = Provider<SetupProgress>((ref) {
  final destinations = ref.watch(destinationsControllerProvider);
  return SetupProgress(
    identityStatus: ref.watch(kycControllerProvider.select((s) => s.status)),
    salaryComplete: ref.watch(
      setupControllerProvider.select((s) => s.salarySourceComplete),
    ),
    walletComplete: destinations.wallets.isNotEmpty,
    beneficiaryComplete: destinations.beneficiaries.isNotEmpty,
    ruleComplete: ref.watch(rulesControllerProvider).isNotEmpty,
  );
});
