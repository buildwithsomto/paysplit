import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paysplit/core/network/api_exception.dart';
import 'package:paysplit/features/destinations/data/repositories/destinations_repository.dart';
import 'package:paysplit/features/destinations/presentation/controllers/destinations_controller.dart';

@immutable
class BeneficiaryEditorState {
  const BeneficiaryEditorState({
    this.bank,
    this.category,
    this.resolvedName,
    this.resolving = false,
    this.savedId,
    this.errors = const {},
    this.busy = false,
  });
  final Bank? bank;
  final DestinationCategory? category;

  /// The account holder the bank returned for the entered number.
  final String? resolvedName;
  final bool resolving;
  final String? savedId;

  /// Keyed by form field; `form` holds a failure that belongs to no field,
  /// and `kyc` is set when the server requires identity verification first.
  final Map<String, String> errors;
  final bool busy;

  bool get editing => savedId != null;

  BeneficiaryEditorState copyWith({
    Bank? bank,
    DestinationCategory? category,
    String? resolvedName,
    bool clearResolved = false,
    bool? resolving,
    String? savedId,
    Map<String, String>? errors,
    bool? busy,
  }) => BeneficiaryEditorState(
    bank: bank ?? this.bank,
    category: category ?? this.category,
    resolvedName: clearResolved ? null : resolvedName ?? this.resolvedName,
    resolving: resolving ?? this.resolving,
    savedId: savedId ?? this.savedId,
    errors: Map.unmodifiable(errors ?? this.errors),
    busy: busy ?? this.busy,
  );
}

/// Adds a recipient bank account, or edits an existing one's category and
/// narration. The account name always comes from the bank, never the user.
class BeneficiaryEditorController extends Notifier<BeneficiaryEditorState> {
  BeneficiaryEditorController({this.initial});
  final Beneficiary? initial;

  /// Discards lookups for a number or bank the user has since changed.
  int _lookup = 0;

  @override
  BeneficiaryEditorState build() {
    final initial = this.initial;
    if (initial == null) return const BeneficiaryEditorState();
    return BeneficiaryEditorState(
      category: DestinationCategory(
        id: initial.categoryId,
        name: initial.category,
      ),
      savedId: initial.id,
    );
  }

  void selectBank(Bank bank, {required String accountNumber}) {
    state = state.copyWith(
      bank: bank,
      clearResolved: true,
      errors: {...state.errors}
        ..remove('bank')
        ..remove('account'),
    );
    resolve(accountNumber);
  }

  void selectCategory(DestinationCategory value) => state = state.copyWith(
    category: value,
    errors: {...state.errors}..remove('category'),
  );

  void clearError(String field) =>
      state = state.copyWith(errors: {...state.errors}..remove(field));

  /// Called as the account number changes; looks the holder up once a bank
  /// is chosen and all ten digits are in.
  Future<void> resolve(String accountNumber) async {
    final lookup = ++_lookup;
    final bank = state.bank;
    final number = accountNumber.trim();
    if (state.editing) return;
    if (bank == null || !RegExp(r'^\d{10}$').hasMatch(number)) {
      state = state.copyWith(
        clearResolved: true,
        resolving: false,
        errors: {...state.errors}..remove('account'),
      );
      return;
    }
    state = state.copyWith(
      clearResolved: true,
      resolving: true,
      errors: {...state.errors}..remove('account'),
    );
    try {
      final name = await ref
          .read(destinationsRepositoryProvider)
          .resolveAccount(bankCode: bank.code, accountNumber: number);
      if (!ref.mounted || lookup != _lookup) return;
      state = state.copyWith(resolvedName: name, resolving: false);
    } on Object catch (error) {
      if (!ref.mounted || lookup != _lookup) return;
      state = state.copyWith(
        resolving: false,
        errors: {
          ...state.errors,
          ..._placed(error, fallback: 'account'),
        },
      );
    }
  }

  /// Puts a server answer on the field it is about.
  Map<String, String> _placed(Object error, {String fallback = 'form'}) {
    final message = describeError(error);
    if (error is! ApiException) return {fallback: message};
    return switch (error.code) {
      'KYC_REQUIRED' => {'kyc': message},
      'ACCOUNT_NOT_FOUND' || 'BENEFICIARY_EXISTS' => {'account': message},
      'UNKNOWN_BANK' => {'bank': message},
      'INVALID_CATEGORY' => {'category': message},
      _ when error.fieldError('narration') != null => {
        'narration': 'Use at most 100 characters.',
      },
      _ when error.fieldError('accountNumber') != null => {
        'account': 'Enter the 10-digit account number.',
      },
      _ => {fallback: message},
    };
  }

  /// Validates the form, then adds the beneficiary or, when one is already
  /// saved, updates its category and narration.
  Future<Beneficiary?> save({
    required String accountNumber,
    required String narration,
  }) async {
    if (state.busy) return null;
    final errors = <String, String>{};
    final number = accountNumber.trim();
    final note = narration.trim();
    final savedId = state.savedId;
    final bank = state.bank;
    final category = state.category;
    if (savedId == null) {
      if (bank == null) errors['bank'] = 'Select the bank.';
      if (!RegExp(r'^\d{10}$').hasMatch(number)) {
        errors['account'] = 'Enter the 10-digit account number.';
      } else if (bank != null &&
          state.resolvedName == null &&
          !state.resolving) {
        // The lookup failed: its reason stays on the field.
        if (state.errors['account'] case final reason?) {
          errors['account'] = reason;
        }
      }
    }
    if (category == null) errors['category'] = 'Select a category.';
    if (note.length > 100) errors['narration'] = 'Use at most 100 characters.';
    if (errors.isNotEmpty || category == null) {
      state = state.copyWith(errors: errors);
      return null;
    }
    final destinations = ref.read(destinationsControllerProvider.notifier);
    final Future<Beneficiary> Function() send;
    if (savedId != null) {
      send = () => destinations.updateBeneficiary(
        savedId,
        categoryId: category.id,
        narration: note,
      );
    } else if (bank != null) {
      send = () => destinations.createBeneficiary(
        bankCode: bank.code,
        accountNumber: number,
        categoryId: category.id,
        narration: note.isEmpty ? null : note,
      );
    } else {
      // A new beneficiary without a bank was turned away above.
      return null;
    }
    state = state.copyWith(busy: true, errors: const {});
    try {
      final beneficiary = await send();
      if (!ref.mounted) return beneficiary;
      state = state.copyWith(busy: false, savedId: beneficiary.id);
      return beneficiary;
    } on Object catch (error) {
      if (!ref.mounted) return null;
      state = state.copyWith(busy: false, errors: _placed(error));
      return null;
    }
  }
}

final beneficiaryEditorControllerProvider =
    NotifierProvider.autoDispose<
      BeneficiaryEditorController,
      BeneficiaryEditorState
    >(BeneficiaryEditorController.new);
