import 'package:paysplit/core/formatting/api_date.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paysplit/features/home/data/data_sources/dashboard_data_source.dart';
import 'package:paysplit/features/home/data/models/cash_flow.dart';
import 'package:paysplit/features/home/data/models/dashboard_summary.dart';

class DashboardRepository {
  const DashboardRepository(this._source);
  final DashboardDataSource _source;

  Future<DashboardSummary> summary() async =>
      DashboardSummary.fromJson(await _source.summary());

  /// Cash flow from the calendar day [from] up to today.
  Future<CashFlow> cashFlow({required DateTime from}) async =>
      CashFlow.fromJson(await _source.cashFlow(from: apiDay(from)));
}

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DashboardRepository(ref.watch(dashboardDataSourceProvider)),
);
