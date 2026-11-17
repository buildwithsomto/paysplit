import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paysplit/core/network/api_client.dart';
import 'package:paysplit/core/network/json.dart';
import 'package:paysplit/features/settings/data/data_sources/profile_data_source.dart';
import 'package:paysplit/features/settings/data/models/notification_preferences.dart';
import 'package:paysplit/features/settings/data/models/user_profile.dart';

class ProfileRepository {
  const ProfileRepository(this._source);
  final ProfileDataSource _source;

  Future<UserProfile> profile() async =>
      UserProfile.fromJson(await _source.profile());

  /// Sends only the details that changed. Names answer `409 NAME_LOCKED`
  /// once identity verification is approved; a bad number `422 INVALID_PHONE`.
  Future<UserProfile> updateDetails({
    String? firstName,
    String? lastName,
    String? phoneNumber,
  }) async => UserProfile.fromJson(
    await _source.updateDetails({
      'firstName': ?firstName,
      'lastName': ?lastName,
      'phoneNumber': ?phoneNumber,
    }),
  );

  Future<NotificationPreferences> preferences() async =>
      NotificationPreferences.fromJson(await _source.preferences());

  /// A partial update: only the listed channels and topics change.
  Future<NotificationPreferences> savePreferences(
    Map<NotificationChannel, Map<String, bool>> changes,
  ) async => NotificationPreferences.fromJson(
    await _source.savePreferences({
      for (final entry in changes.entries) entry.key.key: entry.value,
    }),
  );

  /// PNG, JPG or WebP up to 5 MB. Returns the new picture's address.
  Future<String> uploadImage({
    required List<int> bytes,
    required String filename,
    required String contentType,
  }) async => Json.from(
    await _source.uploadImage(
      ApiFile(
        field: 'image',
        bytes: bytes,
        filename: filename,
        contentType: contentType,
      ),
    ),
  ).string('profileImageUrl');

  Future<void> removeImage() async {
    await _source.removeImage();
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(profileDataSourceProvider)),
);
