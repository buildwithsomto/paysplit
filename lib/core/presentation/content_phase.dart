import 'package:paysplit/core/network/api_exception.dart';

/// How a screen's data currently stands with the API.
///
/// [offline] and [error] keep whatever was last loaded on screen, so a failed
/// refresh never blanks balances or history.
enum ContentPhase {
  ready,
  loading,
  refreshing,
  offline,
  error;

  bool get isBusy => this == loading || this == refreshing;
  bool get isFailure => this == offline || this == error;

  /// The phase a failed load leaves behind.
  static ContentPhase failure(Object cause) =>
      cause is ApiException && cause.isConnectivity ? offline : error;
}
