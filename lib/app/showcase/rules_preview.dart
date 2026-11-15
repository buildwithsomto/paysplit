import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paysplit/features/destinations/presentation/controllers/destinations_controller.dart';
import 'package:paysplit/features/home/presentation/controllers/dashboard_controller.dart';
import 'package:paysplit/features/kyc/presentation/controllers/kyc_controller.dart';
import 'package:paysplit/features/rules/presentation/controllers/rules_controller.dart';
import 'package:paysplit/features/setup/presentation/controllers/setup_controller.dart';

/// Invoked only by the explicitly labelled development showcase action.
/// Creates configuration fixtures; wallet balances and actual allocations stay zero.
void loadRulesPreview(WidgetRef ref) {
  ref.read(kycControllerProvider.notifier).previewOutcome(KycStatus.approved);
  ref.read(dashboardControllerProvider.notifier).selectPreview(populated: true);
  final setup = ref.read(setupControllerProvider.notifier);
  setup.updateEmployer('Sample Employer');
  setup.updateSalary('850000');
  setup.setPayDay(25);
  setup.validate();
  final destinations = ref.read(destinationsControllerProvider.notifier);
  final rules = ref.read(rulesControllerProvider.notifier);
  for (final entry in <(String, String, RuleDestinationType, String, int)>[
    (
      'Emergency Buffer',
      'Emergency Wallet',
      RuleDestinationType.wallet,
      '85000',
      1,
    ),
    (
      'Annual Rent Vault',
      'Rent Wallet',
      RuleDestinationType.wallet,
      '200000',
      2,
    ),
    (
      'Mrs. Folashade Adebayo',
      'Mrs. Folashade Adebayo',
      RuleDestinationType.beneficiary,
      '100000',
      3,
    ),
    (
      'Wealth Index Pocket',
      'Wealth Wallet',
      RuleDestinationType.wallet,
      '192500',
      4,
    ),
    (
      'Ikeja Electric Distribution',
      'Ikeja Electric',
      RuleDestinationType.beneficiary,
      '35000',
      5,
    ),
  ]) {
    final data = ref.read(destinationsControllerProvider);
    final id = entry.$3 == RuleDestinationType.wallet
        ? data.wallets.where((w) => w.name == entry.$2).firstOrNull?.id ??
              destinations
                  .saveWallet(
                    name: entry.$2,
                    category: 'Savings',
                    accent: WalletAccent.blue,
                  )
                  .id
        : data.beneficiaries.where((b) => b.name == entry.$2).firstOrNull?.id ??
              destinations
                  .saveBeneficiary(
                    name: entry.$2,
                    bank: 'Demo Bank',
                    accountNumber: '0000001234',
                    category: 'Personal',
                    narration: '',
                  )
                  .id;
    if (rules.forDestination(id) == null) {
      rules.save(
        RuleInput(
          name: entry.$1,
          type: entry.$3,
          destinationId: id,
          method: AllocationMethod.fixed,
          value: entry.$4,
          priority: entry.$5,
        ),
        status: RuleStatus.active,
      );
    }
  }
}
