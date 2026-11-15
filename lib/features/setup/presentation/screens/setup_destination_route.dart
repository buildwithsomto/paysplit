import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paysplit/features/destinations/presentation/controllers/beneficiary_editor_controller.dart';
import 'package:paysplit/features/destinations/presentation/controllers/destinations_controller.dart';
import 'package:paysplit/features/destinations/presentation/controllers/wallet_editor_controller.dart';
import 'package:paysplit/features/destinations/presentation/screens/beneficiary_editor_screen.dart';
import 'package:paysplit/features/destinations/presentation/screens/wallet_editor_screen.dart';

/// Reopening setup edits its existing first destination instead of duplicating it.
class SetupDestinationRoute extends ConsumerWidget {
  const SetupDestinationRoute({this.beneficiary = false, super.key});
  final bool beneficiary;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final destinations = ref.read(destinationsControllerProvider);
    if (beneficiary) {
      final initial = destinations.beneficiaries.firstOrNull;
      return ProviderScope(
        overrides: [
          beneficiaryEditorControllerProvider.overrideWith(
            () => BeneficiaryEditorController(initial: initial),
          ),
        ],
        child: BeneficiaryEditorScreen(setup: true, initial: initial),
      );
    }
    final initial = destinations.wallets.firstOrNull;
    return ProviderScope(
      overrides: [
        walletEditorControllerProvider.overrideWith(
          () => WalletEditorController(initial: initial),
        ),
      ],
      child: WalletEditorScreen(setup: true, initial: initial),
    );
  }
}
