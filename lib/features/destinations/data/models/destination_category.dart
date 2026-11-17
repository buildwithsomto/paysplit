import 'package:flutter/foundation.dart';
import 'package:paysplit/core/network/json.dart';

/// One entry of the fixed category list shared by wallets, beneficiaries and
/// split rules. The API expects [id] as `categoryId`.
@immutable
class DestinationCategory {
  const DestinationCategory({required this.id, required this.name});

  factory DestinationCategory.fromJson(Object? value) {
    final json = Json.from(value);
    return DestinationCategory(
      id: json.string('id'),
      name: json.string('name'),
    );
  }

  final String id, name;

  @override
  bool operator ==(Object other) =>
      other is DestinationCategory && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
