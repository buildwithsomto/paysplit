import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paysplit/core/network/api_client.dart';
import 'package:paysplit/core/network/network_providers.dart';

class NotificationsDataSource {
  const NotificationsDataSource(this._client);
  final ApiClient _client;

  /// Newest first.
  Future<Object?> list({
    required int page,
    required int limit,
    bool unreadOnly = false,
  }) => _client.get(
    '/notifications',
    query: {'page': page, 'limit': limit, if (unreadOnly) 'unreadOnly': true},
  );

  Future<Object?> markRead(String id) =>
      _client.post('/notifications/${pathSegment(id)}/read');

  Future<Object?> markAllRead() => _client.post('/notifications/read-all');
}

final notificationsDataSourceProvider = Provider<NotificationsDataSource>(
  (ref) => NotificationsDataSource(ref.watch(apiClientProvider)),
);
