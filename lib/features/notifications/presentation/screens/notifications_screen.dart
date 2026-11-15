import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paysplit/features/notifications/presentation/controllers/notifications_controller.dart';
import 'package:paysplit/theme/app_typography.dart';
import 'package:paysplit/theme/app_theme.dart';
import 'package:paysplit/widgets/app_svg_icon.dart';
import 'package:paysplit/widgets/buttons/app_back_button.dart';
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
  NotificationFilter get _filter => _selection.value;
  @override
  String get restorationId => 'notifications_view';
  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_selection, 'filter');
  }

  @override
  void dispose() {
    _selection.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = ref
        .watch(notificationsControllerProvider)
        .where(
          (item) => switch (_filter) {
            NotificationFilter.all => true,
            NotificationFilter.unread => !item.read,
            NotificationFilter.read => item.read,
          },
        )
        .toList();
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.systemOverlay,
      child: Scaffold(
        body: CustomScrollView(
          restorationId: 'notifications_scroll',
          slivers: [
            SliverToBoxAdapter(
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
                        AppFilterTabs(
                          values: NotificationFilter.values,
                          selected: _filter,
                          label: (v) => switch (v) {
                            NotificationFilter.all => 'All',
                            NotificationFilter.unread => 'Unread',
                            NotificationFilter.read => 'Read',
                          },
                          onChanged: (value) =>
                              setState(() => _selection.value = value),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (items.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No notifications here yet.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 32),
                sliver: SliverList.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final showGroup =
                        index == 0 || items[index - 1].group != item.group;
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
                              item.group,
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
                            label: item.read
                                ? 'Read notification'
                                : 'Unread notification',
                            child: Material(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  ref
                                      .read(
                                        notificationsControllerProvider
                                            .notifier,
                                      )
                                      .markRead(item.id);
                                  showModalBottomSheet<void>(
                                    context: context,
                                    showDragHandle: true,
                                    useSafeArea: true,
                                    builder: (context) => SizedBox(
                                      width: double.infinity,
                                      child: SafeArea(
                                        child: Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                            24,
                                            0,
                                            24,
                                            32,
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            spacing: 16,
                                            children: [
                                              Text(
                                                item.title,
                                                style: AppTypography.heading,
                                              ),
                                              Text(item.message),
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                child: const Text('Close'),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    spacing: 12,
                                    children: [
                                      AppSvgIcon(
                                        'assets/icons/dashboard/${item.asset}',
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
                                              style: const TextStyle(
                                                fontSize: 16,
                                                height: 1.2,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF323232),
                                              ),
                                            ),
                                            Text(
                                              item.message,
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
    );
  }
}
