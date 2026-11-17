import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paysplit/features/rules/presentation/controllers/rules_controller.dart';

@immutable
class RuleEditorState {
  const RuleEditorState({
    this.type = RuleDestinationType.wallet,
    this.destinationId,
    this.method = AllocationMethod.fixed,
    this.priority = 10,
    this.errors = const {},
    this.busy = false,
  });
  final RuleDestinationType type;
  final String? destinationId;
  final AllocationMethod method;
  final int priority;
  final Map<String, String> errors;
  final bool busy;
  RuleEditorState copyWith({
    RuleDestinationType? type,
    String? destinationId,
    bool clearDestination = false,
    AllocationMethod? method,
    int? priority,
    Map<String, String>? errors,
    bool? busy,
  }) => RuleEditorState(
    type: type ?? this.type,
    destinationId: clearDestination
        ? null
        : destinationId ?? this.destinationId,
    method: method ?? this.method,
    priority: priority ?? this.priority,
    errors: Map.unmodifiable(errors ?? this.errors),
    busy: busy ?? this.busy,
  );
}

class RuleEditorController extends Notifier<RuleEditorState> {
  RuleEditorController({
    this.initial,
    this.destinationId,
    this.type = RuleDestinationType.wallet,
  });
  final SplitRule? initial;
  final String? destinationId;
  final RuleDestinationType type;
  @override
  RuleEditorState build() => RuleEditorState(
    type: initial?.type ?? type,
    destinationId: initial?.destinationId ?? destinationId,
    method: initial?.method ?? AllocationMethod.fixed,
    priority: initial?.priority ?? 10,
  );
  void setType(RuleDestinationType value) {
    if (value != state.type) {
      state = state.copyWith(type: value, clearDestination: true, errors: {});
    }
  }

  void setDestination(String value) => state = state.copyWith(
    destinationId: value,
    errors: {...state.errors}..remove('destination'),
  );
  void setMethod(AllocationMethod value) => state = state.copyWith(
    method: value,
    errors: {...state.errors}..remove('value'),
  );
  void setPriority(int value) => state = state.copyWith(priority: value);
  void clearError(String key) =>
      state = state.copyWith(errors: {...state.errors}..remove(key));

  /// Validates the form and saves the rule: "Activate Split Rule".
  /// Server answers land on the field they are about; `kyc` is set when
  /// identity verification is required first.
  Future<SplitRule?> submit({
    required String name,
    required String value,
  }) async {
    if (state.busy) return null;
    final rules = ref.read(rulesControllerProvider.notifier);
    final (:input, :errors) = rules.check(
      name: name,
      type: state.type,
      destinationId: state.destinationId,
      method: state.method,
      value: value,
      priority: state.priority,
      id: initial?.id,
    );
    if (input == null) {
      state = state.copyWith(errors: errors);
      return null;
    }
    state = state.copyWith(busy: true, errors: const {});
    try {
      final rule = await rules.save(input, id: initial?.id);
      if (ref.mounted) state = state.copyWith(busy: false);
      return rule;
    } on Object catch (error) {
      if (!ref.mounted) return null;
      state = state.copyWith(
        busy: false,
        errors: RulesController.placeError(error),
      );
      return null;
    }
  }
}

final ruleEditorControllerProvider =
    NotifierProvider.autoDispose<RuleEditorController, RuleEditorState>(
      RuleEditorController.new,
    );
