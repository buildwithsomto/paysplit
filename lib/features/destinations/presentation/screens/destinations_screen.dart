import 'package:intl/intl.dart';
import 'package:paysplit/app/navigation/app_navigation_insets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paysplit/core/presentation/content_phase.dart';
import 'package:paysplit/core/session/session_providers.dart';
import 'package:paysplit/features/destinations/data/models/destination_transaction.dart';
import 'package:paysplit/features/destinations/data/repositories/destinations_repository.dart';
import 'package:paysplit/features/history/data/models/transaction.dart';
import 'package:paysplit/features/history/presentation/controllers/history_filter_controller.dart';
import 'package:paysplit/features/history/presentation/widgets/destination_activity.dart';
import 'package:paysplit/features/history/presentation/widgets/transaction_tile.dart';
import 'package:paysplit/widgets/feedback/content_status_card.dart';
import 'package:paysplit/features/destinations/presentation/controllers/destinations_controller.dart';
import 'package:paysplit/features/destinations/presentation/screens/beneficiary_editor_screen.dart';
import 'package:paysplit/features/destinations/presentation/screens/wallet_editor_screen.dart';
import 'package:paysplit/features/destinations/presentation/widgets/destination_empty_state.dart';
import 'package:paysplit/features/destinations/presentation/widgets/wallet_summary_card.dart';
import 'package:paysplit/theme/app_colors.dart';
import 'package:paysplit/widgets/app_svg_icon.dart';
import 'package:paysplit/widgets/feedback/skeleton.dart';
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
    final controller = ref.read(destinationsControllerProvider.notifier);
    final firstLoad = !state.hasData && state.phase.isBusy;
    // The first load failed: only the reason and a retry are shown.
    final unknown = !state.hasData && state.phase.isFailure;
    final showStatus =
        state.phase != ContentPhase.ready &&
        !(state.phase == ContentPhase.refreshing && state.hasData);
    return TabPageLayout(
      title: 'Destination',
      child: RefreshIndicator(
        onRefresh: controller.load,
        child: SingleChildScrollView(
          restorationId: 'destination_scroll',
          physics: const AlwaysScrollableScrollPhysics(),
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
              if (showStatus) ...[
                ContentStatusCard(
                  phase: state.phase,
                  hasContent: state.hasData,
                  subject: _beneficiaries ? 'Beneficiaries' : 'Wallets',
                  items: _beneficiaries ? 'beneficiaries' : 'wallets',
                  message: state.message,
                  updatedAt: state.updatedAt,
                  onRetry: controller.load,
                  skeleton: _beneficiaries
                      ? const SkeletonTiles()
                      : const SkeletonSurface(
                          radius: 20,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                spacing: 10,
                                children: [
                                  SkeletonBox(width: 32, height: 32),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      spacing: 8,
                                      children: [
                                        SkeletonBox(width: 90),
                                        SkeletonBox(width: 120, height: 10),
                                      ],
                                    ),
                                  ),
                                  SkeletonBox(width: 90, height: 18),
                                ],
                              ),
                              SizedBox(height: 28),
                              SkeletonBox(width: 150, height: 10),
                              SizedBox(height: 28),
                              SkeletonBox(width: 130, height: 10),
                            ],
                          ),
                        ),
                ),
                const SizedBox(height: 16),
              ],
              if (firstLoad || unknown)
                const SizedBox.shrink()
              else if (_beneficiaries) ...[
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
              if (!unknown) ...[
                const SizedBox(height: 16),
                Center(
                  child: FilledButton.icon(
                    onPressed: () => _beneficiaries
                        ? showBeneficiaryEditor(context)
                        : showWalletEditor(context),
                    icon: const AppSvgIcon(
                      'assets/icons/destinations/bab21.svg',
                    ),
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
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Recent Activity',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      // Every wallet movement is the History tab's Wallets view.
                      SeeAllLink(
                        onPressed: () {
                          ref
                              .read(historyFilterProvider.notifier)
                              .selectTab(HistoryTab.wallets);
                          context.go('/history');
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const _WalletActivity(),
                ],
              ],
            ],
          ),
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

class _BeneficiaryTile extends StatelessWidget {
  const _BeneficiaryTile({required this.beneficiary});
  final Beneficiary beneficiary;
  @override
  Widget build(BuildContext context) {
    final nextSplit = beneficiary.nextSplitDate;
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF171918),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        beneficiary.bank,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF696969),
                        ),
                      ),
                    ],
                  ),
                ),
                // "Next Split" over its date, as designed. Without a
                // date the chip says why there is none.
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  spacing: 6,
                  children: [
                    if (nextSplit != null && !beneficiary.paused)
                      const Text(
                        'Next Split',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFC8553D),
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: beneficiary.paused
                            ? const Color(0xFFF2F4F7)
                            : const Color(0xFFEEF5F0),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        beneficiary.paused
                            ? 'Paused'
                            : nextSplit != null
                            ? DateFormat('MMM d').format(nextSplit)
                            : 'No linked rule',
                        style: TextStyle(
                          fontSize: 12,
                          color: beneficiary.paused
                              ? AppColors.body
                              : const Color(0xFF387647),
                        ),
                      ),
                    ),
                  ],
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
  final List<Wallet> wallets;
  @override
  State<_WalletCarousel> createState() => _WalletCarouselState();
}

class _WalletCarouselState extends State<_WalletCarousel> {
  int _index = 0;
  @override
  Widget build(BuildContext context) {
    // A wallet may have been deleted since the last scroll position.
    final active = _index.clamp(0, widget.wallets.length - 1);
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
                  width: i == active ? 12 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == active
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

/// The latest movements across every wallet (`GET /wallets/activity`).
///
/// Kept for the session, one per signed-in user, so a refresh that fails
/// offline leaves the last loaded activity on screen.
final _walletActivityProvider =
    FutureProvider.family<List<DestinationTransaction>, String?>((
      ref,
      userId,
    ) async {
      ref.watch(destinationsControllerProvider.select((s) => s.updatedAt));
      final page = await ref
          .watch(destinationsRepositoryProvider)
          .walletActivity(page: 1, limit: 5);
      return page.items;
    });

class _WalletActivity extends ConsumerWidget {
  const _WalletActivity();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activity = ref.watch(
      _walletActivityProvider(ref.watch(sessionUserIdProvider)),
    );
    final items = activity.value ?? const <DestinationTransaction>[];
    return Container(
      padding: EdgeInsets.all(items.isEmpty ? 24 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: items.isNotEmpty
          ? TransactionMonthList(
              walletActivity: true,
              records: [
                // Across every wallet, each row names the wallet it is
                // about; a move back says so in its narration.
                for (final item in items)
                  destinationRecord(
                    item,
                    beneficiary: false,
                    destinationName: item.walletName ?? '',
                    title: item.walletName == null
                        ? item.narration
                        : '${item.label} · ${item.walletName}',
                  ),
              ],
            )
          : activity.isLoading
          ? const SkeletonLoader(
              label: 'Loading wallet activity',
              child: SkeletonRows(count: 4),
            )
          : Text(
              activity.hasError
                  ? 'Wallet activity couldn’t be loaded. Pull down to refresh.'
                  : 'No wallet activity yet. Salary allocations will appear here.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Color(0xFF696969),
              ),
            ),
    );
  }
}
