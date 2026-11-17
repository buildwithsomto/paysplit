import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paysplit/core/formatting/money.dart';
import 'package:paysplit/core/network/api_exception.dart';
import 'package:paysplit/features/destinations/data/repositories/destinations_repository.dart';
import 'package:paysplit/features/destinations/presentation/controllers/destinations_controller.dart';

@immutable
class WalletEditorState {
  const WalletEditorState({
    this.category,
    this.savedId,
    this.accent,
    this.noTarget = false,
    this.errors = const {},
    this.busy = false,
  });
  final DestinationCategory? category;
  final String? savedId;

  /// The colour the user picked. While null, the first colour the API
  /// offers is shown and saved.
  final WalletAccent? accent;
  final bool noTarget;

  /// Keyed by form field; `form` holds a failure that belongs to no field.
  final Map<String, String> errors;
  final bool busy;

  WalletEditorState copyWith({
    DestinationCategory? category,
    String? savedId,
    WalletAccent? accent,
    bool? noTarget,
    Map<String, String>? errors,
    bool? busy,
  }) => WalletEditorState(
    category: category ?? this.category,
    savedId: savedId ?? this.savedId,
    accent: accent ?? this.accent,
    noTarget: noTarget ?? this.noTarget,
    errors: Map.unmodifiable(errors ?? this.errors),
    busy: busy ?? this.busy,
  );
}

/// Creates or edits one wallet through the API.
class WalletEditorController extends Notifier<WalletEditorState> {
  WalletEditorController({this.initial});
  final Wallet? initial;

  @override
  WalletEditorState build() {
    final initial = this.initial;
    return WalletEditorState(
      category: initial == null
          ? null
          : DestinationCategory(id: initial.categoryId, name: initial.category),
      savedId: initial?.id,
      accent: initial?.accent,
      noTarget: initial != null && initial.targetMinor == null,
    );
  }

  void selectCategory(DestinationCategory value) => state = state.copyWith(
    category: value,
    errors: {...state.errors}..remove('category'),
  );

  void selectAccent(WalletAccent accent) =>
      state = state.copyWith(accent: accent);

  void setNoTarget(bool value) => state = state.copyWith(
    noTarget: value,
    errors: {...state.errors}..remove('target'),
  );

  void clearError(String field) =>
      state = state.copyWith(errors: {...state.errors}..remove(field));

  /// Validates the form, then creates the wallet or updates the saved one.
  Future<Wallet?> save({required String name, required String target}) async {
    if (state.busy) return null;
    final errors = <String, String>{};
    final amount = state.noTarget || target.trim().isEmpty
        ? null
        : Money.parse(target);
    final accents = ref.read(walletAccentsProvider);
    final accent = state.accent ?? accents.value?.firstOrNull;
    final category = state.category;
    if (name.trim().isEmpty) errors['name'] = 'Enter a wallet name.';
    if (name.trim().length > 60) errors['name'] = 'Use at most 60 characters.';
    if (category == null) errors['category'] = 'Select a category.';
    if (!state.noTarget &&
        target.trim().isNotEmpty &&
        (amount == null || amount < 100)) {
      errors['target'] = 'Enter a target of at least ₦1, or leave it empty.';
    }
    if (accent == null) {
      errors['form'] = accents.hasError
          ? 'Colours couldn’t be loaded. Tap Accent Color to try again.'
          : 'Colours are still loading. Try again in a moment.';
    }
    if (errors.isNotEmpty || category == null || accent == null) {
      state = state.copyWith(errors: errors);
      return null;
    }
    state = state.copyWith(busy: true, errors: const {});
    try {
      final wallet = await ref
          .read(destinationsControllerProvider.notifier)
          .saveWallet(
            id: state.savedId,
            name: name.trim(),
            categoryId: category.id,
            accentColor: accent.key,
            targetMinor: amount,
          );
      if (!ref.mounted) return wallet;
      state = state.copyWith(busy: false, savedId: wallet.id, accent: accent);
      return wallet;
    } on Object catch (error) {
      if (!ref.mounted) return null;
      state = state.copyWith(
        busy: false,
        errors: switch (error) {
          ApiException(code: 'WALLET_NAME_TAKEN') => {'name': error.message},
          ApiException(code: 'INVALID_CATEGORY') => {'category': error.message},
          ApiException() when error.fieldError('name') != null => {
            'name': 'Check the wallet name and try again.',
          },
          ApiException() when error.fieldError('targetAmount') != null => {
            'target': 'Enter a valid target amount.',
          },
          _ => {'form': describeError(error)},
        },
      );
      return null;
    }
  }
}

final walletEditorControllerProvider =
    NotifierProvider.autoDispose<WalletEditorController, WalletEditorState>(
      WalletEditorController.new,
    );
