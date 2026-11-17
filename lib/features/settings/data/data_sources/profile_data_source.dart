import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paysplit/core/network/api_client.dart';
import 'package:paysplit/core/network/network_providers.dart';

class ProfileDataSource {
  const ProfileDataSource(this._client);
  final ApiClient _client;

  Future<Object?> profile() => _client.get('/users/me/profile');
  Future<Object?> updateDetails(Map<String, Object?> body) =>
      _client.patch('/users/me', data: body);
  Future<Object?> preferences() =>
      _client.get('/users/me/notification-preferences');
  Future<Object?> savePreferences(Map<String, Object?> body) =>
      _client.put('/users/me/notification-preferences', data: body);
  Future<Object?> uploadImage(ApiFile image) =>
      _client.upload('/users/me/profile-image', method: 'PUT', files: [image]);
  Future<Object?> removeImage() => _client.delete('/users/me/profile-image');
}

final profileDataSourceProvider = Provider<ProfileDataSource>(
  (ref) => ProfileDataSource(ref.watch(apiClientProvider)),
);
