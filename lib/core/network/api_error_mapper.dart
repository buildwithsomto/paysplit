import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:paysplit/core/network/api_exception.dart';

/// Turns transport and API failures into [ApiException]s.
///
/// The API answers errors as `{statusCode, error, message, code?}`. Domain
/// errors carry a stable `code` and a user-facing `message`; request
/// validation answers 400 with a list of technical messages and no code.
class ApiErrorMapper {
  const ApiErrorMapper();

  ApiException map(DioException exception) {
    if (exception.error case final ApiException error) return error;
    final response = exception.response;
    if (response != null) {
      return _fromResponse(response.statusCode, response.data);
    }
    final (code, message, kind) = switch (exception.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => (
        'request_timeout',
        'The connection timed out. Check your connection and try again.',
        ApiFailureKind.timeout,
      ),
      DioExceptionType.connectionError => (
        'network_unavailable',
        'You’re offline. Check your internet connection and try again.',
        ApiFailureKind.network,
      ),
      _ =>
        exception.error is SocketException ||
                exception.error is HandshakeException
            ? (
                'network_unavailable',
                'You’re offline. Check your internet connection and try again.',
                ApiFailureKind.network,
              )
            : (
                'request_failed',
                ApiException.genericMessage,
                ApiFailureKind.server,
              ),
    };
    return ApiException(code: code, message: message, kind: kind);
  }

  ApiException _fromResponse(int? status, Object? data) {
    final body = _body(data);
    final serverCode = body?['code'];
    final code = serverCode is String && _codePattern.hasMatch(serverCode)
        ? serverCode
        : null;
    final rawMessage = body?['message'];
    final attempts = body?['attemptsRemaining'];

    if (status == 400 && rawMessage is List && code == null) {
      return ApiException(
        code: 'validation_failed',
        message: 'Check the highlighted details and try again.',
        kind: ApiFailureKind.validation,
        statusCode: status,
        fieldErrors: _fieldErrors(rawMessage),
      );
    }

    final serverMessage = _presentable(rawMessage);
    final kind = switch (status) {
      401 => ApiFailureKind.unauthorized,
      429 => ApiFailureKind.rateLimited,
      400 || 422 => ApiFailureKind.validation,
      _ => ApiFailureKind.server,
    };
    final message = switch (status) {
      // A coded error's message is written for the user by the API.
      _ when code != null && serverMessage != null => serverMessage,
      401 => serverMessage ?? ApiException.sessionExpired.message,
      403 => serverMessage ?? 'You don’t have access to this yet.',
      404 => serverMessage ?? 'We could not find what you were looking for.',
      409 || 422 => serverMessage ?? ApiException.genericMessage,
      429 =>
        serverMessage ??
            'Too many attempts. Please wait a moment and try again.',
      final int s when s >= 500 =>
        'PaySplit is having trouble right now. Please try again shortly.',
      _ => ApiException.genericMessage,
    };
    return ApiException(
      code: code ?? 'http_${status ?? 0}',
      message: message,
      kind: kind,
      statusCode: status,
      attemptsRemaining: attempts is int ? attempts : null,
    );
  }

  static final _codePattern = RegExp(r'^[A-Z][A-Z0-9_]{0,79}$');

  /// Error bodies arrive as text when the request asked for a non-JSON type.
  Map<Object?, Object?>? _body(Object? data) {
    if (data is Map) return data;
    if (data is String && data.startsWith('{')) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map) return decoded;
      } on FormatException {
        return null;
      }
    }
    return null;
  }

  /// Framework messages such as "Cannot GET /x" are not shown to users.
  String? _presentable(Object? value) {
    if (value is! String) return null;
    final text = value.trim();
    if (text.isEmpty ||
        text.length > 240 ||
        text.startsWith('Cannot ') ||
        text.startsWith('Validation failed')) {
      return null;
    }
    return text;
  }

  /// Validation messages start with the offending property name.
  Map<String, List<String>> _fieldErrors(List<Object?> messages) {
    final fields = <String, List<String>>{};
    for (final message in messages.whereType<String>()) {
      final words = message.split(' ');
      var field = words.first;
      if (field == 'property' && words.length > 1) field = words[1];
      if (!RegExp(r'^[a-z][A-Za-z0-9.]*$').hasMatch(field)) continue;
      (fields[field] ??= []).add(message);
    }
    return Map.unmodifiable({
      for (final entry in fields.entries)
        entry.key: List<String>.unmodifiable(entry.value),
    });
  }
}
