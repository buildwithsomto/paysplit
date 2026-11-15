import 'package:paysplit/app/navigation/app_navigation_insets.dart';
import 'package:paysplit/features/rules/presentation/controllers/rules_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paysplit/features/destinations/presentation/controllers/destinations_controller.dart';
import 'package:paysplit/features/destinations/presentation/screens/beneficiary_editor_screen.dart';
import 'package:paysplit/features/destinations/presentation/screens/wallet_editor_screen.dart';
import 'package:paysplit/features/destinations/presentation/widgets/destination_empty_state.dart';
import 'package:paysplit/features/destinations/presentation/widgets/wallet_summary_card.dart';
import 'package:paysplit/theme/app_colors.dart';
import 'package:paysplit/widgets/app_svg_icon.dart';
import 'package:paysplit/widgets/layout/tab_page_layout.dart';

class DestinationsScreen extends ConsumerStatefulWidget {
  const DestinationsScreen({super.key});
  @override
  ConsumerState<DestinationsScreen> createState() => _DestinationsScreenState();
}

class _DestinationsScreenState extends ConsumerState<DestinationsScreen>
    with RestorationMixin {
  final _tab = RestorableBool(false);
  bool get _beneficiaries => _tab.value;
  @override
  String get restorationId => 'destination_view';
  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_tab, 'beneficiaries');
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(destinationsControllerProvider);
    return TabPageLayout(
      title: 'Destination',
      child: SingleChildScrollView(
        restorationId: 'destination_scroll',
        padding: EdgeInsets.fromLTRB(
          16,
          19,
          16,
          AppNavigationInsets.bottomOf(context) + 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 251,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 10,
                  children: [
                    Expanded(
                      child: _DestinationTab(
                        label: 'Wallet',
                        selected: !_beneficiaries,
                        onPressed: () => setState(() => _tab.value = false),
                      ),
                    ),
                    Expanded(
                      child: _DestinationTab(
                        label: 'Beneficiary',
                        selected: _beneficiaries,
                        onPressed: () => setState(() => _tab.value = true),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_beneficiaries) ...[
              if (state.beneficiaries.isEmpty)
                const DestinationEmptyState(beneficiary: true),
              for (final beneficiary in state.beneficiaries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _BeneficiaryTile(beneficiary: beneficiary),
                ),
            ] else ...[
              if (state.wallets.isEmpty)
                const DestinationEmptyState(beneficiary: false)
              else
                _WalletCarousel(wallets: state.wallets),
            ],
            const SizedBox(height: 16),
            Center(
              child: FilledButton.icon(
                onPressed: () => _beneficiaries
                    ? showBeneficiaryEditor(context)
                    : showWalletEditor(context),
                icon: const AppSvgIcon('assets/icons/destinations/bab21.svg'),
                label: Text(
                  _beneficiaries ? 'Add Beneficiary' : 'Create Wallet',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.action,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(171, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF171918),
                  ),
                ),
              ),
            ),
            if (!_beneficiaries) ...[
              const SizedBox(height: 24),
              const Text(
                'Recent Activity',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              const _NoActivity(),
            ],
          ],
        ),
      ),
    );
  }
}

class _DestinationTab extends StatelessWidget {
  const _DestinationTab({
    required this.label,
    required this.selected,
    required this.onPressed,
  });
  final String label;
  final bool selected;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: Material(
      color: selected ? AppColors.action : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 15),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 1.2,
              color: selected ? Colors.white : const Color(0xFF333333),
            ),
          ),
        ),
      ),
    ),
  );
}

class _BeneficiaryTile extends ConsumerWidget {
  const _BeneficiaryTile({required this.beneficiary});
  final BeneficiaryViewData beneficiary;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rule = ref
        .watch(rulesControllerProvider)
        .where((r) => r.destinationId == beneficiary.id)
        .firstOrNull;
    return Semantics(
      button: true,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.push('/beneficiaries/${beneficiary.id}'),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
            child: Row(
              spacing: 12,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        beneficiary.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF171918),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        beneficiary.bank,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF696969),
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF5F0),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      rule == null ? 'No linked rule' : rule.status.name,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Color(0xFF387647)),
                    ),
                  ),
                ),
                const AppSvgIcon(
                  'assets/icons/destinations/c1ae0.svg',
                  width: 18,
                  height: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WalletCarousel extends StatefulWidget {
  const _WalletCarousel({required this.wallets});
  final List<WalletViewData> wallets;
  @override
  State<_WalletCarousel> createState() => _WalletCarouselState();
}

class _WalletCarouselState extends State<_WalletCarousel> {
  int _index = 0;
  @override
  Widget build(BuildContext context) {
    // Intrinsic card height avoids fixed-height overflow for names and text scaling.
    return Column(
      children: [
        NotificationListener<ScrollUpdateNotification>(
          onNotification: (notification) {
            if (notification.metrics.axis == Axis.horizontal) {
              final width =
                  (MediaQuery.sizeOf(context).width - 54).clamp(240, 336) + 16;
              final index = (notification.metrics.pixels / width).round().clamp(
                0,
                widget.wallets.length - 1,
              );
              if (index != _index) setState(() => _index = index);
            }
            return false;
          },
          child: SingleChildScrollView(
            restorationId: 'destination_scroll',
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 16,
              children: [
                for (var i = 0; i < widget.wallets.length; i++)
                  SizedBox(
                    width: (MediaQuery.sizeOf(context).width - 54).clamp(
                      240,
                      336,
                    ),
                    child: WalletSummaryCard(
                      wallet: widget.wallets[i],
                      onOpen: () {
                        context.push('/wallets/${widget.wallets[i].id}');
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (widget.wallets.length > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 4,
            children: [
              for (var i = 0; i < widget.wallets.length; i++)
                Container(
                  width: i == _index ? 12 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == _index
                        ? AppColors.primary
                        : const Color(0xFFE2E2E2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _NoActivity extends StatelessWidget {
  const _NoActivity();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: const Text(
      'No wallet activity yet. Salary allocations will appear here.',
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF696969)),
    ),
  );
}
