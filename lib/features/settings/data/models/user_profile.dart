import 'package:paysplit/core/network/json.dart';
import 'package:paysplit/features/auth/data/models/auth_models.dart';
import 'package:paysplit/features/settings/data/models/notification_preferences.dart';
import 'package:paysplit/features/setup/data/models/income.dart';

/// Everything Profile & Settings shows, from `GET /users/me/profile`.
/// `PATCH /users/me` answers with the same shape.
class UserProfile {
  const UserProfile({
    required this.user,
    required this.accountId,
    required this.namesLocked,
    required this.onboarding,
    this.income,
    this.notifications,
  });

  factory UserProfile.fromJson(Object? value) {
    final json = Json.from(value);
    final notifications = json.objectOrNull('notificationPreferences');
    return UserProfile(
      user: AppUser.fromJson(json.object('user')),
      accountId: json.string('accountId'),
      namesLocked: json.boolean('namesLocked'),
      income: Income.fromJsonOrNull(json.objectOrNull('income')),
      notifications: notifications == null
          ? null
          : NotificationPreferences.fromJson(notifications),
      onboarding: Onboarding.fromJson(json.object('onboarding')),
    );
  }

  final AppUser user;

  /// The public account reference, for example `USER265119E6`.
  final String accountId;

  /// First and last name cannot change once identity verification is approved.
  final bool namesLocked;

  /// Null until the salary income source is set.
  final Income? income;
  final NotificationPreferences? notifications;
  final Onboarding onboarding;

  UserProfile copyWith({
    AppUser? user,
    Income? income,
    NotificationPreferences? notifications,
    Onboarding? onboarding,
  }) => UserProfile(
    user: user ?? this.user,
    accountId: accountId,
    namesLocked: namesLocked,
    income: income ?? this.income,
    notifications: notifications ?? this.notifications,
    onboarding: onboarding ?? this.onboarding,
  );

  @override
  String toString() => 'UserProfile([redacted])';
}
