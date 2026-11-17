import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paysplit/core/network/api_exception.dart';
import 'package:paysplit/core/presentation/content_phase.dart';
import 'package:paysplit/core/session/ledger_version.dart';
import 'package:paysplit/core/session/session_providers.dart';
import 'package:paysplit/features/home/presentation/controllers/dashboard_controller.dart';
import 'package:paysplit/features/notifications/data/models/app_notification.dart';
import 'package:paysplit/features/notifications/data/repositories/notifications_repository.dart';

export 'package:paysplit/features/notifications/data/models/app_notification.dart'
    show AppNotification;

enum NotificationFilter { all, unread, read }

@immutable
class NotificationsState {
  const NotificationsState({
    this.items = const [],
    this.filter = NotificationFilter.all,
    this.phase = ContentPhase.loading,
    this.message,
    this.updatedAt,
    this.unreadCount = 0,
    this.page = 0,
    this.hasMore = false,
    this.loadingMore = false,
    this.loadMoreFailed = false,
    this.markingAll = false,
  });

  /// Loaded entries, newest first. With the Unread filter these are only the
  /// unread ones, because the server filters that list.
  final List<AppNotification> items;
  final NotificationFilter filter;
  final ContentPhase phase;

  /// The API's explanation of the last failed load.
  final String? message;

  /// Null until the feed has loaded once.
  final DateTime? updatedAt;

  /// Drives the bell badge and the "Mark all as read" action.
  final int unreadCount;

  /// The last page loaded; more are fetched as the list is scrolled.
  final int page;
  final bool hasMore, loadingMore, loadMoreFailed, markingAll;

  bool get hasData => updatedAt != null;

  /// What the selected filter shows. Read is filtered here: the API can only
  /// narrow the feed to unread entries.
  List<AppNotification> get visible => switch (filter) {
    NotificationFilter.all => items,
    NotificationFilter.unread =>
      items.where((item) => !item.isRead).toList(growable: false),
    NotificationFilter.read =>
      items.where((item) => item.isRead).toList(growable: false),
  };

  NotificationsState copyWith({
    List<AppNotification>? items,
    NotificationFilter? filter,
    ContentPhase? phase,
    String? message,
    bool clearMessage = false,
    DateTime? updatedAt,
    bool clearUpdatedAt = false,
    int? unreadCount,
    int? page,
    bool? hasMore,
    bool? loadingMore,
    bool? loadMoreFailed,
    bool? markingAll,
  }) => NotificationsState(
    items: items == null ? this.items : List.unmodifiable(items),
    filter: filter ?? this.filter,
    phase: phase ?? this.phase,
    message: clearMessage ? null : message ?? this.message,
    updatedAt: clearUpdatedAt ? null : updatedAt ?? this.updatedAt,
    unreadCount: unreadCount ?? this.unreadCount,
    page: page ?? this.page,
    hasMore: hasMore ?? this.hasMore,
    loadingMore: loadingMore ?? this.loadingMore,
    loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
    markingAll: markingAll ?? this.markingAll,
  );
}

/// The notification feed, backed by `/notifications`.
class NotificationsController extends Notifier<NotificationsState> {
  int _generation = 0;

  /// Bumped by every first-page load so an older page can never land on a
  /// newer list.
  int _feed = 0;

  NotificationsRepository get _repository =>
      ref.read(notificationsRepositoryProvider);

  @override
  NotificationsState build() {
    final userId = ref.watch(sessionUserIdProvider);
    final generation = ++_generation;
    ref.listen(ledgerVersionProvider, (_, _) => load());
    ref.onDispose(() => _generation++);
    if (userId == null) {
      return const NotificationsState(phase: ContentPhase.ready);
    }
    Future.microtask(() {
      if (ref.mounted && generation == _generation) load();
    });
    return const NotificationsState();
  }

  bool get _unreadOnly => state.filter == NotificationFilter.unread;

  /// First load, pull-to-refresh and Retry: the first page of the feed.
  Future<void> load() async {
    if (ref.read(sessionUserIdProvider) == null) return;
    final generation = _generation;
    final feed = ++_feed;
    state = state.copyWith(
      phase: state.hasData ? ContentPhase.refreshing : ContentPhase.loading,
      loadingMore: false,
      loadMoreFailed: false,
    );
    try {
      final result = await _repository.feed(unreadOnly: _unreadOnly);
      if (!ref.mounted || generation != _generation || feed != _feed) return;
      state = state.copyWith(
        items: result.page.items,
        phase: ContentPhase.ready,
        clearMessage: true,
        updatedAt: DateTime.now(),
        unreadCount: result.unreadCount,
        page: result.page.page,
        hasMore: result.page.hasNextPage,
      );
      _publishUnreadCount();
    } on Object catch (error) {
      if (!ref.mounted || generation != _generation || feed != _feed) return;
      // Keep the last loaded notifications on screen; only the phase changes.
      state = state.copyWith(
        phase: ContentPhase.failure(error),
        message: describeError(error),
      );
    }
  }

  /// Fetches the next page when the end of the list is reached.
  Future<void> loadMore() async {
    if (!state.hasMore || state.loadingMore || state.phase.isBusy) return;
    final generation = _generation;
    final feed = _feed;
    state = state.copyWith(loadingMore: true, loadMoreFailed: false);
    try {
      final result = await _repository.feed(
        page: state.page + 1,
        unreadOnly: _unreadOnly,
      );
      if (!ref.mounted || generation != _generation || feed != _feed) return;
      final known = {for (final item in state.items) item.id};
      state = state.copyWith(
        items: [
          ...state.items,
          ...result.page.items.where((item) => !known.contains(item.id)),
        ],
        unreadCount: result.unreadCount,
        page: result.page.page,
        hasMore: result.page.hasNextPage,
        loadingMore: false,
      );
      _publishUnreadCount();
    } on Object {
      if (!ref.mounted || generation != _generation || feed != _feed) return;
      state = state.copyWith(loadingMore: false, loadMoreFailed: true);
    }
  }

  Future<void> setFilter(NotificationFilter filter) async {
    if (filter == state.filter) return;
    final wasUnreadOnly = _unreadOnly;
    final unreadOnly = filter == NotificationFilter.unread;
    if (wasUnreadOnly == unreadOnly) {
      // All and Read share one server list.
      state = state.copyWith(filter: filter);
      return;
    }
    // Unread entries are a subset of the full feed, so they can stay on
    // screen while the server's list loads. The reverse is not true.
    state = unreadOnly
        ? state.copyWith(filter: filter)
        : state.copyWith(
            filter: filter,
            items: const [],
            clearUpdatedAt: true,
            page: 0,
            hasMore: false,
          );
    await load();
  }

  /// Marks one notification as read straight away and tells the server.
  /// Returns false, with the entry unread again, when the server refused.
  Future<bool> markRead(String id) async {
    final index = state.items.indexWhere((item) => item.id == id);
    if (index < 0 || state.items[index].isRead) return true;
    final generation = _generation;
    final original = state.items[index];
    _replace(id, original.asRead());
    state = state.copyWith(unreadCount: state.unreadCount - 1);
    _publishUnreadCount();
    try {
      await _repository.markRead(id);
      return true;
    } on Object {
      if (!ref.mounted || generation != _generation) return false;
      _replace(id, original);
      state = state.copyWith(unreadCount: state.unreadCount + 1);
      _publishUnreadCount();
      return false;
    }
  }

  /// Returns null on success, otherwise the message to show.
  Future<String?> markAllRead() async {
    if (state.markingAll || state.unreadCount == 0) return null;
    final generation = _generation;
    final feed = _feed;
    final items = state.items;
    final unreadCount = state.unreadCount;
    state = state.copyWith(
      items: [for (final item in items) item.asRead()],
      unreadCount: 0,
      markingAll: true,
    );
    _publishUnreadCount();
    try {
      await _repository.markAllRead();
      if (ref.mounted && generation == _generation) {
        state = state.copyWith(markingAll: false);
      }
      return null;
    } on Object catch (error) {
      if (!ref.mounted || generation != _generation) return null;
      state = feed == _feed
          ? state.copyWith(
              items: items,
              unreadCount: unreadCount,
              markingAll: false,
            )
          : state.copyWith(markingAll: false);
      _publishUnreadCount();
      return describeError(error);
    }
  }

  void _replace(String id, AppNotification replacement) {
    state = state.copyWith(
      items: [
        for (final item in state.items) item.id == id ? replacement : item,
      ],
    );
  }

  void _publishUnreadCount() {
    final count = state.unreadCount < 0 ? 0 : state.unreadCount;
    if (count != state.unreadCount) state = state.copyWith(unreadCount: count);
    ref
        .read(dashboardControllerProvider.notifier)
        .setUnreadNotifications(count);
  }
}

final notificationsControllerProvider =
    NotifierProvider<NotificationsController, NotificationsState>(
      NotificationsController.new,
    );
