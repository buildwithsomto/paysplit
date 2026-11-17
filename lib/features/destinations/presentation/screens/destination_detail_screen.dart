import 'package:paysplit/features/history/presentation/widgets/destination_activity.dart';
import 'package:paysplit/features/rules/presentation/widgets/linked_rule_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paysplit/core/formatting/money.dart';
import 'package:paysplit/core/network/api_exception.dart';
import 'package:paysplit/features/destinations/presentation/widgets/move_funds_sheet.dart';
import 'package:paysplit/widgets/feedback/app_notice.dart';
import 'package:paysplit/widgets/feedback/content_status_card.dart';
import 'package:paysplit/widgets/feedback/skeleton.dart';
import 'package:paysplit/widgets/overlays/confirm_sheet.dart';
import 'package:paysplit/features/destinations/presentation/controllers/destinations_controller.dart';
import 'package:paysplit/features/destinations/presentation/screens/beneficiary_editor_screen.dart';
import 'package:paysplit/features/destinations/presentation/screens/wallet_editor_screen.dart';
import 'package:paysplit/features/destinations/presentation/widgets/wallet_summary_card.dart';
import 'package:paysplit/widgets/app_svg_icon.dart';
import 'package:paysplit/widgets/layout/app_page_layout.dart';

class DestinationDetailScreen extends ConsumerWidget {
  const DestinationDetailScreen({
    required this.id,
    this.beneficiary = false,
    super.key,
  });
  final String id;
  final bool beneficiary;

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    String title,
  ) async {
    final confirmed = await showConfirmSheet(
      context,
      title: 'Delete ${beneficiary ? 'beneficiary' : 'wallet'}?',
      message:
          '$title and its split rule will be removed. Your transaction history stays available.',
      action: 'Delete',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    final controller = ref.read(destinationsControllerProvider.notifier);
    try {
      await (beneficiary
          ? controller.removeBeneficiary(id)
          : controller.removeWallet(id));
      if (!context.mounted) return;
      showAppNotice(
        context,
        '${beneficiary ? 'Beneficiary' : 'Wallet'} deleted.',
      );
      context.canPop() ? context.pop() : context.go('/destinations');
    } on Object catch (error) {
      if (context.mounted) showAppNotice(context, describeError(error));
    }
  }

  Future<void> _setPaused(
    BuildContext context,
    WidgetRef ref,
    bool paused,
  ) async {
    try {
      await ref
          .read(destinationsControllerProvider.notifier)
          .setBeneficiaryPaused(id, paused);
      if (context.mounted) {
        showAppNotice(
          context,
          paused
              ? 'Beneficiary paused. Splits will skip it.'
              : 'Beneficiary resumed.',
        );
      }
    } on Object catch (error) {
      if (context.mounted) showAppNotice(context, describeError(error));
    }
  }

  Future<void> _move(
    BuildContext context,
    Wallet wallet,
    int availableMinor,
  ) async {
    if (availableMinor <= 0) {
      showAppNotice(context, 'This wallet has no money to move yet.');
      return;
    }
    final moved = await showMoveFundsSheet(
      context,
      wallet: wallet,
      availableMinor: availableMinor,
    );
    if (moved && context.mounted) {
      showAppNotice(context, 'Money moved to your salary account.');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(destinationsControllerProvider);
    final wallet = beneficiary ? null : state.wallet(id);
    final recipient = beneficiary ? state.beneficiary(id) : null;
    // The list record names the page at once. Lifetime totals, and a
    // beneficiary's account number and narration, come from the detail call.
    final AsyncValue<Object> detail = beneficiary
        ? ref.watch(beneficiaryDetailProvider(id))
        : ref.watch(walletDetailProvider(id));
    final walletStats = switch (detail.value) {
      WalletDetail(:final stats) => stats,
      _ => null,
    };
    final recipientDetail = switch (detail.value) {
      final BeneficiaryDetail value => value,
      _ => null,
    };
    // A failed refresh keeps the figures already shown; only a detail that
    // never loaded is reported.
    final detailError = detail.hasValue || detail.isLoading
        ? null
        : detail.error;
    final title = wallet?.name ?? recipient?.name;
    final loading = title == null && state.phase.isBusy;

    Widget content(Widget overview) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        overview,
        if (detailError != null)
          _DetailError(
            message: describeError(
              detailError,
              fallback: 'These details couldn’t be loaded.',
            ),
            onRetry: () => beneficiary
                ? ref.invalidate(beneficiaryDetailProvider(id))
                : ref.invalidate(walletDetailProvider(id)),
          ),
        const SizedBox(height: 20),
        LinkedRuleCard(destinationId: id, beneficiary: beneficiary),
        const SizedBox(height: 24),
        DestinationActivity(destinationId: id, beneficiary: beneficiary),
      ],
    );

    final Widget? trailing;
    final Widget child;
    if (wallet != null) {
      final available = walletStats?.availableBalance ?? wallet.balanceMinor;
      trailing = _ActionsMenu([
        _MenuAction('Edit', () => showWalletEditor(context, initial: wallet)),
        _MenuAction('Move', () => _move(context, wallet, available)),
        _MenuAction(
          'Delete',
          () => _delete(context, ref, wallet.name),
          destructive: true,
        ),
      ]);
      child = content(
        _WalletOverview(
          wallet: wallet,
          available: available,
          stats: walletStats,
        ),
      );
    } else if (recipient != null) {
      trailing = _ActionsMenu([
        _MenuAction(
          'Edit',
          // The form edits the narration, which only the detail carries.
          recipientDetail == null
              ? null
              : () => showBeneficiaryEditor(context, initial: recipient),
        ),
        _MenuAction(
          recipient.paused ? 'Resume' : 'Pause',
          () => _setPaused(context, ref, !recipient.paused),
        ),
        _MenuAction(
          'Delete',
          () => _delete(context, ref, recipient.name),
          destructive: true,
        ),
      ]);
      child = content(
        _BeneficiaryOverview(beneficiary: recipient, detail: recipientDetail),
      );
    } else {
      trailing = null;
      child = loading
          ? const SkeletonLoader(
              label: 'Loading details',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox.card(height: 150),
                  SizedBox(height: 28),
                  SkeletonBox(width: 110),
                  SizedBox(height: 14),
                  SkeletonBox.card(height: 130),
                  SizedBox(height: 28),
                  SkeletonBox(width: 130),
                  SizedBox(height: 14),
                  SkeletonTiles(count: 2),
                ],
              ),
            )
          : state.phase.isFailure
          ? ContentStatusCard(
              phase: state.phase,
              hasContent: false,
              subject: beneficiary ? 'Beneficiary' : 'Wallet',
              items: 'details',
              message: state.message,
              onRetry: ref.read(destinationsControllerProvider.notifier).load,
            )
          : Text(
              'This ${beneficiary ? 'beneficiary' : 'wallet'} is no longer available.',
            );
    }
    return AppPageLayout(
      title: title ?? (loading ? '' : 'Not found'),
      headerTop: 31,
      bodyGap: beneficiary ? 27 : 38,
      onBack: () =>
          context.canPop() ? context.pop() : context.go('/destinations'),
      trailing: trailing,
      child: child,
    );
  }
}

class _MenuAction {
  const _MenuAction(this.label, this.onSelected, {this.destructive = false});
  final String label;
  final VoidCallback? onSelected;
  final bool destructive;
}

/// The "More actions" menu. An action without a callback is shown disabled.
class _ActionsMenu extends StatelessWidget {
  const _ActionsMenu(this.actions);
  final List<_MenuAction> actions;

  @override
  Widget build(BuildContext context) => PopupMenuButton<VoidCallback>(
    tooltip: 'More actions',
    icon: const AppSvgIcon('assets/icons/destinations/c3113.svg'),
    color: Colors.white,
    elevation: 3,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    onSelected: (action) => action(),
    itemBuilder: (_) => [
      for (final action in actions)
        PopupMenuItem(
          value: action.onSelected,
          enabled: action.onSelected != null,
          child: Text(
            action.label,
            style: action.destructive
                ? const TextStyle(color: Color(0xFFFF383C))
                : null,
          ),
        ),
    ],
  );
}

/// Says that the detail call failed, under the figures it would have filled.
class _DetailError extends StatelessWidget {
  const _DetailError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    liveRegion: true,
    child: Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        spacing: 8,
        children: [
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 12, color: Color(0xFF696969)),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    ),
  );
}

class _WalletOverview extends StatelessWidget {
  const _WalletOverview({
    required this.wallet,
    required this.available,
    required this.stats,
  });
  final Wallet wallet;
  final int available;

  /// Lifetime totals; null until the detail call answers.
  final WalletStats? stats;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(horizontal: 11),
    child: Row(
      spacing: 16,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AmountCard(
          label: 'Available Balance',
          amount: available,
          caption: 'Available in Wallet',
        ),
        _AmountCard(
          label: 'Total Allocated',
          amount: stats?.totalAllocated,
          caption: 'Cumulative Salary Split',
        ),
        _AmountCard(
          label: 'Total Moved Back',
          amount: stats?.totalMovedBack,
          caption: 'Transferred to Main Salary',
        ),
        Container(
          width: 297,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: _overviewDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Goal Progress Target',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 24),
              WalletTargetProgress(wallet: wallet),
            ],
          ),
        ),
      ],
    ),
  );
}

const _overviewDecoration = BoxDecoration(
  border: Border.fromBorderSide(BorderSide(color: Color(0xFFD6EDFD))),
  borderRadius: BorderRadius.all(Radius.circular(16)),
  gradient: LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFEAF6FF), Color(0xFFF8FCFF)],
  ),
);

class _AmountCard extends StatelessWidget {
  const _AmountCard({
    required this.label,
    required this.amount,
    required this.caption,
  });
  final String label;

  /// Kobo; null while the figure has not loaded.
  final int? amount;
  final String caption;
  @override
  Widget build(BuildContext context) => Container(
    width: (MediaQuery.sizeOf(context).width - 54).clamp(240, 336),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
    decoration: _overviewDecoration,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, height: 1.2)),
        const SizedBox(height: 20),
        Text(
          _amountOrDash(amount),
          style: const TextStyle(
            fontFamily: 'Arimo',
            color: Color(0xFF171918),
            fontSize: 36,
            fontWeight: FontWeight.w700,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          caption,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.2,
            color: Color(0xFF555653),
          ),
        ),
      ],
    ),
  );
}

/// A figure in naira, or a dash while it has not loaded.
String _amountOrDash(int? minor) => minor == null ? '—' : Money.format(minor);

class _BeneficiaryOverview extends StatefulWidget {
  const _BeneficiaryOverview({required this.beneficiary, required this.detail});
  final Beneficiary beneficiary;

  /// The lifetime total and the whole account number. Null until the detail
  /// call answers; until then the number cannot be revealed or copied.
  final BeneficiaryDetail? detail;
  @override
  State<_BeneficiaryOverview> createState() => _BeneficiaryOverviewState();
}

class _BeneficiaryOverviewState extends State<_BeneficiaryOverview> {
  bool _revealed = false;
  @override
  Widget build(BuildContext context) {
    final detail = widget.detail;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFEBF6FE)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFEAF6FF), Colors.white],
                stops: [.27517, .98923],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Total Allocated',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.2,
                    color: Color(0xFF171918),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _amountOrDash(detail?.totalAllocatedMinor),
                  style: const TextStyle(
                    fontFamily: 'Arimo',
                    fontSize: 36,
                    height: 1.15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF171918),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Cumulative Salary Split',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF555653),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Expanded(
                      child: Text(
                        'Account No',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF696969),
                        ),
                      ),
                    ),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9F9F9),
                          border: Border.all(color: const Color(0xFFE4E4E4)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.beneficiary.category,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Flexible(
                      child: Tooltip(
                        message: _revealed
                            ? 'Hide account number'
                            : 'Show account number',
                        child: InkWell(
                          onTap: detail == null
                              ? null
                              : () => setState(() => _revealed = !_revealed),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 48),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              widthFactor: 1,
                              child: Text(
                                _revealed && detail != null
                                    ? detail.accountNumber
                                    : widget.beneficiary.maskedAccountNumber,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF171918),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Copy account number',
                      icon: const AppSvgIcon(
                        'assets/icons/destinations/d637b.svg',
                        size: 16,
                      ),
                      onPressed: detail == null
                          ? null
                          : () async {
                              await Clipboard.setData(
                                ClipboardData(text: detail.accountNumber),
                              );
                              if (context.mounted) {
                                showAppNotice(
                                  context,
                                  'Account number copied.',
                                );
                              }
                            },
                    ),
                  ],
                ),
                const Text(
                  'Bank Name:',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 12,
                    height: 1.45,
                    color: Color(0xFF696969),
                  ),
                ),
                Text(
                  widget.beneficiary.bank,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
