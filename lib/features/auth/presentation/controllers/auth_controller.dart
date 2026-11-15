import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum VerificationPurpose { signup, recovery }

@immutable
class AuthState {
  const AuthState({
    this.firstName = '',
    this.lastName = '',
    this.email = '',
    this.purpose = VerificationPurpose.signup,
    this.errors = const {},
    this.resendSeconds = 0,
    this.codeExpiresAt,
  });

  final String firstName;
  final String lastName;
  final String email;
  final VerificationPurpose purpose;
  final Map<String, String> errors;
  final int resendSeconds;
  final DateTime? codeExpiresAt;

  AuthState copyWith({
    String? firstName,
    String? lastName,
    String? email,
    VerificationPurpose? purpose,
    Map<String, String>? errors,
    int? resendSeconds,
    DateTime? codeExpiresAt,
  }) => AuthState(
    firstName: firstName ?? this.firstName,
    lastName: lastName ?? this.lastName,
    email: email ?? this.email,
    purpose: purpose ?? this.purpose,
    errors: Map.unmodifiable(errors ?? this.errors),
    resendSeconds: resendSeconds ?? this.resendSeconds,
    codeExpiresAt: codeExpiresAt ?? this.codeExpiresAt,
  );
}

/// Local presentation state only. Passwords and codes are never retained here.
class AuthController extends Notifier<AuthState> {
  Timer? _resendTimer;
  DateTime? _resendAt;
  bool _codeAccepted = false;

  @override
  AuthState build() {
    ref.onDispose(() => _resendTimer?.cancel());
    return const AuthState();
  }

  void clearErrors() => state = state.copyWith(errors: const {});

  void updateDisplayName(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    state = state.copyWith(
      firstName: parts.first,
      lastName: parts.skip(1).join(' '),
    );
  }

  void clearError(String field) {
    if (!state.errors.containsKey(field)) return;
    state = state.copyWith(errors: {...state.errors}..remove(field));
  }

  void reset() {
    _resendTimer?.cancel();
    _resendAt = null;
    _codeAccepted = false;
    state = const AuthState();
  }

  bool validateLogin(String email, String password) {
    final errors = <String, String>{};
    _validateEmail(email, errors);
    if (password.isEmpty) errors['password'] = 'Enter your password.';
    state = state.copyWith(
      email: errors.isEmpty ? email.trim() : null,
      errors: errors,
    );
    return errors.isEmpty;
  }

  bool validateSignup(String firstName, String lastName, String email) {
    final errors = <String, String>{};
    if (firstName.trim().isEmpty) {
      errors['firstName'] = 'Enter your first name.';
    }
    if (lastName.trim().isEmpty) errors['lastName'] = 'Enter your last name.';
    _validateEmail(email, errors);
    state = state.copyWith(
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      email: email.trim(),
      purpose: VerificationPurpose.signup,
      errors: errors,
    );
    return errors.isEmpty;
  }

  bool validateRecovery(String email) {
    final errors = <String, String>{};
    _validateEmail(email, errors);
    state = state.copyWith(
      email: email.trim(),
      purpose: VerificationPurpose.recovery,
      errors: errors,
    );
    return errors.isEmpty;
  }

  bool validatePasswords(String password, String confirmation) {
    final errors = <String, String>{};
    // UI preview policy; reconcile with the backend's policy when supplied.
    if (password.length < 8) {
      errors['password'] = 'Use at least 8 characters.';
    }
    if (confirmation.isEmpty) {
      errors['confirmation'] = 'Confirm your password.';
    } else if (password != confirmation) {
      errors['confirmation'] = 'Passwords do not match.';
    }
    state = state.copyWith(errors: errors);
    return errors.isEmpty;
  }

  void startVerification() {
    _resendTimer?.cancel();
    final now = ref.read(authClockProvider)();
    _resendAt = now.add(const Duration(seconds: 30));
    _codeAccepted = false;
    state = state.copyWith(
      errors: const {},
      resendSeconds: 30,
      codeExpiresAt: now.add(const Duration(minutes: 5)),
    );
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!ref.mounted) {
        timer.cancel();
        return;
      }
      refreshCooldown();
    });
  }

  void refreshCooldown() {
    final deadline = _resendAt;
    final remaining =
        deadline?.difference(ref.read(authClockProvider)()).inMilliseconds ?? 0;
    final seconds = (remaining / 1000).ceil().clamp(0, 30);
    state = state.copyWith(resendSeconds: seconds);
    if (seconds == 0) _resendTimer?.cancel();
  }

  bool resendCode() {
    refreshCooldown();
    if (_codeAccepted || state.resendSeconds > 0) return false;
    startVerification();
    return true;
  }

  bool verify(String code) {
    final expiry = state.codeExpiresAt;
    final error = switch (code) {
      _
          when expiry == null ||
              !ref.read(authClockProvider)().isBefore(expiry) =>
        'This code has expired. Request a new code.',
      _ when _codeAccepted => 'This code has already been used.',
      _ when code.length != 6 => 'Enter the complete six-digit code.',
      _ when code != previewCode => 'Incorrect code. Try again.',
      _ => null,
    };
    state = state.copyWith(errors: {'code': ?error});
    if (error == null) {
      _codeAccepted = true;
      _resendTimer?.cancel();
    }
    return error == null;
  }

  void _validateEmail(String value, Map<String, String> errors) {
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim())) {
      errors['email'] = 'Enter a valid email address.';
    }
  }

  static const previewCode = '141234';
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

final authClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
