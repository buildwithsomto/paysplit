import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paysplit/core/presentation/content_phase.dart';
import 'package:paysplit/core/session/session_providers.dart';
import 'package:paysplit/features/auth/data/models/auth_models.dart';
import 'package:paysplit/features/auth/data/repositories/auth_repository.dart';

@immutable
class AccountState {
  const AccountState({
    this.user,
    this.onboarding = const Onboarding(),
    this.phase = ContentPhase.loading,
  });
  final AppUser? user;
  final Onboarding onboarding;
  final ContentPhase phase;

  String get firstName => user?.firstName ?? '';
}

/// The signed-in user and their server-owned onboarding progress.
///
/// Many endpoints return a fresh `onboarding` object; features pass it to
/// [apply] so the dashboard card and setup checklist stay current without a
/// second request.
class AccountController extends Notifier<AccountState> {
  int _generation = 0;

  @override
  AccountState build() {
    final userId = ref.watch(sessionUserIdProvider);
    final generation = ++_generation;
    ref.onDispose(() => _generation++);
    if (userId == null) return const AccountState(phase: ContentPhase.ready);
    Future.microtask(() {
      if (ref.mounted && generation == _generation && state.user == null) {
        load();
      }
    });
    return const AccountState();
  }

  Future<void> load() async {
    final generation = _generation;
    state = AccountState(
      user: state.user,
      onboarding: state.onboarding,
      phase: state.user == null
          ? ContentPhase.loading
          : ContentPhase.refreshing,
    );
    try {
      final account = await ref.read(authRepositoryProvider).me();
      if (!ref.mounted || generation != _generation) return;
      state = AccountState(
        user: account.user,
        onboarding: account.onboarding,
        phase: ContentPhase.ready,
      );
    } on Object catch (error) {
      if (!ref.mounted || generation != _generation) return;
      state = AccountState(
        user: state.user,
        onboarding: state.onboarding,
        phase: ContentPhase.failure(error),
      );
    }
  }

  /// Adopts fresher values returned by another request.
  void apply({AppUser? user, Onboarding? onboarding}) {
    if (ref.read(sessionUserIdProvider) == null) return;
    state = AccountState(
      user: user ?? state.user,
      onboarding: onboarding ?? state.onboarding,
      phase: ContentPhase.ready,
    );
  }
}

final accountControllerProvider =
    NotifierProvider<AccountController, AccountState>(AccountController.new);

final onboardingProvider = Provider<Onboarding>(
  (ref) => ref.watch(accountControllerProvider.select((s) => s.onboarding)),
);
