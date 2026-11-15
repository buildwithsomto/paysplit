import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
class KycCodeState {
  const KycCodeState({
    required this.expiresAt,
    required this.resendAt,
    this.seconds = 30,
    this.error,
    this.accepted = false,
  });
  final DateTime expiresAt, resendAt;
  final int seconds;
  final String? error;
  final bool accepted;
  KycCodeState copyWith({int? seconds, String? error, bool? accepted}) =>
      KycCodeState(
        expiresAt: expiresAt,
        resendAt: resendAt,
        seconds: seconds ?? this.seconds,
        error: error,
        accepted: accepted ?? this.accepted,
      );
}

/// Local challenge preview. A real provider must own code delivery/verification.
class KycCodeController extends Notifier<KycCodeState> {
  static const previewCode = '141234';
  Timer? _timer;
  @override
  KycCodeState build() {
    ref.onDispose(() => _timer?.cancel());
    _startTimer();
    return _fresh();
  }

  KycCodeState _fresh() {
    final now = ref.read(kycCodeClockProvider)();
    return KycCodeState(
      expiresAt: now.add(const Duration(minutes: 5)),
      resendAt: now.add(const Duration(seconds: 30)),
    );
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final remaining = state.resendAt
          .difference(ref.read(kycCodeClockProvider)())
          .inMilliseconds;
      final seconds = (remaining / 1000).ceil().clamp(0, 30);
      state = state.copyWith(seconds: seconds, error: state.error);
      if (seconds == 0) {
        _timer?.cancel();
      }
    });
  }

  void clearError() => state = state.copyWith();
  bool resend() {
    if (state.accepted ||
        ref.read(kycCodeClockProvider)().isBefore(state.resendAt)) {
      return false;
    }
    state = _fresh();
    _startTimer();
    return true;
  }

  bool verify(String code) {
    if (state.accepted) {
      return false;
    }
    final now = ref.read(kycCodeClockProvider)();
    final error = !now.isBefore(state.expiresAt)
        ? 'This code has expired. Request a new code.'
        : !RegExp(r'^\d{6}$').hasMatch(code)
        ? 'Enter the complete six-digit code.'
        : code != previewCode
        ? 'Incorrect code. Try again.'
        : null;
    state = state.copyWith(error: error, accepted: error == null);
    if (error == null) {
      _timer?.cancel();
    }
    return error == null;
  }
}

final kycCodeProvider =
    NotifierProvider.autoDispose<KycCodeController, KycCodeState>(
      KycCodeController.new,
    );
final kycCodeClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);
