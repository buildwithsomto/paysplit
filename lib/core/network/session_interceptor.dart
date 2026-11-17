import 'package:dio/dio.dart';
import 'package:paysplit/core/config/api_config.dart';
import 'package:paysplit/core/network/api_exception.dart';
import 'package:paysplit/core/network/api_request.dart';
import 'package:paysplit/core/session/session_controller.dart';

/// Attaches the session to authenticated requests and ends it when the API
/// stops accepting the token.
class SessionInterceptor extends Interceptor {
  SessionInterceptor(this._config, this._session);
  final ApiConfig _config;
  final SessionController _session;

  DioException _failure(RequestOptions request, ApiException error) =>
      DioException(requestOptions: request, error: error);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_config.allows(options.uri)) {
      handler.reject(
        _failure(
          options,
          const ApiException(
            code: 'invalid_api_destination',
            message: 'Invalid API destination.',
          ),
        ),
      );
      return;
    }
    final bearer = options.extra[ApiRequest.bearerKey];
    if (bearer is String) {
      options.headers['Authorization'] = 'Bearer $bearer';
      handler.next(options);
      return;
    }
    if (options.extra[ApiRequest.authenticatedKey] == false) {
      handler.next(options);
      return;
    }
    try {
      final revision = _session.revision;
      final session = await _session.current();
      if (session == null) throw ApiException.sessionExpired;
      if (revision != _session.revision) throw ApiException.sessionChanged;
      options.headers['Authorization'] = 'Bearer ${session.accessToken}';
      handler.next(options);
    } on Object catch (error) {
      handler.reject(
        _failure(
          options,
          error is ApiException ? error : ApiException.storageUnavailable,
        ),
      );
    }
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final request = err.requestOptions;
    final body = err.response?.data;
    // Domain errors also use 401 (for example INVALID_CURRENT_PASSWORD) and
    // carry a `code`. Only an uncoded 401 means the token was refused.
    final tokenRefused =
        err.response?.statusCode == 401 &&
        request.extra[ApiRequest.authenticatedKey] != false &&
        !(body is Map && body['code'] is String);
    if (!tokenRefused) {
      handler.next(err);
      return;
    }
    final header = request.headers['Authorization'];
    if (header is String && header.startsWith('Bearer ')) {
      await _session.reject(header.substring(7));
    }
    handler.reject(_failure(request, ApiException.sessionExpired));
  }
}
