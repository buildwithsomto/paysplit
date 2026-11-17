import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paysplit/core/config/api_config.dart';
import 'package:paysplit/core/config/app_config.dart';
import 'package:paysplit/core/session/session_controller.dart';
import 'package:paysplit/core/storage/app_preferences.dart';
import 'package:paysplit/core/storage/session_storage.dart';

final sessionStorageProvider = Provider<SessionStorage>((ref) {
  final environment = ref.watch(appConfigProvider).environment.name;
  final origin = Uri.parse(ref.watch(apiConfigProvider).origin);
  return SecureSessionStorage(
    preferences: ref.watch(appPreferencesProvider),
    // A token is only ever read back for the backend that issued it.
    namespace: 'paysplit.$environment.${origin.host}',
  );
});

final sessionControllerProvider =
    NotifierProvider<SessionController, SessionState>(SessionController.new);

/// Rebuilds user-scoped state when the signed-in user changes. Feature
/// controllers watch this so one account's data can never be shown to another.
final sessionUserIdProvider = Provider<String?>(
  (ref) => ref.watch(sessionControllerProvider.select((s) => s.userId)),
);
