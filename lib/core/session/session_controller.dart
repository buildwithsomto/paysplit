import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paysplit/core/session/auth_session.dart';
import 'package:paysplit/core/session/session_providers.dart';
import 'package:paysplit/core/storage/session_storage.dart';

enum SessionStatus { unknown, authenticated, signedOut }

/// What the rest of the app may know about the session. The token itself
/// stays private to this boundary and never enters Riverpod state.
class SessionState {
  const SessionState(this.status, {this.userId, this.expired = false});
  final SessionStatus status;
  final String? userId;

  /// The session ended without the user asking (expired or revoked), so the
  /// login screen explains why they are there.
  final bool expired;

  bool get isAuthenticated => status == SessionStatus.authenticated;
}

class SessionController extends Notifier<SessionState> {
  late SessionStorage _storage;
  AuthSession? _session;
  bool _restored = false;
  int _revision = 0;
  Future<void>? _restoring;
  Future<void> _writes = Future.value();

  /// Changes whenever the signed-in identity or token changes. A request that
  /// was being prepared across such a change is refused instead of being sent
  /// with the wrong session.
  int get revision => _revision;

  @override
  SessionState build() {
    _storage = ref.watch(sessionStorageProvider);
    _revision++;
    _session = null;
    _restored = false;
    _restoring = null;
    ref.onDispose(() => _revision++);
    return const SessionState(SessionStatus.unknown);
  }

  /// Loads the stored session once, at startup.
  Future<void> restore() async {
    if (_restored) return;
    await (_restoring ??= _restore());
  }

  Future<void> _restore() async {
    final revision = _revision;
    try {
      AuthSession? stored;
      try {
        stored = await _storage.readSession();
      } on Object {
        // Unreadable secure storage means signing in again, not a crash.
        stored = null;
      }
      if (!ref.mounted || revision != _revision) return;
      _restored = true;
      if (stored != null && stored.isExpired(DateTime.now())) {
        await clear(expired: true);
        return;
      }
      _publish(stored);
    } finally {
      _restoring = null;
    }
  }

  void _publish(AuthSession? session, {bool expired = false}) {
    _session = session;
    state = SessionState(
      session == null ? SessionStatus.signedOut : SessionStatus.authenticated,
      userId: session?.userId,
      expired: session == null && expired,
    );
  }

  /// Serialises writes so a slow save can never overwrite a newer session.
  Future<void> _persist(int revision, AuthSession? session) {
    final storage = _storage;
    final operation = _writes.then((_) async {
      if (revision != _revision) return;
      if (session == null) {
        await storage.clearSession();
      } else {
        await storage.writeSession(session);
      }
    });
    _writes = operation.then((_) {}, onError: (Object _, StackTrace _) {});
    return operation;
  }

  /// Starts a session after sign-in, signup or a password change. The session
  /// is usable immediately; if secure storage fails it simply will not survive
  /// a restart.
  Future<void> establish(AuthSession session) async {
    final revision = ++_revision;
    _restored = true;
    _publish(session);
    try {
      await _persist(revision, session);
    } on Object {
      // Kept in memory for this run.
    }
  }

  /// Ends the session locally. Always succeeds from the caller's view, so
  /// signing out works offline and with unavailable storage.
  Future<void> clear({bool expired = false}) async {
    final revision = ++_revision;
    _restored = true;
    _publish(null, expired: expired);
    try {
      await _persist(revision, null);
    } on Object {
      // The in-memory session is already gone.
    }
  }

  /// The session to authenticate a request with, or null when signed out.
  Future<AuthSession?> current() async {
    await restore();
    final session = _session;
    if (session == null) return null;
    if (session.isExpired(DateTime.now())) {
      await clear(expired: true);
      return null;
    }
    return session;
  }

  /// The server refused [accessToken]. Ignored when a newer session has
  /// already replaced it, so a late 401 cannot sign out a fresh login.
  Future<void> reject(String accessToken) async {
    if (_session?.accessToken != accessToken) return;
    await clear(expired: true);
  }
}
