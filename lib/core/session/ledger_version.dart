import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Counts the movements of money made in this session.
///
/// A split, a wallet move or a salary credit changes balances, rule totals,
/// history and notifications at once. The controllers behind those screens
/// listen to this and reload, so none of them is left showing stale figures.
class LedgerVersion extends Notifier<int> {
  @override
  int build() => 0;

  /// Call after money has moved, or may have (an unconfirmed request).
  void moved() => state++;
}

final ledgerVersionProvider = NotifierProvider<LedgerVersion, int>(
  LedgerVersion.new,
);
