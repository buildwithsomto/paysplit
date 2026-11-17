import 'package:flutter/material.dart';
import 'package:paysplit/core/network/api_exception.dart';
import 'package:paysplit/core/network/json.dart';

/// A wallet colour offered by `GET /wallets/accent-colors`.
@immutable
class WalletAccent {
  const WalletAccent({required this.key, required this.color});

  /// `{key, hex}` from the colour list.
  factory WalletAccent.fromJson(Object? value) {
    final json = Json.from(value);
    return WalletAccent.fromApi(json.string('key'), json.string('hex'));
  }

  factory WalletAccent.fromApi(String key, String hex) {
    final match = RegExp(r'^#([0-9a-fA-F]{6})$').firstMatch(hex);
    if (match == null) throw ApiException.invalidResponse;
    return WalletAccent(
      key: key,
      color: Color(0xFF000000 | int.parse(match[1]!, radix: 16)),
    );
  }

  /// The API's colour key, sent back as `accentColor`.
  final String key;
  final Color color;

  String get label =>
      key.isEmpty ? key : '${key[0].toUpperCase()}${key.substring(1)}';

  /// The pale wash behind a wallet card.
  Color get tint =>
      Color.alphaBlend(color.withValues(alpha: .12), Colors.white);

  @override
  bool operator ==(Object other) => other is WalletAccent && other.key == key;

  @override
  int get hashCode => key.hashCode;
}

/// A wallet as returned by the list, create and edit endpoints:
/// `{id, name, category: {id, name, slug}, accentColor, accentHex,
/// targetAmount, balance, progressPercent, createdAt}`.
@immutable
class Wallet {
  const Wallet({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.category,
    required this.categorySlug,
    required this.accent,
    required this.balanceMinor,
    required this.createdAt,
    this.targetMinor,
    this.progressPercent,
  });

  factory Wallet.fromJson(Object? value) {
    final json = Json.from(value);
    final category = json.object('category');
    return Wallet(
      id: json.string('id'),
      name: json.string('name'),
      categoryId: category.string('id'),
      category: category.string('name'),
      categorySlug: category.string('slug'),
      accent: WalletAccent.fromApi(
        json.string('accentColor'),
        json.string('accentHex'),
      ),
      balanceMinor: json.integer('balance'),
      createdAt: json.date('createdAt'),
      targetMinor: json.integerOrNull('targetAmount'),
      progressPercent: json.numberOrNull('progressPercent'),
    );
  }

  final String id, name;

  /// Sent back as `categoryId`; [category] is its display name.
  final String categoryId, category, categorySlug;
  final WalletAccent accent;

  /// Available balance in kobo.
  final int balanceMinor;
  final DateTime createdAt;

  /// Goal in kobo; null means "No targeted amount".
  final int? targetMinor;

  /// Goal progress as the server reports it, 0-100; null without a target.
  final double? progressPercent;

  /// Goal progress between 0 and 1, or null without a target.
  double? get progress {
    final percent = progressPercent;
    return percent == null ? null : (percent / 100).clamp(0.0, 1.0);
  }
}

/// Lifetime totals from `GET /wallets/{id}`.
@immutable
class WalletStats {
  const WalletStats({
    required this.availableBalance,
    required this.totalAllocated,
    required this.totalMovedBack,
  });

  factory WalletStats.fromJson(Object? value) {
    final json = Json.from(value);
    return WalletStats(
      availableBalance: json.integer('availableBalance'),
      totalAllocated: json.integer('totalAllocated'),
      totalMovedBack: json.integer('totalMovedBack'),
    );
  }

  /// All in kobo.
  final int availableBalance, totalAllocated, totalMovedBack;
}

/// `GET /wallets/{id}`: the wallet with its lifetime totals.
@immutable
class WalletDetail {
  const WalletDetail({required this.wallet, required this.stats});

  factory WalletDetail.fromJson(Object? value) => WalletDetail(
    wallet: Wallet.fromJson(value),
    stats: WalletStats.fromJson(Json.from(value).object('stats')),
  );

  final Wallet wallet;
  final WalletStats stats;
}
