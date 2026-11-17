import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paysplit/core/routing/app_router.dart';
import 'package:paysplit/theme/app_theme.dart';

class PaySplitApp extends ConsumerWidget {
  const PaySplitApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
    restorationScopeId: 'paysplit_app',
    title: 'PaySplit',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    routerConfig: ref.watch(appRouterProvider),
    // A tap that no control claims closes the keyboard. The number pad has no
    // "done" key, so this is the only way to dismiss it without scrolling.
    builder: (context, child) => GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: child,
    ),
  );
}
