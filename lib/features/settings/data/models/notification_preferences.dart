import 'package:paysplit/core/network/json.dart';

/// The ways PaySplit can reach the user.
enum NotificationChannel {
  push('push', 'Push'),
  sms('sms', 'SMS'),
  email('email', 'Email');

  const NotificationChannel(this.key, this.label);

  /// The API's key for this channel.
  final String key;
  final String label;
}

/// `{preferences: {push|sms|email: {topic: bool}}, topics: {topic: label},
/// deliveredChannels: [..]}` as returned by the profile and preference calls.
/// Every channel holds a choice for every topic.
class NotificationPreferences {
  NotificationPreferences({
    required List<String> topics,
    required Map<NotificationChannel, Map<String, bool>> values,
  }) : topics = List.unmodifiable(topics),
       _values = Map.unmodifiable({
         for (final entry in values.entries)
           entry.key: Map<String, bool>.unmodifiable(entry.value),
       });

  factory NotificationPreferences.fromJson(Object? value) {
    final json = Json.from(value);
    final preferences = json.object('preferences');
    final topics = json.object('topics').keys.toList();
    return NotificationPreferences(
      topics: topics,
      values: {
        for (final channel in NotificationChannel.values)
          channel: {
            for (final topic in topics)
              topic: preferences.object(channel.key).boolean(topic),
          },
      },
    );
  }

  /// The API's keys for the kinds of update, for example `salaryReceived`.
  final List<String> topics;
  final Map<NotificationChannel, Map<String, bool>> _values;

  bool isOn(NotificationChannel channel, String topic) =>
      _values[channel]?[topic] ?? false;

  /// A channel is on while it carries at least one kind of update.
  bool channelOn(NotificationChannel channel) =>
      topics.any((topic) => isOn(channel, topic));

  /// A copy with [changes] laid over the current choices.
  NotificationPreferences merge(
    Map<NotificationChannel, Map<String, bool>> changes,
  ) => NotificationPreferences(
    topics: topics,
    values: {
      for (final channel in NotificationChannel.values)
        channel: {...?_values[channel], ...?changes[channel]},
    },
  );
}
