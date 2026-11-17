import 'package:paysplit/core/network/api_exception.dart';
import 'package:paysplit/core/network/json.dart';

/// Only the credential belongs here; profile data stays in feature models.
///
/// The API issues a single access token (24 hours, or 30 days with
/// "remember me") and no refresh token, so an expired session means signing
/// in again.
class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.expiresAt,
    required this.userId,
  });

  /// Reads `{accessToken, expiresIn, user: {id}}` from a sign-in response.
  factory AuthSession.fromResponse(Object? value, {required DateTime now}) {
    final json = Json.from(value);
    final lifetime = json.integer('expiresIn');
    if (lifetime <= 0) throw ApiException.invalidResponse;
    return AuthSession(
      accessToken: json.string('accessToken'),
      expiresAt: now.toUtc().add(Duration(seconds: lifetime)),
      userId: json.object('user').string('id'),
    );
  }

  factory AuthSession.fromStorageJson(Map<String, dynamic> value) {
    final json = Json(value);
    final expiry = DateTime.tryParse(json.string('expiresAt'));
    if (expiry == null) throw ApiException.invalidResponse;
    return AuthSession(
      accessToken: json.string('accessToken'),
      expiresAt: expiry.toUtc(),
      userId: json.string('userId'),
    );
  }

  final String accessToken, userId;
  final DateTime expiresAt;

  bool isExpired(DateTime now) => !expiresAt.isAfter(now.toUtc());

  Map<String, Object> toStorageJson() => {
    'accessToken': accessToken,
    'expiresAt': expiresAt.toUtc().toIso8601String(),
    'userId': userId,
  };

  @override
  String toString() => 'AuthSession([redacted])';
}
