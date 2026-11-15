import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paysplit/app/app.dart';
import 'package:paysplit/core/config/app_config.dart';

/// Initializes the presentation app without starting remote services.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfig.fromEnvironment();
  await LiquidGlassWidgets.initialize();
  runApp(
    ProviderScope(
      overrides: [appConfigProvider.overrideWithValue(config)],
      child: LiquidGlassWidgets.wrap(
        brightnessResolver: Theme.maybeBrightnessOf,
        child: const PaySplitApp(),
      ),
    ),
  );
}
