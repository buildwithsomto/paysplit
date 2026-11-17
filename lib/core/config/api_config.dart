import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paysplit/core/config/app_config.dart';

/// Public connection settings. Never put credentials in dart-defines.
class ApiConfig {
  ApiConfig({required String baseUrl}) {
    final uri = Uri.tryParse(baseUrl);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        (uri.path.isNotEmpty && uri.path != '/')) {
      throw ArgumentError('API_BASE_URL must be an HTTPS origin.');
    }
    origin = uri.origin;
  }

  /// The hosted TN Build sandbox. Used only when a dev build supplies no URL,
  /// so `flutter run` works for reviewers without an environment file.
  static const devOrigin =
      'https://paysplit-be-dev-14573850302.europe-west1.run.app';
  static const apiPrefix = '/api/v1';

  late final String origin;

  /// Requests may only leave the app for the configured API surface.
  bool allows(Uri uri) =>
      uri.scheme == 'https' &&
      uri.origin == origin &&
      uri.path.startsWith('$apiPrefix/');
}

final apiConfigProvider = Provider<ApiConfig>((ref) {
  const supplied = String.fromEnvironment('API_BASE_URL');
  final environment = ref.watch(appConfigProvider).environment;
  return ApiConfig(
    baseUrl: supplied.isEmpty && environment == AppEnvironment.dev
        ? ApiConfig.devOrigin
        : supplied,
  );
});
