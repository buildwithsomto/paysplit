import 'dart:async';

enum ApiFailureKind {
  server,
  unauthorized,
  validation,
  rateLimited,
  network,
  timeout,
  invalidResponse,
  storage,
}

/// A failure the presentation layer can act on, independent of Dio.
///
/// [code] is the server's `code` (for example `WALLET_NAME_TAKEN`) when the
/// API supplied one, otherwise a lower-case local code. [message] is always
/// safe to show to the user.
class ApiException implements Exception {
  const ApiException({
    required this.code,
    required this.message,
    this.kind = ApiFailureKind.server,
    this.statusCode,
    this.fieldErrors = const {},
    this.attemptsRemaining,
  });

  static const invalidResponse = ApiException(
    code: 'invalid_response',
    message: 'We could not read the server response. Please try again.',
    kind: ApiFailureKind.invalidResponse,
  );
  static const sessionExpired = ApiException(
    code: 'session_expired',
    message: 'Your session has ended. Please log in again.',
    kind: ApiFailureKind.unauthorized,
    statusCode: 401,
  );
  static const sessionChanged = ApiException(
    code: 'session_changed',
    message: 'Your session changed. Please try again.',
    kind: ApiFailureKind.unauthorized,
  );
  static const storageUnavailable = ApiException(
    code: 'secure_storage_unavailable',
    message: 'Secure storage is unavailable. Please try again.',
    kind: ApiFailureKind.storage,
  );

  static const genericMessage =
      'We could not complete this request. Please try again.';

  final String code;
  final String message;
  final ApiFailureKind kind;
  final int? statusCode;

  /// Keyed by the API's field name, for example `phoneNumber`.
  final Map<String, List<String>> fieldErrors;

  /// Present on KYC failures that consume a limited attempt.
  final int? attemptsRemaining;

  /// The request never produced a server answer, so its outcome is unknown.
  bool get isConnectivity =>
      kind == ApiFailureKind.network || kind == ApiFailureKind.timeout;

  String? fieldError(String field) => fieldErrors[field]?.firstOrNull;

  // Never stringify server payloads, field values, tokens or request details.
  @override
  String toString() => 'ApiException($code)';
}

/// The message to show for any thrown object, without leaking internals.
String describeError(Object error, {String? fallback}) => error is ApiException
    ? error.message
    : fallback ?? ApiException.genericMessage;

/// The failure behind a thrown object.
///
/// Two requests awaited together with `.wait` fail as a [ParallelWaitError]
/// that holds each request's error wrapped in an [AsyncError]. This returns
/// the first of them, so an offline request is still recognized as offline.
Object failureCause(Object error) {
  if (error is! ParallelWaitError) return error;
  return switch (error.errors) {
    (final AsyncError? first, final AsyncError? second) =>
      (first ?? second)?.error ?? error,
    _ => error,
  };
}
