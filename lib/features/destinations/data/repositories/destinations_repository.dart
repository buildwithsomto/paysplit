import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paysplit/core/network/json.dart';
import 'package:paysplit/core/session/session_providers.dart';
import 'package:paysplit/features/destinations/data/data_sources/destinations_data_source.dart';
import 'package:paysplit/features/destinations/data/models/beneficiary.dart';
import 'package:paysplit/features/destinations/data/models/destination_category.dart';
import 'package:paysplit/features/destinations/data/models/destination_transaction.dart';
import 'package:paysplit/features/destinations/data/models/wallet.dart';

class DestinationsRepository {
  const DestinationsRepository(this._source);
  final DestinationsDataSource _source;

  /// The API returns at most 100 beneficiaries per page; the list stops at
  /// [_maxPages] pages.
  static const _pageSize = 100;
  static const _maxPages = 5;

  Future<List<DestinationCategory>> categories() async =>
      jsonList(await _source.categories(), DestinationCategory.fromJson);

  // Wallets

  /// Every wallet; this list is not paginated.
  Future<List<Wallet>> wallets() async =>
      jsonList(await _source.wallets(), Wallet.fromJson);

  Future<List<WalletAccent>> accentColors() async =>
      jsonList(await _source.accentColors(), WalletAccent.fromJson);

  Future<WalletDetail> wallet(String id) async =>
      WalletDetail.fromJson(await _source.wallet(id));

  /// [targetMinor] is the goal in kobo; null means "No targeted amount".
  Future<Wallet> createWallet({
    required String name,
    required String categoryId,
    required String accentColor,
    int? targetMinor,
  }) async => Wallet.fromJson(
    await _source.createWallet({
      'name': name,
      'categoryId': categoryId,
      'accentColor': accentColor,
      'targetAmount': ?targetMinor,
    }),
  );

  /// Replaces every editable field; a null [targetMinor] clears the goal.
  Future<Wallet> updateWallet(
    String id, {
    required String name,
    required String categoryId,
    required String accentColor,
    required int? targetMinor,
  }) async => Wallet.fromJson(
    await _source.updateWallet(id, {
      'name': name,
      'categoryId': categoryId,
      'accentColor': accentColor,
      'targetAmount': targetMinor,
    }),
  );

  /// Fails with `WALLET_NOT_EMPTY` while the wallet holds money. The wallet's
  /// split rule is deleted with it.
  Future<void> deleteWallet(String id) async {
    await _source.deleteWallet(id);
  }

  /// Activity across every wallet. [direction] is `all`, `in` or `out`.
  Future<ApiPage<DestinationTransaction>> walletActivity({
    required int page,
    required int limit,
    String direction = 'all',
    String? search,
  }) async => ApiPage.fromJson(
    await _source.walletActivity({
      'page': page,
      'limit': limit,
      'direction': direction,
      'search': search,
    }),
    DestinationTransaction.fromJson,
  );

  /// One wallet's history. [filter] is `all`, `allocated` or `moved`.
  Future<ApiPage<DestinationTransaction>> walletTransactions(
    String id, {
    required int page,
    required int limit,
    String filter = 'all',
    String? search,
  }) async => ApiPage.fromJson(
    await _source.walletTransactions(id, {
      'page': page,
      'limit': limit,
      'filter': filter,
      'search': search,
    }),
    DestinationTransaction.fromJson,
  );

  /// Moves [amountMinor] kobo from the wallet back to the salary account.
  /// Fails with `INSUFFICIENT_BALANCE` when the wallet holds less.
  /// The answer is not read: callers reload the wallet and the ledger.
  Future<void> moveFromWallet(String id, int amountMinor) async {
    await _source.moveFromWallet(id, amountMinor);
  }

  // Beneficiaries

  /// Nigerian banks sorted by name.
  Future<List<Bank>> banks() async =>
      jsonList(await _source.banks(), Bank.fromJson);

  /// The name of the account holder of [accountNumber] at the bank.
  Future<String> resolveAccount({
    required String bankCode,
    required String accountNumber,
  }) async => Json.from(
    await _source.resolveAccount(bankCode, accountNumber),
  ).string('accountName');

  /// Every beneficiary, read page by page.
  Future<List<Beneficiary>> beneficiaries() async {
    final all = <Beneficiary>[];
    for (var page = 1; page <= _maxPages; page++) {
      final result = ApiPage.fromJson(
        await _source.beneficiaries({'page': page, 'limit': _pageSize}),
        Beneficiary.fromJson,
      );
      all.addAll(result.items);
      if (!result.hasNextPage) break;
    }
    return all;
  }

  /// The account name is resolved by the server and is not sent.
  Future<Beneficiary> createBeneficiary({
    required String bankCode,
    required String accountNumber,
    required String categoryId,
    String? narration,
  }) async => Beneficiary.fromJson(
    await _source.createBeneficiary({
      'bankCode': bankCode,
      'accountNumber': accountNumber,
      'categoryId': categoryId,
      'narration': ?narration,
    }),
  );

  Future<BeneficiaryDetail> beneficiary(String id) async =>
      BeneficiaryDetail.fromJson(await _source.beneficiary(id));

  /// Edits the category and narration; an empty [narration] clears it.
  Future<Beneficiary> updateBeneficiary(
    String id, {
    required String categoryId,
    required String narration,
  }) async => Beneficiary.fromJson(
    await _source.updateBeneficiary(id, {
      'categoryId': categoryId,
      'narration': narration.isEmpty ? null : narration,
    }),
  );

  /// A paused beneficiary is skipped by salary splits.
  Future<Beneficiary> setBeneficiaryStatus(
    String id,
    BeneficiaryStatus status,
  ) async => Beneficiary.fromJson(
    await _source.updateBeneficiary(id, {'status': status.name}),
  );

  /// The beneficiary's split rule is deleted with it.
  Future<void> deleteBeneficiary(String id) async {
    await _source.deleteBeneficiary(id);
  }

  Future<ApiPage<DestinationTransaction>> beneficiaryTransactions(
    String id, {
    required int page,
    required int limit,
    String? search,
  }) async => ApiPage.fromJson(
    await _source.beneficiaryTransactions(id, {
      'page': page,
      'limit': limit,
      'search': search,
    }),
    DestinationTransaction.fromJson,
  );
}

final destinationsRepositoryProvider = Provider<DestinationsRepository>(
  (ref) => DestinationsRepository(ref.watch(destinationsDataSourceProvider)),
);

// A failed reference list stays failed until the user taps Retry, which
// invalidates the provider; nothing is re-requested behind their back.
Duration? _noRetry(int retryCount, Object error) => null;

/// The fixed category list for wallets, beneficiaries and split rules,
/// fetched once and kept for the life of the app.
final categoriesProvider = FutureProvider<List<DestinationCategory>>(
  (ref) => ref.watch(destinationsRepositoryProvider).categories(),
  retry: _noRetry,
);

/// The colours a wallet can use, in the order the API lists them.
final walletAccentsProvider = FutureProvider<List<WalletAccent>>((ref) {
  ref.watch(sessionUserIdProvider);
  return ref.watch(destinationsRepositoryProvider).accentColors();
}, retry: _noRetry);

/// Banks for the beneficiary form. The lookup service can be unavailable
/// (`BANK_LOOKUP_UNAVAILABLE`); the picker offers Retry.
final banksProvider = FutureProvider<List<Bank>>((ref) {
  ref.watch(sessionUserIdProvider);
  return ref.watch(destinationsRepositoryProvider).banks();
}, retry: _noRetry);
