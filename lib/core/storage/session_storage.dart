import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:paysplit/core/network/api_exception.dart';
import 'package:paysplit/core/session/auth_session.dart';
import 'package:paysplit/core/storage/app_preferences.dart';

abstract interface class SessionStorage {
  Future<AuthSession?> readSession();
  Future<void> writeSession(AuthSession session);
  Future<void> clearSession();
}

/// Keeps the access token in the Keychain / Android Keystore.
class SecureSessionStorage implements SessionStorage {
  SecureSessionStorage({required this._preferences, required String namespace})
    : _installationMarker = 'installation.$namespace',
      _storage = FlutterSecureStorage(
        aOptions: AndroidOptions(storageNamespace: namespace),
        iOptions: IOSOptions(
          accountName: namespace,
          accessibility: KeychainAccessibility.unlocked_this_device,
        ),
      );

  static const _sessionKey = 'paysplit.auth.session';
  final FlutterSecureStorage _storage;
  final AppPreferences _preferences;
  final String _installationMarker;
  Future<void>? _prepared;

  Future<void> _prepareInstallation() => _prepared ??= _prepare();

  Future<void> _prepare() async {
    try {
      // The iOS Keychain can survive an uninstall. This non-sensitive marker
      // stops a previous installation's session from signing a new one in.
      if (await _preferences.readBool(_installationMarker) != true) {
        await _storage.delete(key: _sessionKey);
        await _preferences.writeBool(_installationMarker, true);
      }
    } on Object {
      _prepared = null;
      throw ApiException.storageUnavailable;
    }
  }

  @override
  Future<AuthSession?> readSession() async {
    try {
      await _prepareInstallation();
      final raw = await _storage.read(key: _sessionKey);
      if (raw == null) return null;
      // A stored value this version cannot read is discarded.
      try {
        final json = jsonDecode(raw);
        if (json is Map<String, dynamic>) {
          return AuthSession.fromStorageJson(json);
        }
      } on Object {
        // Falls through to the delete below.
      }
      await _storage.delete(key: _sessionKey);
      return null;
    } on Object {
      throw ApiException.storageUnavailable;
    }
  }

  @override
  Future<void> writeSession(AuthSession session) async {
    try {
      await _prepareInstallation();
      await _storage.write(
        key: _sessionKey,
        value: jsonEncode(session.toStorageJson()),
      );
    } on Object {
      throw ApiException.storageUnavailable;
    }
  }

  @override
  Future<void> clearSession() async {
    try {
      await _prepareInstallation();
      await _storage.delete(key: _sessionKey);
    } on Object {
      throw ApiException.storageUnavailable;
    }
  }
}
