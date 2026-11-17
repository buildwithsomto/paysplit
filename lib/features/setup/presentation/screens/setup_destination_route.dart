import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paysplit/features/destinations/presentation/controllers/beneficiary_editor_controller.dart';
import 'package:paysplit/features/destinations/presentation/controllers/destinations_controller.dart';
import 'package:paysplit/features/destinations/presentation/controllers/wallet_editor_controller.dart';
import 'package:paysplit/features/destinations/presentation/screens/beneficiary_editor_screen.dart';
import 'package:paysplit/features/destinations/presentation/screens/wallet_editor_screen.dart';
import 'package:paysplit/theme/app_theme.dart';
import 'package:paysplit/widgets/feedback/skeleton.dart';

/// Setup steps 2 and 3. Reopening setup edits the first wallet or
/// beneficiary the account already has instead of creating a duplicate.
class SetupDestinationRoute extends ConsumerStatefulWidget {
  const SetupDestinationRoute({this.beneficiary = false, super.key});
  final bool beneficiary;
  @override
  ConsumerState<SetupDestinationRoute> createState() =>
      _SetupDestinationRouteState();
}

class _SetupDestinationRouteState extends ConsumerState<SetupDestinationRoute> {
  /// Decided once the lists have loaded, then kept so a save does not swap
  /// the form out from under the user.
  bool _resolved = false;
  Wallet? _wallet;
  Beneficiary? _beneficiary;

  void _resolve(DestinationsState state) {
    if (_resolved || !(state.hasData || state.phase.isFailure)) return;
    _resolved = true;
    _wallet = state.wallets.firstOrNull;
    _beneficiary = state.beneficiaries.firstOrNull;
  }

  @override
  Widget build(BuildContext context) {
    _resolve(ref.watch(destinationsControllerProvider));
    if (!_resolved) {
      // Dark status bar icons from the first frame: this page opens over
      // the dashboard's dark header.
      return const AnnotatedRegion<SystemUiOverlayStyle>(
        value: AppTheme.systemOverlay,
        child: Scaffold(
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 96, 16, 16),
              child: SkeletonLoader(
                label: 'Loading your setup',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox.card(height: 56),
                    SizedBox(height: 32),
                    SkeletonForm(fields: 4),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    if (widget.beneficiary) {
      return ProviderScope(
        overrides: [
          beneficiaryEditorControllerProvider.overrideWith(
            () => BeneficiaryEditorController(initial: _beneficiary),
          ),
        ],
        child: BeneficiaryEditorScreen(setup: true, initial: _beneficiary),
      );
    }
    return ProviderScope(
      overrides: [
        walletEditorControllerProvider.overrideWith(
          () => WalletEditorController(initial: _wallet),
        ),
      ],
      child: WalletEditorScreen(setup: true, initial: _wallet),
    );
  }
}
