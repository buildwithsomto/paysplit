import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paysplit/features/home/presentation/controllers/dashboard_controller.dart';

enum NotificationFilter { all, unread, read }

@immutable
class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.group,
    required this.asset,
    this.read = false,
  });
  final String id;
  final String title;
  final String message;
  final String group;
  final String asset;
  final bool read;
  NotificationItem markRead() => NotificationItem(
    id: id,
    title: title,
    message: message,
    group: group,
    asset: asset,
    read: true,
  );
}

class NotificationsController extends Notifier<List<NotificationItem>> {
  @override
  List<NotificationItem> build() {
    final populated = ref.watch(
      dashboardControllerProvider.select((s) => s.populated),
    );
    return populated
        ? const [
            NotificationItem(
              id: 'salary',
              title: 'Salary Received',
              message:
                  'Sample: Talent Nation credited your salary account with ₦850,000.',
              group: 'Today',
              asset: '11cb9.svg',
            ),
            NotificationItem(
              id: 'wallet',
              title: 'Wallet Created',
              message: 'Sample: You created an Emergency Wallet.',
              group: 'Today',
              asset: '5bad9.svg',
            ),
            NotificationItem(
              id: 'wallet-2',
              title: 'Wallet Created',
              message: 'Sample: You created a Travel Wallet.',
              group: 'Today',
              asset: 'e71e2.svg',
              read: true,
            ),
            NotificationItem(
              id: 'rule',
              title: 'Split Rule Created',
              message: 'Sample: You created a split rule for rent.',
              group: 'Yesterday',
              asset: '11cb9.svg',
              read: true,
            ),
          ]
        : const [];
  }

  void markRead(String id) => state = List.unmodifiable([
    for (final item in state) item.id == id ? item.markRead() : item,
  ]);
}

final notificationsControllerProvider =
    NotifierProvider<NotificationsController, List<NotificationItem>>(
      NotificationsController.new,
    );
