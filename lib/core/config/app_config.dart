import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Deployment names contain public configuration, never credentials.
enum AppEnvironment { dev, prod }

/// Build-time switches.
@immutable
class AppConfig {
  const AppConfig({
    required this.environment,
    required this.sandboxToolsEnabled,
  });

  factory AppConfig.fromEnvironment() {
    const name = String.fromEnvironment('APP_ENV', defaultValue: 'dev');
    final environment = AppEnvironment.values.byName(name);
    return AppConfig(
      environment: environment,
      // Sandbox tools (simulated salary credit) exist on dev and QA
      // backends only, so they follow the environment, not the build mode.
      sandboxToolsEnabled: environment != AppEnvironment.prod,
    );
  }

  final AppEnvironment environment;
  final bool sandboxToolsEnabled;
}

final appConfigProvider = Provider<AppConfig>(
  (ref) => AppConfig.fromEnvironment(),
);
