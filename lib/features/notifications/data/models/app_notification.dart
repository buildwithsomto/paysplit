import 'package:paysplit/core/network/json.dart';

/// One entry of the notification feed.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.splitRunId,
    this.transactionId,
  });

  /// `{id, type, title, body, data, read, readAt, createdAt}`. `data` is null
  /// or names what the event is about, for example `{splitRunId}`.
  factory AppNotification.fromJson(Object? value) {
    final json = Json.from(value);
    final data = json.objectOrNull('data');
    return AppNotification(
      id: json.string('id'),
      type: json.string('type'),
      title: json.string('title'),
      message: json.string('body'),
      isRead: json.boolean('read'),
      createdAt: json.date('createdAt'),
      splitRunId: data?.stringOrNull('splitRunId'),
      transactionId: data?.stringOrNull('transactionId'),
    );
  }

  final String id;

  /// The server's event name, for example `split_completed`; picks the icon.
  final String type;
  final String title, message;
  final bool isRead;
  final DateTime createdAt;

  /// The split run or transaction the event is about, when it has one.
  final String? splitRunId, transactionId;

  AppNotification asRead() => isRead
      ? this
      : AppNotification(
          id: id,
          type: type,
          title: title,
          message: message,
          isRead: true,
          createdAt: createdAt,
          splitRunId: splitRunId,
          transactionId: transactionId,
        );
}

/// One page of the feed with the count behind the bell badge.
class NotificationFeedPage {
  const NotificationFeedPage({required this.page, required this.unreadCount});

  factory NotificationFeedPage.fromJson(Object? value) => NotificationFeedPage(
    page: ApiPage.fromJson(value, AppNotification.fromJson),
    unreadCount: Json.from(value).integer('unreadCount'),
  );

  final ApiPage<AppNotification> page;
  final int unreadCount;
}
