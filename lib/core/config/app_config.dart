import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Deployment names contain public configuration, never credentials.
enum AppEnvironment { dev, staging, prod }

/// Build-time switches for the presentation-only milestone.
@immutable
class AppConfig {
  const AppConfig({required this.environment, required this.showcaseEnabled});

  factory AppConfig.fromEnvironment() {
    const name = String.fromEnvironment('APP_ENV', defaultValue: 'dev');
    final environment = AppEnvironment.values.byName(name);
    return AppConfig(
      environment: environment,
      showcaseEnabled:
          kDebugMode &&
          environment != AppEnvironment.prod &&
          const bool.fromEnvironment('ENABLE_SHOWCASE', defaultValue: true),
    );
  }

  final AppEnvironment environment;
  final bool showcaseEnabled;
}

final appConfigProvider = Provider<AppConfig>(
  (ref) => AppConfig.fromEnvironment(),
);
