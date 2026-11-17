import 'package:dio/dio.dart';
import 'package:paysplit/core/config/api_config.dart';

Dio createHttpClient(ApiConfig config) => Dio(
  BaseOptions(
    baseUrl: config.origin,
    connectTimeout: const Duration(seconds: 15),
    sendTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    responseType: ResponseType.json,
    headers: {Headers.acceptHeader: Headers.jsonContentType},
    followRedirects: false,
  ),
);
