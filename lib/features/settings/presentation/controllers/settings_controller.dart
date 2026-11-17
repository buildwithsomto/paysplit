import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paysplit/core/network/api_exception.dart';
import 'package:paysplit/core/presentation/content_phase.dart';
import 'package:paysplit/core/session/session_providers.dart';
import 'package:paysplit/features/auth/data/models/auth_models.dart';
import 'package:paysplit/features/auth/presentation/controllers/account_controller.dart';
import 'package:paysplit/features/settings/data/models/notification_preferences.dart';
import 'package:paysplit/features/settings/data/models/user_profile.dart';
import 'package:paysplit/features/settings/data/repositories/profile_repository.dart';
import 'package:paysplit/features/setup/data/models/income.dart';

export 'package:paysplit/features/settings/data/models/notification_preferences.dart'
    show NotificationChannel, NotificationPreferences;
export 'package:paysplit/features/settings/data/models/user_profile.dart'
    show UserProfile;

@immutable
class SettingsState {
  const SettingsState({
    this.profile,
    this.preferences,
    this.phase = ContentPhase.loading,
    this.preferencesPhase = ContentPhase.ready,
    this.message,
    this.error,
    this.updatedAt,
    this.avatarBusy = false,
  });

  /// Null until `GET /users/me/profile` has answered once.
  final UserProfile? profile;

  /// Kept apart from [profile] so a toggle can show before it is saved.
  final NotificationPreferences? preferences;
  final ContentPhase phase;

  /// The notification screen's own refresh of [preferences].
  final ContentPhase preferencesPhase;

  /// Why the last load failed.
  final String? message;

  /// Why the last change (photo or notification toggle) failed.
  final String? error;
  final DateTime? updatedAt;

  /// A profile photo is being uploaded or removed.
  final bool avatarBusy;

  bool get hasData => profile != null;
  String? get profileImageUrl => profile?.user.profileImageUrl;

  /// Channels that currently carry at least one kind of update.
  Set<NotificationChannel> get channels => {
    for (final channel in NotificationChannel.values)
      if (preferences?.channelOn(channel) ?? false) channel,
  };

  SettingsState copyWith({
    UserProfile? profile,
    NotificationPreferences? preferences,
    ContentPhase? phase,
    ContentPhase? preferencesPhase,
    String? message,
    String? error,
    bool clearError = false,
    DateTime? updatedAt,
    bool? avatarBusy,
  }) => SettingsState(
    profile: profile ?? this.profile,
    preferences: preferences ?? this.preferences,
    phase: phase ?? this.phase,
    preferencesPhase: preferencesPhase ?? this.preferencesPhase,
    message: message ?? this.message,
    error: clearError ? null : error ?? this.error,
    updatedAt: updatedAt ?? this.updatedAt,
    avatarBusy: avatarBusy ?? this.avatarBusy,
  );
}

/// Profile & Settings, backed by `/users/me`.
///
/// The profile's `user` and `onboarding` are shared with
/// [accountControllerProvider] after every answer, so the dashboard greeting
/// and avatar follow edits made here.
class SettingsController extends Notifier<SettingsState> {
  static const maxImageBytes = 5 * 1024 * 1024;

  int _generation = 0;
  int _preferenceWrites = 0;
  Future<void>? _loading;

  ProfileRepository get _repository => ref.read(profileRepositoryProvider);

  @override
  SettingsState build() {
    final userId = ref.watch(sessionUserIdProvider);
    final generation = ++_generation;
    _preferenceWrites = 0;
    _loading = null;
    ref.onDispose(() => _generation++);
    if (userId == null) return const SettingsState(phase: ContentPhase.ready);
    Future.microtask(() {
      if (ref.mounted && generation == _generation) load();
    });
    return const SettingsState();
  }

  /// Loads the profile. Also the Retry and pull-to-refresh action; calls made
  /// while one is running share its result.
  Future<void> load() {
    if (ref.read(sessionUserIdProvider) == null) return Future.value();
    final generation = _generation;
    return _loading ??= _load().whenComplete(() {
      if (generation == _generation) _loading = null;
    });
  }

  Future<void> _load() async {
    final generation = _generation;
    state = state.copyWith(
      phase: state.hasData ? ContentPhase.refreshing : ContentPhase.loading,
    );
    try {
      final profile = await _repository.profile();
      if (!ref.mounted || generation != _generation) return;
      _share(profile);
      state = state.copyWith(
        profile: profile,
        // A toggle still being saved is newer than this answer.
        preferences: _preferenceWrites > 0 ? null : profile.notifications,
        phase: ContentPhase.ready,
        preferencesPhase: profile.notifications == null
            ? null
            : ContentPhase.ready,
        updatedAt: DateTime.now(),
      );
    } on Object catch (error) {
      if (!ref.mounted || generation != _generation) return;
      // Keep the last loaded profile on screen; only the phase changes.
      state = state.copyWith(
        phase: ContentPhase.failure(error),
        message: describeError(error),
      );
    }
  }

  /// Takes the profile returned by `PATCH /users/me`.
  void adopt(UserProfile profile) {
    _share(profile);
    state = state.copyWith(
      profile: profile,
      preferences: _preferenceWrites > 0 ? null : profile.notifications,
      phase: ContentPhase.ready,
      updatedAt: DateTime.now(),
    );
  }

  /// Takes the income source saved through `PUT /setup/income`.
  void adoptIncome(Income income, {required Onboarding onboarding}) {
    final profile = state.profile;
    if (profile == null) return;
    state = state.copyWith(
      profile: profile.copyWith(income: income, onboarding: onboarding),
    );
  }

  void _share(UserProfile profile) => ref
      .read(accountControllerProvider.notifier)
      .apply(user: profile.user, onboarding: profile.onboarding);

  // Notification preferences ------------------------------------------------

  /// Refreshes the toggles from `GET /users/me/notification-preferences`.
  Future<void> loadPreferences() async {
    if (ref.read(sessionUserIdProvider) == null) return;
    if (state.preferencesPhase.isBusy) return;
    final generation = _generation;
    state = state.copyWith(
      preferencesPhase: state.preferences == null
          ? ContentPhase.loading
          : ContentPhase.refreshing,
    );
    try {
      final preferences = await _repository.preferences();
      if (!ref.mounted || generation != _generation) return;
      state = state.copyWith(
        preferences: _preferenceWrites > 0 ? null : preferences,
        preferencesPhase: ContentPhase.ready,
      );
    } on Object catch (error) {
      if (!ref.mounted || generation != _generation) return;
      state = state.copyWith(
        preferencesPhase: ContentPhase.failure(error),
        message: describeError(error),
      );
    }
  }

  /// Turns every kind of update on or off for [channel].
  Future<bool> setChannel(NotificationChannel channel, bool enabled) {
    final topics = state.preferences?.topics ?? const <String>[];
    return _savePreferences({
      channel: {for (final topic in topics) topic: enabled},
    });
  }

  /// Shows the change at once, then saves it; a failed save is undone.
  Future<bool> _savePreferences(
    Map<NotificationChannel, Map<String, bool>> changes,
  ) async {
    final before = state.preferences;
    if (before == null || changes.values.every((topics) => topics.isEmpty)) {
      return false;
    }
    final generation = _generation;
    final previous = {
      for (final entry in changes.entries)
        entry.key: {
          for (final topic in entry.value.keys)
            topic: before.isOn(entry.key, topic),
        },
    };
    _preferenceWrites++;
    state = state.copyWith(
      preferences: before.merge(changes),
      clearError: true,
    );
    try {
      final saved = await _repository.savePreferences(changes);
      if (!ref.mounted || generation != _generation) return false;
      _preferenceWrites--;
      // With other toggles still saving, what is on screen is already newer.
      if (_preferenceWrites == 0) {
        state = state.copyWith(
          preferences: saved,
          profile: state.profile?.copyWith(notifications: saved),
        );
      }
      return true;
    } on Object catch (error) {
      if (!ref.mounted || generation != _generation) return false;
      _preferenceWrites--;
      final current = state.preferences ?? before;
      // Undo only what this save changed and no later toggle has replaced.
      final undo = {
        for (final entry in changes.entries)
          entry.key: {
            for (final topic in entry.value.entries)
              if (current.isOn(entry.key, topic.key) == topic.value)
                topic.key: previous[entry.key]![topic.key]!,
          },
      };
      state = state.copyWith(
        preferences: current.merge(undo),
        error: describeError(error),
      );
      return false;
    }
  }

  // Profile photo -------------------------------------------------------------

  /// The upload type for [bytes], or null when it is not PNG, JPG or WebP.
  static ({String contentType, String extension})? imageType(List<int> bytes) {
    bool starts(List<int> magic, [int offset = 0]) {
      if (bytes.length < offset + magic.length) return false;
      for (var i = 0; i < magic.length; i++) {
        if (bytes[offset + i] != magic[i]) return false;
      }
      return true;
    }

    if (starts(const [0x89, 0x50, 0x4E, 0x47])) {
      return (contentType: 'image/png', extension: 'png');
    }
    if (starts(const [0xFF, 0xD8, 0xFF])) {
      return (contentType: 'image/jpeg', extension: 'jpg');
    }
    if (starts(const [0x52, 0x49, 0x46, 0x46]) &&
        starts(const [0x57, 0x45, 0x42, 0x50], 8)) {
      return (contentType: 'image/webp', extension: 'webp');
    }
    return null;
  }

  /// Replaces the profile photo. [bytes] must be a PNG, JPG or WebP image.
  Future<bool> uploadAvatar(Uint8List bytes) async {
    if (state.avatarBusy) return false;
    final type = imageType(bytes);
    if (type == null) {
      state = state.copyWith(error: 'Choose a PNG, JPG or WebP image.');
      return false;
    }
    if (bytes.length > maxImageBytes) {
      state = state.copyWith(error: 'Choose a photo smaller than 5 MB.');
      return false;
    }
    return _changeAvatar(
      () => _repository.uploadImage(
        bytes: bytes,
        filename: 'profile.${type.extension}',
        contentType: type.contentType,
      ),
    );
  }

  Future<bool> removeAvatar() async {
    if (state.avatarBusy) return false;
    return _changeAvatar(() async {
      await _repository.removeImage();
      return null;
    });
  }

  Future<bool> _changeAvatar(Future<String?> Function() request) async {
    // The photo controls only exist once the profile has loaded.
    if (state.profile == null) return false;
    final generation = _generation;
    state = state.copyWith(avatarBusy: true, clearError: true);
    try {
      final url = await request();
      if (!ref.mounted || generation != _generation) return false;
      // A loaded profile is never cleared within a generation.
      final profile = state.profile!;
      final updated = profile.user.copyWith(profileImageUrl: () => url);
      // The home header shows the same picture.
      ref.read(accountControllerProvider.notifier).apply(user: updated);
      state = state.copyWith(
        profile: profile.copyWith(user: updated),
        avatarBusy: false,
      );
      return true;
    } on Object catch (error) {
      if (!ref.mounted || generation != _generation) return false;
      state = state.copyWith(
        avatarBusy: false,
        error: error is ApiException && error.statusCode == 413
            ? 'That photo is larger than 5 MB. Choose a smaller one.'
            : describeError(error),
      );
      return false;
    }
  }
}

final settingsControllerProvider =
    NotifierProvider<SettingsController, SettingsState>(SettingsController.new);
