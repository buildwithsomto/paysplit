import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paysplit/features/notifications/data/data_sources/notifications_data_source.dart';
import 'package:paysplit/features/notifications/data/models/app_notification.dart';

class NotificationsRepository {
  const NotificationsRepository(this._source);
  final NotificationsDataSource _source;

  static const pageSize = 20;

  Future<NotificationFeedPage> feed({
    int page = 1,
    bool unreadOnly = false,
  }) async => NotificationFeedPage.fromJson(
    await _source.list(page: page, limit: pageSize, unreadOnly: unreadOnly),
  );

  Future<void> markRead(String id) async {
    await _source.markRead(id);
  }

  Future<void> markAllRead() async {
    await _source.markAllRead();
  }
}

final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (ref) => NotificationsRepository(ref.watch(notificationsDataSourceProvider)),
);
