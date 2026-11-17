import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paysplit/core/network/api_exception.dart';
import 'package:paysplit/core/session/session_providers.dart';
import 'package:paysplit/features/auth/data/repositories/auth_repository.dart';
import 'package:paysplit/features/auth/presentation/controllers/auth_controller.dart';

@immutable
class ChangePasswordState {
  const ChangePasswordState({this.errors = const {}, this.busy = false});

  /// Keyed by `current` and `next`; `form` holds any other failure.
  final Map<String, String> errors;
  final bool busy;
}

/// Settings → Change Password. Passwords pass through and are never kept.
class ChangePasswordController extends Notifier<ChangePasswordState> {
  @override
  ChangePasswordState build() => const ChangePasswordState();

  /// Checks a change before it is sent. The new password follows the same
  /// rule as sign-up.
  static Map<String, String> _validate(String current, String next) => {
    if (current.isEmpty) 'current': 'Enter your current password.',
    if (AuthController.passwordError(next) case final weak?)
      'next': weak
    else if (next == current)
      'next': 'Your new password must be different from the current one.',
  };

  void clearError(String key) {
    if (!state.errors.containsKey(key)) return;
    state = ChangePasswordState(
      errors: Map.unmodifiable({...state.errors}..remove(key)),
      busy: state.busy,
    );
  }

  /// The API signs out every other device and returns a new token, which
  /// replaces this device's session so the user stays signed in here.
  Future<bool> submit(String current, String next) async {
    if (state.busy) return false;
    final errors = _validate(current, next);
    if (errors.isNotEmpty) {
      state = ChangePasswordState(errors: Map.unmodifiable(errors));
      return false;
    }
    state = const ChangePasswordState(busy: true);
    // Leaving the screen mid-request must not lose the replacement session:
    // the old token stops working the moment the change succeeds.
    final alive = ref.keepAlive();
    final sessions = ref.read(sessionControllerProvider.notifier);
    final repository = ref.read(authRepositoryProvider);
    final userId = ref.read(sessionUserIdProvider);
    try {
      if (userId == null) throw ApiException.sessionExpired;
      final session = await repository.changePassword(
        current: current,
        next: next,
        userId: userId,
      );
      await sessions.establish(session);
      if (!ref.mounted) return true;
      state = const ChangePasswordState();
      return true;
    } on Object catch (error) {
      if (!ref.mounted) return false;
      final message = describeError(error);
      state = ChangePasswordState(
        errors: Map.unmodifiable(switch (error) {
          ApiException(code: 'INVALID_CURRENT_PASSWORD') => {
            'current': message,
          },
          ApiException(code: 'PASSWORD_UNCHANGED') => {'next': message},
          // The validation answer is technical; the rule says it plainly.
          ApiException() when error.fieldError('newPassword') != null => {
            'next': AuthController.passwordRule,
          },
          _ => {'form': message},
        }),
      );
      return false;
    } finally {
      alive.close();
    }
  }
}

final changePasswordProvider =
    NotifierProvider.autoDispose<ChangePasswordController, ChangePasswordState>(
      ChangePasswordController.new,
    );
