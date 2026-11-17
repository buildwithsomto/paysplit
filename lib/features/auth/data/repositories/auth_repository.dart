import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paysplit/core/network/api_exception.dart';
import 'package:paysplit/core/network/json.dart';
import 'package:paysplit/core/session/auth_session.dart';
import 'package:paysplit/features/auth/data/data_sources/auth_data_source.dart';
import 'package:paysplit/features/auth/data/models/auth_models.dart';

class AuthRepository {
  const AuthRepository(this._source);
  final AuthDataSource _source;

  Future<CodeDelivery> signup({
    required String firstName,
    required String lastName,
    required String email,
  }) async => CodeDelivery.fromJson(
    await _source.signup({
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
    }),
  );

  Future<EmailVerification> verifyEmail(String email, String code) async =>
      EmailVerification.fromJson(await _source.verifyEmail(email, code));

  Future<CodeDelivery> resendEmailCode(String email) async =>
      CodeDelivery.fromJson(await _source.resendEmailCode(email));

  Future<SignedIn> setPassword({
    required String setupToken,
    required String password,
  }) async => SignedIn.fromJson(
    await _source.setPassword(setupToken, password),
    now: DateTime.now(),
  );

  /// Mobile sessions stay signed in, so the 30-day token is requested.
  Future<SignedIn> login({
    required String email,
    required String password,
  }) async => SignedIn.fromJson(
    await _source.login({
      'email': email,
      'password': password,
      'rememberMe': true,
    }),
    now: DateTime.now(),
  );

  Future<Account> me() async => Account.fromJson(await _source.me());

  /// Revokes every token for this user, on all devices.
  Future<void> logout() async {
    await _source.logout();
  }

  /// Other sessions are signed out; the returned session replaces this one.
  Future<AuthSession> changePassword({
    required String current,
    required String next,
    required String userId,
  }) async {
    final json = Json.from(await _source.changePassword(current, next));
    final lifetime = json.integer('expiresIn');
    if (lifetime <= 0) throw ApiException.invalidResponse;
    return AuthSession(
      accessToken: json.string('accessToken'),
      expiresAt: DateTime.now().toUtc().add(Duration(seconds: lifetime)),
      userId: userId,
    );
  }

  Future<CodeDelivery> forgotPassword(String email) async =>
      CodeDelivery.fromJson(await _source.forgotPassword(email));

  Future<void> verifyResetCode(String email, String code) async {
    await _source.verifyResetCode(email, code);
  }

  Future<void> resetPassword(String email, String password) async {
    await _source.resetPassword(email, password);
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(authDataSourceProvider)),
);
