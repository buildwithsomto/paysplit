import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Non-sensitive preferences only. Tokens, identity data and payment details
/// never belong here; the session uses the platform's secure store.
abstract interface class AppPreferences {
  Future<bool?> readBool(String key);
  Future<void> writeBool(String key, bool value);
}

class LocalAppPreferences implements AppPreferences {
  LocalAppPreferences() : _preferences = SharedPreferencesAsync();
  final SharedPreferencesAsync _preferences;

  @override
  Future<bool?> readBool(String key) => _preferences.getBool('paysplit.$key');

  @override
  Future<void> writeBool(String key, bool value) =>
      _preferences.setBool('paysplit.$key', value);
}

final appPreferencesProvider = Provider<AppPreferences>(
  (ref) => LocalAppPreferences(),
);
