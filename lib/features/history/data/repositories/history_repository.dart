import 'package:paysplit/core/formatting/api_date.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paysplit/core/network/json.dart';
import 'package:paysplit/features/history/data/data_sources/history_data_source.dart';
import 'package:paysplit/features/history/data/models/transaction.dart';

/// The History tabs, each with its `type` filter value.
enum HistoryTab {
  all('all'),
  wallets('wallet'),
  transfers('beneficiary');

  const HistoryTab(this.apiValue);
  final String apiValue;
}

/// Which way money moved, with its `direction` filter value.
enum MoneyDirection {
  all('all'),
  incoming('in'),
  outgoing('out');

  const MoneyDirection(this.apiValue);
  final String apiValue;
}

/// The filters `/transactions` and `/transactions/export` share.
class TransactionQuery {
  const TransactionQuery({
    this.type = HistoryTab.all,
    this.direction = MoneyDirection.all,
    this.status,
    this.search,
    this.from,
    this.to,
  });

  final HistoryTab type;
  final MoneyDirection direction;
  final TransactionStatus? status;
  final String? search;

  /// Inclusive calendar days, in Lagos time on the server.
  final DateTime? from, to;

  Map<String, Object?> toQuery() => {
    'type': type.apiValue,
    'direction': direction.apiValue,
    'status': status?.name,
    'search': search?.trim(),
    'from': from == null ? null : apiDay(from!),
    'to': to == null ? null : apiDay(to!),
  };
}

class HistoryRepository {
  const HistoryRepository(this._source);
  final HistoryDataSource _source;

  Future<ApiPage<Transaction>> transactions(
    TransactionQuery query, {
    required int page,
    int limit = 20,
  }) async => ApiPage.fromJson(
    await _source.transactions({
      ...query.toQuery(),
      'page': page,
      'limit': limit,
    }),
    Transaction.fromJson,
  );

  Future<Transaction> transaction(String id) async =>
      Transaction.fromJson(await _source.transaction(id));

  /// The statement CSV for [query], up to 5,000 rows.
  Future<String> exportCsv(TransactionQuery query) =>
      _source.export(query.toQuery());
}

final historyRepositoryProvider = Provider<HistoryRepository>(
  (ref) => HistoryRepository(ref.watch(historyDataSourceProvider)),
);

/// The five newest transactions, whatever filters the History tab has
/// applied, for the dashboard's recent activity card.
final recentTransactionsProvider =
    FutureProvider.autoDispose<List<Transaction>>((ref) async {
      final page = await ref
          .watch(historyRepositoryProvider)
          .transactions(const TransactionQuery(), page: 1, limit: 5);
      return page.items;
    });
