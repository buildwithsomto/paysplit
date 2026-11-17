import 'package:dio/dio.dart';
import 'package:paysplit/core/config/api_config.dart';
import 'package:paysplit/core/network/api_error_mapper.dart';
import 'package:paysplit/core/network/api_exception.dart';
import 'package:paysplit/core/network/api_request.dart';

/// One file part of a multipart upload.
class ApiFile {
  const ApiFile({
    required this.field,
    required this.bytes,
    required this.filename,
    required this.contentType,
  });
  final String field;
  final List<int> bytes;
  final String filename;
  final String contentType;
}

/// The only way features reach the API. Paths are relative to `/api/v1`,
/// for example `/wallets`; query parameters are passed separately.
abstract interface class ApiClient {
  Future<Object?> get(
    String path, {
    Map<String, Object?>? query,
    ApiRequest request = const ApiRequest(),
  });
  Future<Object?> post(
    String path, {
    Object? data,
    ApiRequest request = const ApiRequest(),
  });
  Future<Object?> put(
    String path, {
    Object? data,
    ApiRequest request = const ApiRequest(),
  });
  Future<Object?> patch(
    String path, {
    Object? data,
    ApiRequest request = const ApiRequest(),
  });
  Future<Object?> delete(
    String path, {
    ApiRequest request = const ApiRequest(),
  });

  /// Sends `multipart/form-data` with text [fields] and binary [files].
  Future<Object?> upload(
    String path, {
    String method = 'POST',
    Map<String, String> fields = const {},
    required List<ApiFile> files,
  });

  /// Fetches a non-JSON document, such as the CSV statement.
  Future<String> getText(String path, {Map<String, Object?>? query});
}

class DioApiClient implements ApiClient {
  DioApiClient(this._dio);
  final Dio _dio;
  static const _errorMapper = ApiErrorMapper();

  @override
  Future<Object?> get(
    String path, {
    Map<String, Object?>? query,
    ApiRequest request = const ApiRequest(),
  }) => _execute('GET', path, query: query, request: request);

  @override
  Future<Object?> post(
    String path, {
    Object? data,
    ApiRequest request = const ApiRequest(),
  }) => _execute('POST', path, data: data, request: request);

  @override
  Future<Object?> put(
    String path, {
    Object? data,
    ApiRequest request = const ApiRequest(),
  }) => _execute('PUT', path, data: data, request: request);

  @override
  Future<Object?> patch(
    String path, {
    Object? data,
    ApiRequest request = const ApiRequest(),
  }) => _execute('PATCH', path, data: data, request: request);

  @override
  Future<Object?> delete(
    String path, {
    ApiRequest request = const ApiRequest(),
  }) => _execute('DELETE', path, request: request);

  @override
  Future<Object?> upload(
    String path, {
    String method = 'POST',
    Map<String, String> fields = const {},
    required List<ApiFile> files,
  }) => _execute(
    method,
    path,
    request: const ApiRequest(),
    // Rebuilt per call: a FormData stream can only be sent once.
    data: FormData.fromMap({
      ...fields,
      for (final file in files)
        file.field: MultipartFile.fromBytes(
          file.bytes,
          filename: file.filename,
          contentType: DioMediaType.parse(file.contentType),
        ),
    }),
    // Uploads over mobile data need longer than a JSON call.
    sendTimeout: const Duration(seconds: 60),
  );

  @override
  Future<String> getText(String path, {Map<String, Object?>? query}) async {
    final body = await _execute(
      'GET',
      path,
      query: query,
      request: const ApiRequest(),
      responseType: ResponseType.plain,
    );
    if (body is! String) throw ApiException.invalidResponse;
    return body;
  }

  Future<Object?> _execute(
    String method,
    String path, {
    Object? data,
    Map<String, Object?>? query,
    required ApiRequest request,
    ResponseType? responseType,
    Duration? sendTimeout,
  }) async {
    final uri = Uri.tryParse(path);
    if (uri == null ||
        uri.hasScheme ||
        uri.hasAuthority ||
        !path.startsWith('/') ||
        path.contains('..') ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw ArgumentError(
        'Use a path relative to the API root and pass query parameters separately.',
      );
    }
    try {
      final response = await _dio.request<Object?>(
        '${ApiConfig.apiPrefix}$path',
        data: data,
        // Null and empty values mean "no filter" and are not sent.
        queryParameters: query == null
            ? null
            : {
                for (final entry in query.entries)
                  if (entry.value != null && entry.value != '')
                    entry.key: entry.value,
              },
        options: Options(
          method: method,
          responseType: responseType,
          sendTimeout: sendTimeout,
          extra: {
            ApiRequest.authenticatedKey: request.authenticated,
            ApiRequest.bearerKey: ?request.bearer,
          },
        ),
      );
      return response.data;
    } on DioException catch (error) {
      throw _errorMapper.map(error);
    }
  }
}

/// Path segments come from server IDs; encode them before interpolation.
String pathSegment(String value) => Uri.encodeComponent(value);
