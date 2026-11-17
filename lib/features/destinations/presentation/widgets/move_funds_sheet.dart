import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paysplit/core/formatting/money.dart';
import 'package:paysplit/core/network/api_exception.dart';
import 'package:paysplit/features/destinations/presentation/controllers/destinations_controller.dart';
import 'package:paysplit/theme/app_colors.dart';
import 'package:paysplit/theme/app_typography.dart';
import 'package:paysplit/widgets/buttons/app_button.dart';
import 'package:paysplit/widgets/feedback/app_notice.dart';
import 'package:paysplit/widgets/inputs/app_input_field.dart';
import 'package:paysplit/widgets/overlays/editor_sheet_layout.dart';

/// "Move": sends money from a wallet back to the salary account.
/// Resolves to true once the move has gone through.
Future<bool> showMoveFundsSheet(
  BuildContext context, {
  required Wallet wallet,
  required int availableMinor,
}) async =>
    await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (_) =>
          _MoveFundsSheet(wallet: wallet, availableMinor: availableMinor),
    ) ??
    false;

class _MoveFundsSheet extends ConsumerStatefulWidget {
  const _MoveFundsSheet({required this.wallet, required this.availableMinor});
  final Wallet wallet;
  final int availableMinor;
  @override
  ConsumerState<_MoveFundsSheet> createState() => _MoveFundsSheetState();
}

class _MoveFundsSheetState extends ConsumerState<_MoveFundsSheet> {
  final _amount = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _move() async {
    if (_busy) return;
    FocusManager.instance.primaryFocus?.unfocus();
    final amount = Money.parse(_amount.text);
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter an amount greater than zero.');
      return;
    }
    if (amount > widget.availableMinor) {
      setState(
        () => _error =
            'You can move up to ${Money.format(widget.availableMinor)}.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(destinationsControllerProvider.notifier)
          .moveFromWallet(widget.wallet.id, amount);
      if (!mounted) return;
      Navigator.pop(context, true);
    } on Object catch (failure) {
      if (!mounted) return;
      final connectivity = failure is ApiException && failure.isConnectivity;
      setState(() {
        _busy = false;
        // A money movement is never retried blindly: the first request may
        // have gone through even though no answer came back.
        _error = connectivity
            ? 'We couldn’t confirm this move. Check the wallet’s activity before trying again.'
            : describeError(failure);
      });
      if (connectivity) {
        showAppNotice(
          context,
          'Connection lost before the move was confirmed.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => EditorSheetLayout(
    title: 'Move to Salary Account',
    height: 420,
    onClose: () => Navigator.pop(context, false),
    bottom: AppButton(label: 'Move Funds', busy: _busy, onPressed: _move),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primaryBorder),
          ),
          child: Row(
            spacing: 12,
            children: [
              Expanded(
                child: Text(
                  'Available in ${widget.wallet.name}',
                  style: AppTypography.body,
                ),
              ),
              Text(
                Money.format(widget.availableMinor),
                style: AppTypography.label.copyWith(
                  fontSize: 16,
                  color: AppColors.heading,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppInputField(
          label: 'Amount (₦)',
          controller: _amount,
          hint: 'e.g 50,000',
          error: _error,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _move(),
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
        ),
      ],
    ),
  );
}
