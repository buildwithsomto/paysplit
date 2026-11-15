import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum NotificationChannel { push, sms, email }

@immutable
class DevicePreview {
  const DevicePreview({
    required this.id,
    required this.name,
    required this.location,
    required this.lastSeen,
    this.current = false,
  });
  final String id, name, location, lastSeen;
  final bool current;
}

@immutable
class SettingsState {
  const SettingsState({
    this.channels = const {
      NotificationChannel.push,
      NotificationChannel.sms,
      NotificationChannel.email,
    },
    this.devices = const [],
    this.sampleAccount = false,
    this.avatar,
  });
  final Set<NotificationChannel> channels;
  final List<DevicePreview> devices;
  final bool sampleAccount;
  final Uint8List? avatar;
  SettingsState copyWith({
    Set<NotificationChannel>? channels,
    List<DevicePreview>? devices,
    bool? sampleAccount,
    Uint8List? avatar,
    bool clearAvatar = false,
  }) => SettingsState(
    channels: Set.unmodifiable(channels ?? this.channels),
    devices: List.unmodifiable(devices ?? this.devices),
    sampleAccount: sampleAccount ?? this.sampleAccount,
    avatar: clearAvatar ? null : avatar ?? this.avatar,
  );
}

class SettingsController extends Notifier<SettingsState> {
  @override
  SettingsState build() => const SettingsState();
  void setChannel(NotificationChannel channel, bool enabled) {
    final channels = {...state.channels};
    enabled ? channels.add(channel) : channels.remove(channel);
    state = state.copyWith(channels: channels);
  }

  void setAvatar(Uint8List bytes) => state = state.copyWith(
    avatar: Uint8List.fromList(bytes).asUnmodifiableView(),
  );
  void clearAvatar() => state = state.copyWith(clearAvatar: true);
  void loadSampleDevices() => state = state.copyWith(
    sampleAccount: true,
    devices: const [
      DevicePreview(
        id: 'sample-current',
        name: 'iPhone XR',
        location: 'Lagos, Nigeria',
        lastSeen: 'Oct 2026',
        current: true,
      ),
      DevicePreview(
        id: 'sample-other',
        name: 'Samsung S22 Ultra',
        location: 'Ogun, Nigeria',
        lastSeen: 'Jan 2026',
      ),
    ],
  );
  void removeSampleDevice(String id) => state = state.copyWith(
    devices: state.devices.where((d) => d.id != id).toList(),
  );
  void clearSampleDevices() => state = state.copyWith(devices: []);
}

final settingsControllerProvider =
    NotifierProvider<SettingsController, SettingsState>(SettingsController.new);

/// Validates form input only; does not authenticate or retain passwords.
Map<String, String> validatePasswordChange(String current, String next) => {
  if (current.isEmpty) 'current': 'Enter your current password.',
  if (next.length < 8)
    'next': 'Use at least 8 characters.'
  else if (next == current)
    'next': 'Choose a different password.',
};
