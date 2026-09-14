class PosConstants {
  static const String counterTableName = 'Counter';

  /// Sentinel UUID for walk-in / counter orders.
  /// Used throughout CartRepository, CartService, OrderRepository, and
  /// PosCartProvider to detect counter-mode flows.
  static const String counterTableId = '00000000-0000-0000-0000-000000000001';

  /// Returns true when [tableId] refers to the walk-in / counter virtual table.
  static bool isCounterTable(String tableId) => tableId == counterTableId;
}
