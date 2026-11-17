import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:paysplit/widgets/layout/header_overscroll_fill.dart';
import 'package:paysplit/core/presentation/content_phase.dart';
import 'package:paysplit/features/notifications/presentation/controllers/notifications_controller.dart';
import 'package:paysplit/theme/app_colors.dart';
import 'package:paysplit/theme/app_typography.dart';
import 'package:paysplit/theme/app_theme.dart';
import 'package:paysplit/widgets/app_svg_icon.dart';
import 'package:paysplit/widgets/buttons/app_back_button.dart';
import 'package:paysplit/widgets/buttons/app_button.dart';
import 'package:paysplit/widgets/buttons/app_text_link.dart';
import 'package:paysplit/widgets/feedback/app_notice.dart';
import 'package:paysplit/widgets/feedback/content_status_card.dart';
import 'package:paysplit/widgets/feedback/empty_state.dart';
import 'package:paysplit/widgets/feedback/skeleton.dart';
import 'package:paysplit/widgets/inputs/app_filter_tabs.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});
  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen>
    with RestorationMixin {
  final _selection = RestorableEnum(
    NotificationFilter.all,
    values: NotificationFilter.values,
  );
  final _scroll = ScrollController();

  NotificationsController get _controller =>
      ref.read(notificationsControllerProvider.notifier);

  @override
  String get restorationId => 'notifications_view';
  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_selection, 'filter');
    if (_selection.value != NotificationFilter.all) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _controller.setFilter(_selection.value);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      // Fetch the next page shortly before the end is reached.
      if (_scroll.position.extentAfter < 320) _controller.loadMore();
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _selection.dispose();
    super.dispose();
  }

  static String _group(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(time.year, time.month, time.day);
    return switch (today.difference(day).inDays) {
      0 => 'Today',
      1 => 'Yesterday',
      _ => DateFormat(
        day.year == now.year ? 'EEE, MMM d' : 'MMM d, y',
      ).format(day),
    };
  }

  Future<void> _markAllRead() async {
    final failure = await _controller.markAllRead();
    if (mounted && failure != null) showAppNotice(context, failure);
  }

  /// Where a notification leads: the split run or transaction it is about.
  static (String, String)? _destination(AppNotification item) {
    if (item.splitRunId case final id?) {
      return ('View Split', '/split-history/$id');
    }
    if (item.transactionId case final id?) {
      return ('View Transaction', '/transactions/$id');
    }
    return null;
  }

  void _open(AppNotification item) {
    final destination = _destination(item);
    if (!item.isRead) {
      _controller.markRead(item.id).then((saved) {
        if (!saved && mounted) {
          showAppNotice(context, 'Couldn’t mark this as read. Try again.');
        }
      });
    }
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (context) => SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 24, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 12,
              children: [
                AppSvgIcon('assets/icons/dashboard/11cb9.svg', size: 30),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 4,
                    children: [
                      Text(item.title, style: AppTypography.heading),
                      Text(
                        DateFormat('MMM d, y · h:mm a').format(item.createdAt),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(item.message),
            const SizedBox(height: 24),
            if (destination case (final label, final route)) ...[
              AppButton(
                label: label,
                onPressed: () {
                  Navigator.pop(context);
                  this.context.push(route);
                },
              ),
              const SizedBox(height: 12),
            ],
            AppButton(
              label: 'Close',
              outlined: true,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationsControllerProvider);
    final items = state.visible;
    final showStatus =
        state.phase != ContentPhase.ready &&
        !(state.phase == ContentPhase.refreshing && state.hasData);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.systemOverlay,
      child: Scaffold(
        body: RefreshIndicator(
          onRefresh: _controller.load,
          child: CustomScrollView(
            controller: _scroll,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: HeaderOverscrollFill(
                  color: Colors.white,
                  child: ColoredBox(
                    color: Colors.white,
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 24, 18, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 10,
                          children: [
                            Row(
                              spacing: 12,
                              children: [
                                AppBackButton(
                                  onPressed: () => context.canPop()
                                      ? context.pop()
                                      : context.go('/home'),
                                ),
                                const Expanded(
                                  child: Text(
                                    'Notifications',
                                    style: AppTypography.heading,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                AppFilterTabs(
                                  values: NotificationFilter.values,
                                  selected: state.filter,
                                  label: (v) => switch (v) {
                                    NotificationFilter.all => 'All',
                                    NotificationFilter.unread => 'Unread',
                                    NotificationFilter.read => 'Read',
                                  },
                                  onChanged: (value) {
                                    _selection.value = value;
                                    _controller.setFilter(value);
                                  },
                                ),
                                const Spacer(),
                                if (state.unreadCount > 0)
                                  AppTextLink(
                                    label: 'Mark all as read',
                                    onPressed: state.markingAll
                                        ? null
                                        : _markAllRead,
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
              if (showStatus)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: ContentStatusCard(
                      phase: state.phase,
                      hasContent: state.items.isNotEmpty,
                      subject: 'Notifications',
                      items: 'notifications',
                      message: state.message,
                      updatedAt: state.updatedAt,
                      onRetry: _controller.load,
                      skeleton: const SkeletonTiles(count: 5),
                    ),
                  ),
                ),
              if (items.isEmpty && !showStatus)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: EmptyState(
                      title: switch (state.filter) {
                        NotificationFilter.unread => 'You’re All Caught Up',
                        NotificationFilter.read => 'Nothing Read Yet',
                        NotificationFilter.all => 'No Notifications Yet',
                      },
                      message: switch (state.filter) {
                        NotificationFilter.unread =>
                          'New salary, split and account updates will appear here.',
                        NotificationFilter.read =>
                          'Notifications you’ve read will appear here.',
                        NotificationFilter.all =>
                          'Salary, split and account updates will appear here.',
                      },
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 32),
                  sliver: SliverList.builder(
                    itemCount: items.length + (state.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == items.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: state.loadMoreFailed
                                ? TextButton(
                                    onPressed: _controller.loadMore,
                                    child: const Text('Load more'),
                                  )
                                : const SkeletonLoader(
                                    label: 'Loading more notifications',
                                    child: SkeletonTiles(count: 1),
                                  ),
                          ),
                        );
                      }
                      final item = items[index];
                      final group = _group(item.createdAt);
                      final showGroup =
                          index == 0 ||
                          _group(items[index - 1].createdAt) != group;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (showGroup)
                            Padding(
                              padding: EdgeInsets.only(
                                top: index == 0 ? 0 : 4,
                                bottom: 10,
                              ),
                              child: Text(
                                group,
                                style: const TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 16,
                                  height: 1.6,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Semantics(
                              button: true,
                              label: item.isRead
                                  ? 'Read notification'
                                  : 'Unread notification',
                              child: Material(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () => _open(item),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      spacing: 12,
                                      children: [
                                        AppSvgIcon(
                                          'assets/icons/dashboard/11cb9.svg',
                                          size: 30,
                                        ),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            spacing: 4,
                                            children: [
                                              Text(
                                                item.title,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  height: 1.2,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF323232),
                                                ),
                                              ),
                                              Text(
                                                item.message,
                                                maxLines: 3,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  height: 1.6,
                                                  fontWeight: FontWeight.w500,
                                                  color: Color(0xFF7C7C7C),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (!item.isRead)
                                          Container(
                                            width: 8,
                                            height: 8,
                                            margin: const EdgeInsets.only(
                                              top: 6,
                                            ),
                                            decoration: const BoxDecoration(
                                              color: AppColors.primary,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
