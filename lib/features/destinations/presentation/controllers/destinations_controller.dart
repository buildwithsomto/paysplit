import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paysplit/core/network/api_exception.dart';
import 'package:paysplit/core/presentation/content_phase.dart';
import 'package:paysplit/core/session/ledger_version.dart';
import 'package:paysplit/core/session/session_providers.dart';
import 'package:paysplit/features/auth/presentation/controllers/account_controller.dart';
import 'package:paysplit/features/destinations/data/models/beneficiary.dart';
import 'package:paysplit/features/destinations/data/models/wallet.dart';
import 'package:paysplit/features/destinations/data/repositories/destinations_repository.dart';
import 'package:paysplit/features/home/presentation/controllers/dashboard_controller.dart';

export 'package:paysplit/features/destinations/data/models/beneficiary.dart';
export 'package:paysplit/features/destinations/data/models/destination_category.dart';
export 'package:paysplit/features/destinations/data/models/wallet.dart';

@immutable
class DestinationsState {
  const DestinationsState({
    this.wallets = const [],
    this.beneficiaries = const [],
    this.phase = ContentPhase.loading,
    this.message,
    this.updatedAt,
  });
  final List<Wallet> wallets;
  final List<Beneficiary> beneficiaries;
  final ContentPhase phase;

  /// The API's explanation of the last failed load.
  final String? message;

  /// Null until the first successful load.
  final DateTime? updatedAt;

  bool get hasData => updatedAt != null;

  Wallet? wallet(String id) =>
      wallets.where((item) => item.id == id).firstOrNull;
  Beneficiary? beneficiary(String id) =>
      beneficiaries.where((item) => item.id == id).firstOrNull;

  DestinationsState copyWith({
    List<Wallet>? wallets,
    List<Beneficiary>? beneficiaries,
    ContentPhase? phase,
    String? message,
    bool clearMessage = false,
    DateTime? updatedAt,
  }) => DestinationsState(
    wallets: List.unmodifiable(wallets ?? this.wallets),
    beneficiaries: List.unmodifiable(beneficiaries ?? this.beneficiaries),
    phase: phase ?? this.phase,
    message: clearMessage ? null : message ?? this.message,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

/// The user's wallets and beneficiaries, backed by `/wallets` and
/// `/beneficiaries`. Writes throw [ApiException] so each form can place the
/// server's answer on the right field.
class DestinationsController extends Notifier<DestinationsState> {
  int _generation = 0;
  Future<void>? _loading;

  DestinationsRepository get _repository =>
      ref.read(destinationsRepositoryProvider);

  @override
  DestinationsState build() {
    final userId = ref.watch(sessionUserIdProvider);
    final generation = ++_generation;
    ref.listen(ledgerVersionProvider, (_, _) => load());
    _loading = null;
    ref.onDispose(() => _generation++);
    if (userId == null) {
      return const DestinationsState(phase: ContentPhase.ready);
    }
    Future.microtask(() {
      if (ref.mounted && generation == _generation) load();
    });
    return const DestinationsState();
  }

  /// First load, pull-to-refresh and Retry. Concurrent callers share one run.
  Future<void> load() =>
      _loading ??= _load().whenComplete(() => _loading = null);

  Future<void> _load() async {
    if (ref.read(sessionUserIdProvider) == null) return;
    final generation = _generation;
    state = state.copyWith(
      phase: state.hasData ? ContentPhase.refreshing : ContentPhase.loading,
    );
    try {
      final (wallets, beneficiaries) = await (
        _repository.wallets(),
        _repository.beneficiaries(),
      ).wait;
      if (!ref.mounted || generation != _generation) return;
      state = state.copyWith(
        wallets: wallets,
        beneficiaries: beneficiaries,
        phase: ContentPhase.ready,
        clearMessage: true,
        updatedAt: DateTime.now(),
      );
    } on Object catch (error) {
      if (!ref.mounted || generation != _generation) return;
      final cause = failureCause(error);
      // Keep the last loaded lists on screen; only the phase changes.
      state = state.copyWith(
        phase: ContentPhase.failure(cause),
        message: describeError(cause),
      );
    }
  }

  /// Onboarding progress and dashboard totals depend on these records.
  void _changed() {
    ref.read(accountControllerProvider.notifier).load();
    ref.read(dashboardControllerProvider.notifier).load();
  }

  Future<Wallet> saveWallet({
    String? id,
    required String name,
    required String categoryId,
    required String accentColor,
    int? targetMinor,
  }) async {
    final generation = _generation;
    final wallet = id == null
        ? await _repository.createWallet(
            name: name,
            categoryId: categoryId,
            accentColor: accentColor,
            targetMinor: targetMinor,
          )
        : await _repository.updateWallet(
            id,
            name: name,
            categoryId: categoryId,
            accentColor: accentColor,
            targetMinor: targetMinor,
          );
    if (ref.mounted && generation == _generation) {
      state = state.copyWith(
        wallets: id == null
            ? [...state.wallets, wallet]
            : [
                for (final item in state.wallets)
                  item.id == wallet.id ? wallet : item,
              ],
      );
      _changed();
    }
    return wallet;
  }

  /// Fails with `WALLET_NOT_EMPTY` while the wallet still holds money.
  Future<void> removeWallet(String id) async {
    final generation = _generation;
    await _repository.deleteWallet(id);
    if (!ref.mounted || generation != _generation) return;
    state = state.copyWith(
      wallets: state.wallets.where((item) => item.id != id).toList(),
    );
    _changed();
  }

  /// Moves money from a wallet back to the salary account.
  Future<void> moveFromWallet(String id, int amountMinor) async {
    final generation = _generation;
    await _repository.moveFromWallet(id, amountMinor);
    if (!ref.mounted || generation != _generation) return;
    ref.read(ledgerVersionProvider.notifier).moved();
    await load();
  }

  Future<Beneficiary> createBeneficiary({
    required String bankCode,
    required String accountNumber,
    required String categoryId,
    String? narration,
  }) async {
    final generation = _generation;
    final beneficiary = await _repository.createBeneficiary(
      bankCode: bankCode,
      accountNumber: accountNumber,
      categoryId: categoryId,
      narration: narration,
    );
    if (ref.mounted && generation == _generation) {
      state = state.copyWith(
        beneficiaries: [...state.beneficiaries, beneficiary],
      );
      _changed();
    }
    return beneficiary;
  }

  /// Edits the category and narration; an empty [narration] clears it.
  Future<Beneficiary> updateBeneficiary(
    String id, {
    required String categoryId,
    required String narration,
  }) async {
    final beneficiary = await _repository.updateBeneficiary(
      id,
      categoryId: categoryId,
      narration: narration,
    );
    _replaceBeneficiary(beneficiary);
    // The narration lives on the detail record, which the list does not
    // carry, so the loaded detail is fetched again.
    if (ref.mounted) ref.invalidate(beneficiaryDetailProvider(id));
    return beneficiary;
  }

  /// A paused beneficiary is skipped by splits.
  Future<Beneficiary> setBeneficiaryPaused(String id, bool paused) async {
    final beneficiary = await _repository.setBeneficiaryStatus(
      id,
      paused ? BeneficiaryStatus.paused : BeneficiaryStatus.active,
    );
    _replaceBeneficiary(beneficiary);
    return beneficiary;
  }

  void _replaceBeneficiary(Beneficiary beneficiary) {
    if (!ref.mounted) return;
    state = state.copyWith(
      beneficiaries: [
        for (final item in state.beneficiaries)
          item.id == beneficiary.id ? beneficiary : item,
      ],
    );
  }

  Future<void> removeBeneficiary(String id) async {
    final generation = _generation;
    await _repository.deleteBeneficiary(id);
    if (!ref.mounted || generation != _generation) return;
    state = state.copyWith(
      beneficiaries: state.beneficiaries
          .where((item) => item.id != id)
          .toList(),
    );
    _changed();
  }
}

final destinationsControllerProvider =
    NotifierProvider<DestinationsController, DestinationsState>(
      DestinationsController.new,
    );

/// One wallet with its lifetime totals. Refetched whenever the list reloads,
/// so a move or split is reflected on the detail screen.
final walletDetailProvider = FutureProvider.autoDispose
    .family<WalletDetail, String>((ref, id) {
      ref.watch(destinationsControllerProvider.select((s) => s.updatedAt));
      return ref.watch(destinationsRepositoryProvider).wallet(id);
    });

/// One beneficiary with its account number, narration and lifetime total.
/// Refetched whenever the list reloads.
final beneficiaryDetailProvider = FutureProvider.autoDispose
    .family<BeneficiaryDetail, String>((ref, id) {
      ref.watch(destinationsControllerProvider.select((s) => s.updatedAt));
      return ref.watch(destinationsRepositoryProvider).beneficiary(id);
    });
