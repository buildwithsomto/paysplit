import 'package:paysplit/features/history/presentation/widgets/destination_activity.dart';
import 'package:paysplit/features/rules/presentation/widgets/linked_rule_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paysplit/core/formatting/money.dart';
import 'package:paysplit/features/destinations/presentation/controllers/destinations_controller.dart';
import 'package:paysplit/features/destinations/presentation/screens/beneficiary_editor_screen.dart';
import 'package:paysplit/features/destinations/presentation/screens/wallet_editor_screen.dart';
import 'package:paysplit/features/destinations/presentation/widgets/wallet_summary_card.dart';
import 'package:paysplit/theme/app_colors.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(destinationsControllerProvider);
    final wallet = state.wallets.where((item) => item.id == id).firstOrNull;
    final recipient = state.beneficiaries
        .where((item) => item.id == id)
        .firstOrNull;
    final exists = beneficiary ? recipient != null : wallet != null;
    final title = beneficiary ? recipient?.name : wallet?.name;
    return AppPageLayout(
      title: title ?? 'Destination unavailable',
      headerTop: 31,
      bodyGap: beneficiary ? 27 : 38,
      onBack: () =>
          context.canPop() ? context.pop() : context.go('/destinations'),
      trailing: !exists
          ? null
          : PopupMenuButton<String>(
              tooltip: 'Destination actions',
              icon: const AppSvgIcon('assets/icons/destinations/c3113.svg'),
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (value) async {
                switch (value) {
                  case 'edit':
                    if (beneficiary) {
                      await showBeneficiaryEditor(context, initial: recipient!);
                    } else {
                      await showWalletEditor(context, initial: wallet!);
                    }
                  case 'move':
                    await showDialog<void>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Move to salary account'),
                        content: const Text(
                          'Wallet transfers are unavailable.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  case 'delete':
                    if (wallet != null && wallet.balanceMinor != 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'A wallet must have a zero balance before it can be deleted.',
                          ),
                        ),
                      );
                      return;
                    }
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(
                          'Delete ${beneficiary ? 'beneficiary' : 'wallet'}?',
                        ),
                        content: Text(
                          'Remove $title and its linked split rule? Your transaction history stays available.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text(
                              'Delete',
                              style: TextStyle(color: AppColors.error),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (confirmed != true || !context.mounted) return;
                    final controller = ref.read(
                      destinationsControllerProvider.notifier,
                    );
                    if (beneficiary) {
                      controller.removeBeneficiary(id);
                    } else {
                      controller.removeWallet(id);
                    }
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/destinations');
                    }
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                if (!beneficiary)
                  const PopupMenuItem(value: 'move', child: Text('Move')),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    'Delete',
                    style: TextStyle(color: Color(0xFFFF383C)),
                  ),
                ),
              ],
            ),
      child: !exists
          ? const Text(
              'This destination is no longer available. Return to Destination to choose another.',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (beneficiary)
                  _BeneficiaryOverview(beneficiary: recipient!)
                else
                  _WalletOverview(wallet: wallet!),
                const SizedBox(height: 20),
                LinkedRuleCard(destinationId: id, beneficiary: beneficiary),
                const SizedBox(height: 24),
                DestinationActivity(
                  destinationId: id,
                  beneficiary: beneficiary,
                ),
              ],
            ),
    );
  }
}

class _WalletOverview extends StatelessWidget {
  const _WalletOverview({required this.wallet});
  final WalletViewData wallet;
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
          amount: wallet.balanceMinor,
          caption: 'Available in Wallet',
        ),
        _AmountCard(
          label: 'Total Allocated',
          amount: wallet.balanceMinor,
          caption: 'Cumulative Salary Split',
        ),
        const _AmountCard(
          label: 'Total Moved Back',
          amount: 0,
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
  final int amount;
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
          Money.format(amount),
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

class _BeneficiaryOverview extends StatefulWidget {
  const _BeneficiaryOverview({required this.beneficiary});
  final BeneficiaryViewData beneficiary;
  @override
  State<_BeneficiaryOverview> createState() => _BeneficiaryOverviewState();
}

class _BeneficiaryOverviewState extends State<_BeneficiaryOverview> {
  bool _revealed = false;
  @override
  Widget build(BuildContext context) => Container(
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
                Money.format(0),
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
                      style: TextStyle(fontSize: 12, color: Color(0xFF696969)),
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
                        onTap: () => setState(() => _revealed = !_revealed),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 48),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            widthFactor: 1,
                            child: Text(
                              _revealed
                                  ? widget.beneficiary.accountNumber
                                  : widget.beneficiary.maskedAccount,
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
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(text: widget.beneficiary.accountNumber),
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Account number copied.'),
                          ),
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
