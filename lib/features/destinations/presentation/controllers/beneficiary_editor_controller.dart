import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paysplit/features/destinations/presentation/controllers/destinations_controller.dart';

@immutable
class BeneficiaryEditorState {
  const BeneficiaryEditorState({
    this.category,
    this.savedId,
    this.errors = const {},
  });
  final String? category;
  final String? savedId;
  final Map<String, String> errors;
}

class BeneficiaryEditorController extends Notifier<BeneficiaryEditorState> {
  BeneficiaryEditorController({this.initial});
  final BeneficiaryViewData? initial;
  @override
  BeneficiaryEditorState build() =>
      BeneficiaryEditorState(category: initial?.category, savedId: initial?.id);
  void selectCategory(String value) {
    if (beneficiaryCategories.contains(value)) {
      state = BeneficiaryEditorState(
        category: value,
        savedId: state.savedId,
        errors: Map.unmodifiable({...state.errors}..remove('category')),
      );
    }
  }

  void clearError(String field) => state = BeneficiaryEditorState(
    category: state.category,
    savedId: state.savedId,
    errors: Map.unmodifiable({...state.errors}..remove(field)),
  );

  BeneficiaryViewData? save({
    required String name,
    required String bank,
    required String accountNumber,
    required String narration,
  }) {
    final errors = <String, String>{};
    if (name.trim().isEmpty) errors['name'] = 'Enter the beneficiary name.';
    if (name.trim().length > 100) {
      errors['name'] = 'Use at most 100 characters.';
    }
    if (bank.trim().isEmpty) errors['bank'] = 'Enter the bank name.';
    if (!RegExp(r'^\d{10}$').hasMatch(accountNumber.trim())) {
      errors['account'] = 'Enter the 10-digit account number.';
    }
    if (state.category == null) errors['category'] = 'Select a category.';
    if (narration.trim().length > 140) {
      errors['narration'] = 'Use at most 140 characters.';
    }
    state = BeneficiaryEditorState(
      category: state.category,
      savedId: state.savedId,
      errors: Map.unmodifiable(errors),
    );
    if (errors.isNotEmpty) return null;
    final beneficiary = ref
        .read(destinationsControllerProvider.notifier)
        .saveBeneficiary(
          id: state.savedId,
          name: name,
          bank: bank,
          accountNumber: accountNumber,
          category: state.category!,
          narration: narration,
        );
    state = BeneficiaryEditorState(
      category: state.category,
      savedId: beneficiary.id,
    );
    return beneficiary;
  }
}

final beneficiaryEditorControllerProvider =
    NotifierProvider.autoDispose<
      BeneficiaryEditorController,
      BeneficiaryEditorState
    >(BeneficiaryEditorController.new);
