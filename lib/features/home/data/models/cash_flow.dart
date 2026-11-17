import 'package:paysplit/core/network/api_exception.dart';
import 'package:paysplit/core/network/json.dart';

/// Money in and out of the salary account over one month or one day, in kobo.
class CashFlowBucket {
  const CashFlowBucket({
    required this.start,
    required this.inflow,
    required this.toWallets,
    required this.toBeneficiaries,
    required this.movedBack,
  });

  factory CashFlowBucket.fromJson(Object? value) {
    final json = Json.from(value);
    return CashFlowBucket(
      start: _start(json.string('period')),
      inflow: json.integer('inflow'),
      toWallets: json.integer('toWallets'),
      toBeneficiaries: json.integer('toBeneficiaries'),
      movedBack: json.integer('movedBack'),
    );
  }

  /// The first day the bucket covers. The API names a bucket `2026-11` for a
  /// month and `2026-11-15` for a day.
  final DateTime start;
  final int inflow, toWallets, toBeneficiaries, movedBack;

  bool get isEmpty =>
      inflow == 0 && toWallets == 0 && toBeneficiaries == 0 && movedBack == 0;

  static DateTime _start(String period) {
    final match = RegExp(r'^(\d{4})-(\d{2})(?:-(\d{2}))?$').firstMatch(period);
    if (match == null) throw ApiException.invalidResponse;
    return DateTime(
      int.parse(match[1]!),
      int.parse(match[2]!),
      match[3] == null ? 1 : int.parse(match[3]!),
    );
  }
}

/// `GET /dashboard/cash-flow`.
class CashFlow {
  const CashFlow({
    required this.daily,
    required this.buckets,
    required this.changePercent,
  });

  factory CashFlow.fromJson(Object? value) {
    final json = Json.from(value);
    return CashFlow(
      daily: json.string('granularity') == 'day',
      buckets: json.list('buckets', CashFlowBucket.fromJson),
      changePercent: json
          .object('monthOverMonth')
          .numberOrNull('changePercent'),
    );
  }

  /// Daily buckets for ranges up to 62 days, monthly otherwise.
  final bool daily;
  final List<CashFlowBucket> buckets;

  /// How this month's income compares with last month's; null when there is
  /// no previous month to compare against.
  final double? changePercent;

  bool get isEmpty => buckets.every((bucket) => bucket.isEmpty);
}
