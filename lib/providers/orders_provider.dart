import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_config.dart';
import '../models/models.dart';
import 'customer_provider.dart';
import '../core/repositories/order_repository.dart';
import '../core/repositories/cart_repository.dart';
import 'pos_cart_provider.dart';
import 'table_provider.dart';
import 'auth_provider.dart';


// ─── Infrastructure Providers ─────────────────────────────────────────────────

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final service = ref.watch(orderServiceProvider);
  final cartService = ref.watch(cartServiceProvider);
  final conn = ref.watch(connectivityServiceProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  return OrderRepository(service, cartService, conn, secureStorage);
});

// ─── Orders Provider & Notifier ───────────────────────────────────────────────

final ordersProvider =
    AsyncNotifierProvider<OrdersNotifier, List<Order>>(OrdersNotifier.new);

class OrdersNotifier extends AsyncNotifier<List<Order>> {
  OrderRepository get repository => ref.watch(orderRepositoryProvider);

  @override
  FutureOr<List<Order>> build() async {
    return _fetchOrders();
  }

  Future<List<Order>> _fetchOrders() async {
    if (ref.read(authProvider).user == null) return [];
    final sessionIds = ref.read(cartSessionIdsProvider);
    final branchId = sessionIds.branchId;
    if (branchId == null) {
      if (AppConfig.allowMockFallbackInDebug) {
        return [];
      }
      throw Exception('No branchId context configured. Please verify your login session.');
    }

    final summaryList = await repository.getOrders(branchId: branchId);
    final tables = ref.read(posTablesProvider).valueOrNull ?? [];

    return summaryList.map((summary) {
      final tableNum = tables.firstWhere(
        (t) => t.id == summary.tableId,
        orElse: () => TableModel(
          id: summary.tableId,
          tableName: '1',
          capacity: 4,
          status: POSTableStatus.available,
          sectionName: '',
          floorName: '',
        ),
      ).tableName;

      return Order(
        id: summary.id,
        tableId: summary.tableId,
        tableNumber: int.tryParse(tableNum) ?? 0,
        items: summary.items.map((i) => OrderItem(
          id: '',
          menuItemId: '',
          itemNameSnapshot: i.name,
          unitPriceMinor: 0,
          quantity: i.qty,
        )).toList(),
        createdAt: summary.createdAt,
        status: summary.status,
        notes: summary.orderNotes,
        grandTotalMinor: summary.grandTotalMinor,
        customerPaymentIntent: summary.customerPaymentIntent,
      );
    }).toList();
  }

  Future<void> fetchOrders() async {
    state = const AsyncLoading();
    try {
      final orderList = await _fetchOrders();
      state = AsyncData(orderList);
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
      if (kDebugMode) {
        debugPrint('[OrdersNotifier] fetchOrders failed: $e');
      }
    }
  }
// (Methods moved above/replaced)

  Future<Order> checkout({
    required String tenantId,
    required String branchId,
    required String tableId,
    required String cartId,
    required int expectedCartRevision,
    String? orderNotes,
  }) async {
    debugPrint('[DEBUG] orders_provider checkout: tableId=$tableId, cartId=$cartId');
    debugPrint('[DEBUG] checkout tableId=$tableId');

    // 1. Pre-condition Validation
    final cartState = ref.read(posCartProvider);
    if (cartState.items.isEmpty) {
      throw const CartValidationException('Pre-checkout Validation Failed: Cart is empty.');
    }

    final selectedTableId = ref.read(cartSelectedTableProvider);
    debugPrint('[DEBUG] selectedTableId=$selectedTableId');
    if (selectedTableId == null || selectedTableId != tableId) {
      throw const CartValidationException('Pre-checkout Validation Failed: Selected table mismatch.');
    }

    try {
      String finalCartId = cartId;
      int finalCartRevision = expectedCartRevision;

      final counterTable = ref.read(counterTableProvider);
      if (counterTable != null && tableId == counterTable.id) {
        debugPrint('[DEBUG] Detected counter table checkout! Syncing cart to backend...');
        final itemsToSync = cartState.items.map((item) => {
          'menuItem': item.menuItem,
          'quantity': item.qty,
          'notes': item.notes,
          'selectedModifiers': item.selectedModifiers,
        }).toList();

        final backendCart = await ref.read(cartRepositoryProvider).syncCartToBackend(
          tenantId: tenantId,
          branchId: branchId,
          tableId: tableId,
          items: itemsToSync,
        );

        finalCartId = backendCart.id;
        finalCartRevision = backendCart.versionNum;
        debugPrint('[DEBUG] Sync completed. finalCartId=$finalCartId, versionNum=$finalCartRevision');
      }

      final customerDetails = ref.read(customerDetailsProvider);

      debugPrint('[DEBUG] Proceeding to repository checkout with finalCartId=$finalCartId');
      // 2. Perform checkout REST API request via repository
      final newOrder = await repository.checkout(
        tenantId: tenantId,
        branchId: branchId,
        tableId: tableId,
        cartId: finalCartId,
        expectedCartRevision: finalCartRevision,
        orderNotes: orderNotes,
        customerName: customerDetails.name,
        customerPhone: customerDetails.phone,
      );

      // 3. Clear/Refresh active cart
      ref.read(posCartProvider.notifier).clear();

      // 4. Refresh POS tables so floor plan is updated
      ref.read(posTablesProvider.notifier).refreshTables();

      // 5. Re-fetch branch orders list
      await fetchOrders();

      return newOrder;
    } catch (e) {
      rethrow;
    }
  }

  void addOrder(Order order) {
    final oldData = state.valueOrNull ?? [];
    state = AsyncData([...oldData, order]);
  }

  void updateStatus(String orderId, OrderStatus status) {
    final oldData = state.valueOrNull ?? [];
    final idx = oldData.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      final updated = List<Order>.from(oldData);
      updated[idx] = updated[idx].copyWith(status: status, updatedAt: DateTime.now());
      state = AsyncData(updated);
    }
  }

  void addItemToOrder(String orderId, OrderItem item) {
    final oldData = state.valueOrNull ?? [];
    final idx = oldData.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      final updated = List<Order>.from(oldData);
      updated[idx] = updated[idx].copyWith(items: [...updated[idx].items, item]);
      state = AsyncData(updated);
    }
  }

  void removeItemFromOrder(String orderId, String itemId) {
    final oldData = state.valueOrNull ?? [];
    final idx = oldData.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      final updated = List<Order>.from(oldData);
      updated[idx] = updated[idx].copyWith(
        items: updated[idx].items.where((i) => i.id != itemId).toList(),
      );
      state = AsyncData(updated);
    }
  }

  void cancelOrder(String orderId) {
    updateStatus(orderId, OrderStatus.cancelled);
  }
}

// ─── Active & Filtered Orders Providers ──────────────────────────────────────

/// Active orders (not completed / cancelled).
final activeOrdersProvider = Provider<List<Order>>((ref) {
  final list = ref.watch(ordersProvider).valueOrNull ?? [];
  return list.where((o) {
    return o.status != OrderStatus.served &&
        o.status != OrderStatus.completed &&
        o.status != OrderStatus.cancelled;
  }).toList();
});

/// Orders by status.
final ordersByStatusProvider =
    Provider.family<List<Order>, OrderStatus>((ref, status) {
  final list = ref.watch(ordersProvider).valueOrNull ?? [];
  return list.where((o) => o.status == status).toList();
});
