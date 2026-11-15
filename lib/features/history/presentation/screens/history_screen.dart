import 'package:paysplit/app/navigation/app_navigation_insets.dart';
import 'package:paysplit/theme/app_colors.dart';
import 'package:paysplit/core/presentation/content_phase.dart';
import 'package:paysplit/widgets/feedback/content_status_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:paysplit/features/history/presentation/controllers/history_controller.dart';
import 'package:paysplit/features/history/presentation/controllers/history_filter_controller.dart';
import 'package:paysplit/features/history/presentation/widgets/history_filter_sheet.dart';
import 'package:paysplit/features/history/presentation/widgets/history_segments.dart';
import 'package:paysplit/features/history/presentation/widgets/restorable_history_view.dart';
import 'package:paysplit/features/history/presentation/widgets/statement_sheet.dart';
import 'package:paysplit/features/history/presentation/widgets/transaction_tile.dart';
import 'package:paysplit/widgets/app_svg_icon.dart';
import 'package:paysplit/widgets/buttons/app_back_button.dart';

class ActivityHistoryRoute extends StatelessWidget {
  const ActivityHistoryRoute({
    required this.destinationId,
    this.walletActivity = false,
    super.key,
  });
  final String destinationId;
  final bool walletActivity;
  @override
  Widget build(BuildContext context) => ProviderScope(
    overrides: [
      historyFilterProvider.overrideWith(HistoryFilterController.new),
    ],
    child: Scaffold(
      body: HistoryScreen(
        destinationId: destinationId,
        walletActivity: walletActivity,
      ),
    ),
  );
}

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({
    this.destinationId,
    this.walletActivity = false,
    super.key,
  });
  final String? destinationId;
  final bool walletActivity;
  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen>
    with RestorationMixin {
  late final _view = RestorableHistoryView(ref.read(historyFilterProvider));
  bool _registered = false;
  @override
  String get restorationId => 'history_view';
  @override
  void initState() {
    super.initState();
    ref.listenManual(historyFilterProvider, (_, next) {
      if (_registered) _view.value = next;
    });
  }

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_view, 'filters');
    _registered = true;
    final restored = _view.value;
    // Provider notifications must occur outside the widget build phase.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(historyFilterProvider.notifier).restoreView(restored);
      _search.text = restored.query;
    });
  }

  late final _search = TextEditingController(
    text: ref.read(historyFilterProvider).query,
  );
  @override
  void dispose() {
    _view.dispose();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(historyControllerProvider);
    final filter = ref.watch(historyFilterProvider);
    final controller = ref.read(historyFilterProvider.notifier);
    final scoped = widget.destinationId != null;
    final records = filterHistory(
      history.records,
      filter,
      destinationId: widget.destinationId,
      walletActivity: widget.walletActivity,
    );
    final visible = records.take(filter.visibleCount).toList();
    final loadingWithoutRecords =
        history.phase != ContentPhase.ready && history.records.isEmpty;
    final historyActions = ref.read(historyControllerProvider.notifier);
    return CustomScrollView(
      restorationId: 'history_scroll',
      key: PageStorageKey('history-${widget.destinationId ?? 'all'}'),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverToBoxAdapter(
          child: ColoredBox(
            color: Colors.white,
            child: SafeArea(
              bottom: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(18, scoped ? 31 : 20, 18, 21),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (scoped) ...[
                          Row(
                            spacing: 16,
                            children: [
                              AppBackButton(
                                onPressed: () => context.canPop()
                                    ? context.pop()
                                    : context.go('/history'),
                              ),
                              Expanded(
                                child: Text(
                                  widget.walletActivity
                                      ? 'Wallet Activity'
                                      : 'Transfer History',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                        SizedBox(
                          height: 48,
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _search,
                                  onChanged: controller.search,
                                  style: const TextStyle(fontSize: 14),
                                  decoration: InputDecoration(
                                    hintText: 'Search',
                                    hintStyle: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF60635F),
                                    ),
                                    prefixIcon: const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: AppSvgIcon(
                                        'assets/icons/history/ecde4.svg',
                                        size: 20,
                                      ),
                                    ),
                                    suffixIcon: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (filter.query.isNotEmpty)
                                          IconButton(
                                            tooltip: 'Clear search',
                                            onPressed: () {
                                              _search.clear();
                                              controller.search('');
                                            },
                                            icon: const Icon(
                                              Icons.close,
                                              size: 18,
                                            ),
                                          ),
                                        IconButton(
                                          tooltip: filter.hasAdvanced
                                              ? 'Edit transaction filters'
                                              : 'Filter transactions',
                                          icon: Icon(
                                            Icons.tune,
                                            size: 18,
                                            color: filter.hasAdvanced
                                                ? const Color(0xFF006BAA)
                                                : null,
                                          ),
                                          onPressed: () async {
                                            FocusManager.instance.primaryFocus
                                                ?.unfocus();
                                            final result =
                                                await showHistoryFilters(
                                                  context,
                                                  filter,
                                                  history.records,
                                                  destinationScoped: scoped,
                                                );
                                            if (result != null) {
                                              controller.apply(result);
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: AppColors.border,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: AppColors.border,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: scoped
                                  ? HistorySegments(
                                      options: const {
                                        MoneyDirection.all: 'All',
                                        MoneyDirection.incoming: 'Money In',
                                        MoneyDirection.outgoing: 'Money Out',
                                      },
                                      selected: filter.direction,
                                      onSelected: controller.selectDirection,
                                    )
                                  : HistorySegments(
                                      options: const {
                                        HistoryTab.all: 'All',
                                        HistoryTab.wallets: 'Wallets',
                                        HistoryTab.transfers: 'Transfer',
                                      },
                                      selected: filter.tab,
                                      onSelected: controller.selectTab,
                                    ),
                            ),
                            if (!scoped)
                              FilledButton(
                                onPressed: history.phase != ContentPhase.ready
                                    ? null
                                    : () => showStatementSheet(
                                        context,
                                        records,
                                        sample: history.sample,
                                      ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.action,
                                  minimumSize: const Size(0, 48),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  spacing: 8,
                                  children: [
                                    AppSvgIcon(
                                      'assets/icons/history/4a6a7.svg',
                                      size: 16,
                                    ),
                                    Text(
                                      'Export',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (history.phase != ContentPhase.ready)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ContentStatusCard(
                phase: history.phase,
                hasContent: history.records.isNotEmpty,
                sample: history.sample,
                updatedAt: history.updatedAt,
                retryFailed: history.retryFailed,
                onRetry: history.sample ? historyActions.retryPreview : null,
                onRestorePreview: history.sample
                    ? historyActions.restorePreview
                    : null,
              ),
            ),
          ),
        if (loadingWithoutRecords)
          const SliverToBoxAdapter(child: SizedBox(height: 48))
        else if (visible.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                scoped ? 32 : AppNavigationInsets.bottomOf(context) + 24,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      'assets/icons/history/b98c5.svg',
                      width: 102.72,
                      height: 66,
                      excludeFromSemantics: true,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      history.records.isEmpty
                          ? 'No Transactions Yet'
                          : 'No matching transactions',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Arimo',
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                        height: 1.2,
                        color: Color(0xFF777777),
                      ),
                    ),
                    if (history.records.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () {
                          _search.clear();
                          controller.clear();
                        },
                        child: const Text('Clear filters'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.only(top: 21),
            sliver: SliverList.builder(
              itemCount: visible.length,
              itemBuilder: (context, index) {
                final record = visible[index];
                final first =
                    index == 0 ||
                    visible[index - 1].time.month != record.time.month ||
                    visible[index - 1].time.year != record.time.year;
                return Column(
                  children: [
                    if (first && index > 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: SizedBox(
                          height: 4,
                          width: double.infinity,
                          child: SvgPicture.asset(
                            'assets/icons/history/40fd4.svg',
                            fit: BoxFit.fill,
                            excludeFromSemantics: true,
                          ),
                        ),
                      ),
                    if (first)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: Row(
                          spacing: 10,
                          children: [
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.sizeOf(context).width - 52,
                              ),
                              child: Text(
                                '${DateFormat('MMMM y').format(record.time)}${history.sample ? ' · Sample' : ''}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF171918),
                                ),
                              ),
                            ),
                            Expanded(
                              child: SizedBox(
                                height: 1,
                                child: SvgPicture.asset(
                                  'assets/icons/history/6e8f7.svg',
                                  fit: BoxFit.fill,
                                  excludeFromSemantics: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        0,
                        16,
                        index == visible.length - 1 ? 0 : 8,
                      ),
                      child: TransactionTile(
                        record: record,
                        walletActivity: widget.walletActivity,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        if (visible.length < records.length)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton(
                onPressed: controller.loadMore,
                child: Text(
                  'Load more (${records.length - visible.length} remaining)',
                ),
              ),
            ),
          ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: scoped ? 32 : AppNavigationInsets.bottomOf(context) + 16,
          ),
        ),
      ],
    );
  }
}
