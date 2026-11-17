import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paysplit/core/network/api_exception.dart';
import 'package:paysplit/core/session/session_providers.dart';
import 'package:paysplit/features/auth/data/models/auth_models.dart';
import 'package:paysplit/features/auth/data/repositories/auth_repository.dart';
import 'package:paysplit/features/auth/presentation/controllers/account_controller.dart';

enum VerificationPurpose { signup, recovery }

/// Where a login sends the user: into the app, or back to the email code
/// when signup was never finished.
enum AuthNext { home, verifyEmail }

@immutable
class AuthState {
  const AuthState({
    this.email = '',
    this.purpose = VerificationPurpose.signup,
    this.errors = const {},
    this.resendSeconds = 0,
    this.busy = false,
  });

  final String email;
  final VerificationPurpose purpose;

  /// Keyed by form field; `form` holds a failure that belongs to no field.
  final Map<String, String> errors;
  final int resendSeconds;
  final bool busy;

  AuthState copyWith({
    String? email,
    VerificationPurpose? purpose,
    Map<String, String>? errors,
    int? resendSeconds,
    bool? busy,
  }) => AuthState(
    email: email ?? this.email,
    purpose: purpose ?? this.purpose,
    errors: Map.unmodifiable(errors ?? this.errors),
    resendSeconds: resendSeconds ?? this.resendSeconds,
    busy: busy ?? this.busy,
  );
}

/// Drives signup, login and password recovery against the API.
/// Passwords and codes pass through but are never kept in state.
class AuthController extends Notifier<AuthState> {
  Timer? _resendTimer;
  DateTime? _resendAt;

  /// Short-lived proof of a verified email; held in memory only.
  String? _setupToken;

  static const passwordRule =
      'Use at least 8 characters with an uppercase letter, a lowercase '
      'letter, a number and a special character.';
  static final _passwordPattern = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&_#^()\-+=]).{8,}$',
  );

  static String? passwordError(String password) =>
      _passwordPattern.hasMatch(password) ? null : passwordRule;

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  @override
  AuthState build() {
    ref.onDispose(() => _resendTimer?.cancel());
    return const AuthState();
  }

  void clearErrors() => state = state.copyWith(errors: const {});

  void clearError(String field) {
    if (!state.errors.containsKey(field)) return;
    state = state.copyWith(errors: {...state.errors}..remove(field));
  }

  /// Drops everything from an unfinished sign-up or password reset.
  void _reset() {
    _resendTimer?.cancel();
    _resendAt = null;
    _setupToken = null;
    state = const AuthState();
  }

  /// Runs one request with the shared busy flag and error handling, and
  /// reports whether it succeeded.
  /// [onError] may claim a failure for a specific field by returning errors.
  Future<bool> _run(
    Future<void> Function() action, {
    Map<String, String>? Function(ApiException error)? onError,
  }) async {
    if (state.busy) return false;
    state = state.copyWith(busy: true, errors: const {});
    try {
      await action();
      if (ref.mounted) state = state.copyWith(busy: false);
      return true;
    } on Object catch (error) {
      if (!ref.mounted) return false;
      final claimed = error is ApiException ? onError?.call(error) : null;
      state = state.copyWith(
        busy: false,
        errors: claimed ?? {'form': describeError(error)},
      );
      return false;
    }
  }

  Future<void> _signedIn(SignedIn result) async {
    await ref
        .read(sessionControllerProvider.notifier)
        .establish(result.session);
    ref
        .read(accountControllerProvider.notifier)
        .apply(
          user: result.account.user,
          onboarding: result.account.onboarding,
        );
  }

  Future<AuthNext?> login(String email, String password) async {
    final errors = <String, String>{};
    _validateEmail(email, errors);
    if (password.isEmpty) errors['password'] = 'Enter your password.';
    if (errors.isNotEmpty) {
      state = state.copyWith(errors: errors);
      return null;
    }
    final address = email.trim();
    state = state.copyWith(email: address);
    var incomplete = false;
    final signedIn = await _run(
      () async => _signedIn(
        await _repository.login(email: address, password: password),
      ),
      onError: (error) {
        if (error.code == 'ACCOUNT_SETUP_INCOMPLETE') {
          incomplete = true;
          return const {};
        }
        return error.statusCode == 401 ? {'password': error.message} : null;
      },
    );
    // Signup was never finished: the API has just emailed a fresh code.
    if (incomplete && ref.mounted) {
      _beginVerification(
        VerificationPurpose.signup,
        const CodeDelivery(Duration(seconds: 60)),
      );
      return AuthNext.verifyEmail;
    }
    return signedIn ? AuthNext.home : null;
  }

  /// Returns true once the verification code has been emailed.
  Future<bool> signup(String firstName, String lastName, String email) async {
    final errors = <String, String>{};
    if (firstName.trim().isEmpty) {
      errors['firstName'] = 'Enter your first name.';
    }
    if (lastName.trim().isEmpty) errors['lastName'] = 'Enter your last name.';
    _validateEmail(email, errors);
    if (errors.isNotEmpty) {
      state = state.copyWith(errors: errors);
      return false;
    }
    final address = email.trim();
    state = state.copyWith(email: address);
    return _run(
      () async {
        final delivery = await _repository.signup(
          firstName: firstName.trim(),
          lastName: lastName.trim(),
          email: address,
        );
        _beginVerification(VerificationPurpose.signup, delivery);
      },
      onError: (error) =>
          error.statusCode == 409 || error.fieldError('email') != null
          ? {
              'email': error.statusCode == 409
                  ? error.message
                  : 'Enter a valid email address.',
            }
          : null,
    );
  }

  /// Returns true once the reset code has been emailed.
  Future<bool> requestReset(String email) async {
    final errors = <String, String>{};
    _validateEmail(email, errors);
    if (errors.isNotEmpty) {
      state = state.copyWith(errors: errors);
      return false;
    }
    final address = email.trim();
    state = state.copyWith(email: address);
    return _run(() async {
      final delivery = await _repository.forgotPassword(address);
      _beginVerification(VerificationPurpose.recovery, delivery);
    });
  }

  /// Checks the emailed code for the current [AuthState.purpose]. A verified
  /// signup code yields the setup token that [createPassword] needs.
  Future<bool> verify(String code) async {
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      state = state.copyWith(
        errors: {'code': 'Enter the complete six-digit code.'},
      );
      return false;
    }
    final recovery = state.purpose == VerificationPurpose.recovery;
    final verified = await _run(
      () async {
        if (recovery) {
          await _repository.verifyResetCode(state.email, code);
        } else {
          _setupToken = (await _repository.verifyEmail(
            state.email,
            code,
          )).setupToken;
        }
      },
      onError: (error) => error.statusCode == 401
          ? {
              'code':
                  'That code is incorrect or has expired. Try again or request a new one.',
            }
          : null,
    );
    if (verified) _resendTimer?.cancel();
    return verified;
  }

  Future<bool> resendCode() async {
    refreshCooldown();
    if (state.resendSeconds > 0 || state.email.isEmpty) return false;
    return _run(() async {
      final delivery = state.purpose == VerificationPurpose.recovery
          ? await _repository.forgotPassword(state.email)
          : await _repository.resendEmailCode(state.email);
      _startCooldown(delivery.resendAvailableIn);
    });
  }

  /// Finishes signup: sets the password with the setup token from [verify]
  /// and signs the user in.
  Future<bool> createPassword(String password, String confirmation) async {
    if (!_validatePassword(password, confirmation)) return false;
    final token = _setupToken;
    if (token == null) {
      // The token lives in memory only, so it is gone after an app restart.
      state = state.copyWith(errors: const {'form': _verificationExpired});
      return false;
    }
    return _run(() async {
      await _signedIn(
        await _repository.setPassword(setupToken: token, password: password),
      );
      _setupToken = null;
    }, onError: (error) => _passwordFailure(error, _verificationExpired));
  }

  /// Sets a new password once the reset code has been verified.
  Future<bool> resetPassword(String password, String confirmation) async {
    if (!_validatePassword(password, confirmation)) return false;
    return _run(
      () => _repository.resetPassword(state.email, password),
      onError: (error) => _passwordFailure(
        error,
        'Your reset code expired. Request a new code to continue.',
      ),
    );
  }

  static const _verificationExpired =
      'Your verification expired. Verify your email again to continue.';

  bool _validatePassword(String password, String confirmation) {
    final errors = <String, String>{};
    final weak = passwordError(password);
    if (weak != null) errors['password'] = weak;
    if (confirmation.isEmpty) {
      errors['confirmation'] = 'Confirm your password.';
    } else if (password != confirmation) {
      errors['confirmation'] = 'Passwords do not match.';
    }
    if (errors.isNotEmpty) state = state.copyWith(errors: errors);
    return errors.isEmpty;
  }

  /// A 401 means the setup token or verified reset code has lapsed;
  /// [expired] says so in the words of the step that failed.
  Map<String, String>? _passwordFailure(ApiException error, String expired) =>
      switch (error) {
        ApiException(kind: ApiFailureKind.validation) => {
          'password': passwordRule,
        },
        ApiException(statusCode: 401) => {'form': expired},
        _ => null,
      };

  /// Ends the session everywhere. Local sign-out succeeds even offline.
  Future<void> logout() async {
    try {
      await _repository.logout();
    } on Object {
      // Revocation is best effort; the device is signed out regardless.
    }
    await ref.read(sessionControllerProvider.notifier).clear();
    if (ref.mounted) _reset();
  }

  void _beginVerification(VerificationPurpose purpose, CodeDelivery delivery) {
    state = state.copyWith(purpose: purpose, errors: const {});
    _startCooldown(delivery.resendAvailableIn);
  }

  void _startCooldown(Duration wait) {
    _resendTimer?.cancel();
    _resendAt = DateTime.now().add(wait);
    state = state.copyWith(resendSeconds: wait.inSeconds);
    if (wait <= Duration.zero) return;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!ref.mounted) {
        timer.cancel();
        return;
      }
      refreshCooldown();
    });
  }

  /// Recomputed from the deadline, so it stays right after backgrounding.
  void refreshCooldown() {
    final deadline = _resendAt;
    final remaining = deadline?.difference(DateTime.now()).inMilliseconds ?? 0;
    final seconds = (remaining / 1000).ceil().clamp(0, 3600);
    if (seconds != state.resendSeconds) {
      state = state.copyWith(resendSeconds: seconds);
    }
    if (seconds == 0) _resendTimer?.cancel();
  }

  void _validateEmail(String value, Map<String, String> errors) {
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim())) {
      errors['email'] = 'Enter a valid email address.';
    }
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
