import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order.dart';
import '../models/pos_notification.dart';
import 'orders_provider.dart';

class PosNotificationsNotifier extends StateNotifier<List<PosNotification>> {
  PosNotificationsNotifier(this._ref) : super([]) {
    _initFromOrders();
  }

  final Ref _ref;
  final Set<String> _knownOrderIds = {};

  void _initFromOrders() {
    _ref.listen<AsyncValue<List<Order>>>(ordersProvider, (previous, next) {
      final orders = next.valueOrNull;
      if (orders != null && orders.isNotEmpty) {
        _syncOrdersToNotifications(orders);
      }
    }, fireImmediately: true);
  }

  void _syncOrdersToNotifications(List<Order> orders) {
    if (state.isEmpty && _knownOrderIds.isEmpty) {
      // First load: take up to 8 most recent orders and convert to notifications
      final initialNotifications = <PosNotification>[];
      final sortedOrders = List<Order>.from(orders)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      for (final order in sortedOrders.take(8)) {
        _knownOrderIds.add(order.id);
        initialNotifications.add(_orderToNotification(order, isInitial: true));
      }

      state = initialNotifications;
      return;
    }

    // Subsequent updates: check for any new orders
    final newNotifications = <PosNotification>[];
    for (final order in orders) {
      if (!_knownOrderIds.contains(order.id)) {
        _knownOrderIds.add(order.id);
        newNotifications.add(_orderToNotification(order, isInitial: false));
      }
    }

    if (newNotifications.isNotEmpty) {
      state = [...newNotifications, ...state];
    }
  }

  PosNotification _orderToNotification(Order order, {required bool isInitial}) {
    final orderNum = order.orderNumber ?? (order.id.length >= 8 ? order.id.substring(0, 8) : order.id);
    final totalStr = '₹${order.total.toStringAsFixed(0)}';

    PosNotificationType type;
    String title;
    String message;

    switch (order.status) {
      case OrderStatus.served:
        type = PosNotificationType.tableAlert;
        title = 'Order #$orderNum Served';
        message = 'Table ${order.tableNumber} order served. Dining active ($totalStr)';
        break;
      case OrderStatus.completed:
        type = PosNotificationType.paymentSuccess;
        title = 'Order #$orderNum Completed';
        message = 'Table ${order.tableNumber} bill settled ($totalStr)';
        break;
      case OrderStatus.ready:
        type = PosNotificationType.tableAlert;
        title = 'Order #$orderNum Ready';
        message = 'Kitchen bumped order for Table ${order.tableNumber} ($totalStr)';
        break;
      case OrderStatus.preparing:
        type = PosNotificationType.newOrder;
        title = 'Order #$orderNum in Prep';
        message = 'Table ${order.tableNumber} • ${order.itemCount} item(s)';
        break;
      case OrderStatus.pending:
      default:
        type = PosNotificationType.newOrder;
        title = 'New Order #$orderNum';
        message = 'Table ${order.tableNumber} • ${order.itemCount} item(s) • $totalStr';
        break;
    }

    return PosNotification(
      id: 'notif_${order.id}_${order.status.name}',
      title: title,
      message: message,
      type: type,
      timestamp: order.createdAt,
      isRead: isInitial, // initial batch marked read, live arrivals unread
      orderId: order.id,
      tableNumber: '${order.tableNumber}',
    );
  }

  void addNotification(PosNotification notification) {
    state = [notification, ...state];
  }

  void markAsRead(String id) {
    state = [
      for (final n in state)
        if (n.id == id) n.copyWith(isRead: true) else n,
    ];
  }

  void markAllAsRead() {
    state = [
      for (final n in state) n.copyWith(isRead: true),
    ];
  }

  void dismiss(String id) {
    state = state.where((n) => n.id != id).toList();
  }

  void clearAll() {
    state = [];
  }
}

final posNotificationsProvider =
    StateNotifierProvider<PosNotificationsNotifier, List<PosNotification>>((ref) {
  return PosNotificationsNotifier(ref);
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notifs = ref.watch(posNotificationsProvider);
  return notifs.where((n) => !n.isRead).length;
});
