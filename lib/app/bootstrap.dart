import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paysplit/app/app.dart';

/// Initializes the app shell. The splash screen restores the session.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LiquidGlassWidgets.initialize();
  runApp(
    ProviderScope(
      // A failed request stays failed until the user retries. Riverpod's
      // default repeats it in the background for up to a minute, which keeps
      // an offline screen on its loading state instead of saying why.
      retry: (_, _) => null,
      child: LiquidGlassWidgets.wrap(
        brightnessResolver: Theme.maybeBrightnessOf,
        child: const PaySplitApp(),
      ),
    ),
  );
}
