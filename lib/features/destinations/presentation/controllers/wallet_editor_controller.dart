import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paysplit/core/formatting/money.dart';
import 'package:paysplit/features/destinations/presentation/controllers/destinations_controller.dart';

@immutable
class WalletEditorState {
  const WalletEditorState({
    this.category,
    this.savedId,
    this.accent = WalletAccent.green,
    this.noTarget = false,
    this.errors = const {},
  });
  final String? category;
  final String? savedId;
  final WalletAccent accent;
  final bool noTarget;
  final Map<String, String> errors;
  WalletEditorState copyWith({
    String? category,
    String? savedId,
    WalletAccent? accent,
    bool? noTarget,
    Map<String, String>? errors,
  }) => WalletEditorState(
    category: category ?? this.category,
    savedId: savedId ?? this.savedId,
    accent: accent ?? this.accent,
    noTarget: noTarget ?? this.noTarget,
    errors: Map.unmodifiable(errors ?? this.errors),
  );
}

class WalletEditorController extends Notifier<WalletEditorState> {
  WalletEditorController({this.initial});
  final WalletViewData? initial;
  @override
  WalletEditorState build() => WalletEditorState(
    category: initial?.category,
    savedId: initial?.id,
    accent: initial?.accent ?? WalletAccent.green,
    noTarget: initial != null && initial!.targetMinor == null,
  );
  void selectCategory(String value) {
    if (walletCategories.contains(value)) {
      state = state.copyWith(
        category: value,
        errors: {...state.errors}..remove('category'),
      );
    }
  }

  void selectAccent(WalletAccent accent) =>
      state = state.copyWith(accent: accent);
  void setNoTarget(bool value) => state = state.copyWith(
    noTarget: value,
    errors: {...state.errors}..remove('target'),
  );
  void clearError(String field) =>
      state = state.copyWith(errors: {...state.errors}..remove(field));

  WalletViewData? save({required String name, required String target}) {
    final errors = <String, String>{};
    final amount = state.noTarget || target.trim().isEmpty
        ? null
        : Money.parse(target);
    if (name.trim().isEmpty) errors['name'] = 'Enter a wallet name.';
    if (name.trim().length > 60) errors['name'] = 'Use at most 60 characters.';
    if (state.category == null) errors['category'] = 'Select a category.';
    if (!state.noTarget &&
        target.trim().isNotEmpty &&
        (amount == null || amount <= 0)) {
      errors['target'] = 'Enter a target greater than zero, or leave it empty.';
    }
    state = state.copyWith(errors: errors);
    if (errors.isNotEmpty) return null;
    final wallet = ref
        .read(destinationsControllerProvider.notifier)
        .saveWallet(
          id: state.savedId,
          name: name,
          category: state.category!,
          accent: state.accent,
          targetMinor: amount,
        );
    state = state.copyWith(savedId: wallet.id);
    return wallet;
  }
}

final walletEditorControllerProvider =
    NotifierProvider.autoDispose<WalletEditorController, WalletEditorState>(
      WalletEditorController.new,
    );
