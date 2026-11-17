import 'package:paysplit/core/network/api_exception.dart';

/// Strict readers for API payloads, shared by every feature's models.
///
/// A missing or mistyped required field throws [ApiException.invalidResponse]
/// rather than a cast error, so a contract change surfaces as a normal failure.
extension type const Json(Map<String, dynamic> _map) {
  factory Json.from(Object? value) {
    if (value is! Map<String, dynamic>) throw ApiException.invalidResponse;
    return Json(value);
  }

  static Json? fromOrNull(Object? value) =>
      value is Map<String, dynamic> ? Json(value) : null;

  bool has(String key) => _map[key] != null;

  /// The field names, for objects keyed by a name the API chooses.
  Iterable<String> get keys => _map.keys;

  String string(String key) {
    final value = _map[key];
    if (value is! String || value.isEmpty) throw ApiException.invalidResponse;
    return value;
  }

  String? stringOrNull(String key) {
    final value = _map[key];
    return value is String && value.isNotEmpty ? value : null;
  }

  /// Whole numbers, including money in kobo. Rejects fractional values.
  int integer(String key) => integerOrNull(key) ?? _fail();

  int? integerOrNull(String key) {
    final value = _map[key];
    if (value is int) return value;
    if (value is double && value == value.roundToDouble()) return value.toInt();
    return null;
  }

  /// Percentages and other values that may carry decimals.
  double number(String key) => numberOrNull(key) ?? _fail();

  double? numberOrNull(String key) {
    final value = _map[key];
    return value is num ? value.toDouble() : null;
  }

  bool boolean(String key) {
    final value = _map[key];
    if (value is! bool) throw ApiException.invalidResponse;
    return value;
  }

  bool flag(String key) => _map[key] == true;

  /// Instants are returned in UTC and shown in the device's local time.
  DateTime date(String key) => dateOrNull(key) ?? _fail();

  DateTime? dateOrNull(String key) {
    final value = _map[key];
    return value is String ? DateTime.tryParse(value)?.toLocal() : null;
  }

  /// Calendar days such as `2026-11-28`, kept free of time zones.
  DateTime? dayOrNull(String key) {
    final value = _map[key];
    if (value is! String) return null;
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(value);
    if (match == null) return null;
    return DateTime(
      int.parse(match[1]!),
      int.parse(match[2]!),
      int.parse(match[3]!),
    );
  }

  Json object(String key) => Json.from(_map[key]);

  Json? objectOrNull(String key) => fromOrNull(_map[key]);

  List<T> list<T>(String key, T Function(Object?) parse) =>
      jsonList(_map[key], parse);

  List<T> listOrEmpty<T>(String key, T Function(Object?) parse) =>
      _map[key] is List ? jsonList(_map[key], parse) : const [];

  Never _fail() => throw ApiException.invalidResponse;
}

List<T> jsonList<T>(Object? value, T Function(Object?) parse) {
  if (value is! List) throw ApiException.invalidResponse;
  return List.unmodifiable(value.map(parse));
}

/// The API's list envelope: `{data: [...], pagination: {total, page, limit, pages}}`.
class ApiPage<T> {
  ApiPage({
    required List<T> items,
    required this.page,
    required this.limit,
    required this.total,
    required this.pages,
  }) : items = List.unmodifiable(items);

  factory ApiPage.fromJson(Object? value, T Function(Object?) parseItem) {
    final json = Json.from(value);
    final pagination = json.object('pagination');
    final page = pagination.integer('page');
    final limit = pagination.integer('limit');
    final total = pagination.integer('total');
    if (page < 1 || limit < 1 || total < 0) throw ApiException.invalidResponse;
    return ApiPage(
      items: json.list('data', parseItem),
      page: page,
      limit: limit,
      total: total,
      pages: pagination.integer('pages'),
    );
  }

  final List<T> items;
  final int page, limit, total, pages;
  bool get hasNextPage => page < pages;
}
