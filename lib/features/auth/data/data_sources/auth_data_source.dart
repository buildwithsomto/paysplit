import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paysplit/core/network/api_client.dart';
import 'package:paysplit/core/network/api_request.dart';
import 'package:paysplit/core/network/network_providers.dart';

class AuthDataSource {
  const AuthDataSource(this._client);
  final ApiClient _client;

  Future<Object?> signup(Map<String, Object?> body) =>
      _client.post('/auth/signup', request: ApiRequest.public, data: body);
  Future<Object?> verifyEmail(String email, String code) => _client.post(
    '/auth/email/verify',
    request: ApiRequest.public,
    data: {'email': email, 'code': code},
  );
  Future<Object?> resendEmailCode(String email) => _client.post(
    '/auth/email/resend',
    request: ApiRequest.public,
    data: {'email': email},
  );
  Future<Object?> setPassword(String setupToken, String password) =>
      _client.post(
        '/auth/password/set',
        request: ApiRequest.withToken(setupToken),
        data: {'password': password, 'confirmPassword': password},
      );
  Future<Object?> login(Map<String, Object?> body) =>
      _client.post('/auth/login', request: ApiRequest.public, data: body);
  Future<Object?> me() => _client.get('/auth/me');
  Future<Object?> logout() => _client.post('/auth/logout');
  Future<Object?> changePassword(String current, String next) => _client.post(
    '/auth/password/change',
    data: {
      'currentPassword': current,
      'newPassword': next,
      'confirmPassword': next,
    },
  );
  Future<Object?> forgotPassword(String email) => _client.post(
    '/auth/password/forgot',
    request: ApiRequest.public,
    data: {'email': email},
  );
  Future<Object?> verifyResetCode(String email, String code) => _client.post(
    '/auth/password/verify-code',
    request: ApiRequest.public,
    data: {'email': email, 'code': code},
  );
  Future<Object?> resetPassword(String email, String password) => _client.post(
    '/auth/password/reset',
    request: ApiRequest.public,
    data: {'email': email, 'newPassword': password},
  );
}

final authDataSourceProvider = Provider<AuthDataSource>(
  (ref) => AuthDataSource(ref.watch(apiClientProvider)),
);
