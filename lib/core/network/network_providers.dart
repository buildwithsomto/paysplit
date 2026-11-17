import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paysplit/core/config/api_config.dart';
import 'package:paysplit/core/network/api_client.dart';
import 'package:paysplit/core/network/http_client_factory.dart';
import 'package:paysplit/core/network/session_interceptor.dart';
import 'package:paysplit/core/session/session_providers.dart';

final dioProvider = Provider<Dio>((ref) {
  final config = ref.watch(apiConfigProvider);
  final session = ref.watch(sessionControllerProvider.notifier);
  final dio = createHttpClient(config);
  dio.interceptors.insert(0, SessionInterceptor(config, session));
  ref.onDispose(() => dio.close(force: true));
  return dio;
});

final apiClientProvider = Provider<ApiClient>(
  (ref) => DioApiClient(ref.watch(dioProvider)),
);
