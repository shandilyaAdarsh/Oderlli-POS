import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../mock/restro_mock_data.dart';
import 'customer_provider.dart';

// ─── Tables State ────────────────────────────────────────────────────────────

class RestroTablesNotifier extends StateNotifier<List<RestroTableItem>> {
  RestroTablesNotifier() : super(List.of(RestroMockData.initialTables));

  void bookTable({
    required String tableNo,
    required String customerName,
    required String customerPhone,
    required double total,
  }) {
    final initials = customerName.trim().isEmpty
        ? 'N/A'
        : customerName
            .trim()
            .split(' ')
            .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
            .take(2)
            .join();

    state = [
      for (final table in state)
        if (table.name == tableNo)
          table.copyWith(
            status: 'Booked',
            initial: initials,
            customerName: customerName,
            customerPhone: customerPhone,
            currentBillTotal: total,
          )
        else
          table,
    ];
  }

  void freeTable(String tableNo) {
    state = [
      for (final table in state)
        if (table.name == tableNo)
          table.copyWith(
            status: 'Available',
            initial: '',
            customerName: null,
            customerPhone: null,
            currentBillTotal: null,
          )
        else
          table,
    ];
  }

  void addTable({required String tableNo, required int seats}) {
    final newId = 't-${state.length + 1}';
    state = [
      ...state,
      RestroTableItem(
        id: newId,
        name: tableNo,
        status: 'Available',
        initial: '',
        seats: seats,
      ),
    ];
  }
}

final restroTablesProvider =
    StateNotifierProvider<RestroTablesNotifier, List<RestroTableItem>>((ref) {
  return RestroTablesNotifier();
});

// ─── Orders State ────────────────────────────────────────────────────────────

class RestroOrdersNotifier extends StateNotifier<List<RestroOrder>> {
  RestroOrdersNotifier() : super(List.of(RestroMockData.initialOrders));

  void addOrder({
    required String customer,
    required String tableNo,
    required double total,
    required List<String> itemNames,
  }) {
    final order = RestroOrder(
      id: '${DateTime.now().millisecondsSinceEpoch}',
      customer: customer.isEmpty ? 'Walk-in Guest' : customer,
      status: 'In Progress',
      dateTime: DateTime.now(),
      itemCount: itemNames.length,
      tableNo: tableNo,
      total: total,
      itemNames: itemNames,
    );
    state = [order, ...state];
  }

  void updateOrderStatus(String orderId, String newStatus) {
    state = [
      for (final order in state)
        if (order.id == orderId)
          order.copyWith(status: newStatus)
        else
          order,
    ];
  }
}

final restroOrdersProvider =
    StateNotifierProvider<RestroOrdersNotifier, List<RestroOrder>>((ref) {
  return RestroOrdersNotifier();
});

// ─── Cart State ──────────────────────────────────────────────────────────────

class RestroCartLineItem {
  final RestroMenuItem item;
  final int quantity;

  const RestroCartLineItem({
    required this.item,
    required this.quantity,
  });

  double get totalPrice => item.price * quantity;

  RestroCartLineItem copyWith({
    RestroMenuItem? item,
    int? quantity,
  }) {
    return RestroCartLineItem(
      item: item ?? this.item,
      quantity: quantity ?? this.quantity,
    );
  }
}

class RestroCartNotifier extends StateNotifier<List<RestroCartLineItem>> {
  RestroCartNotifier() : super([]);

  void addItem(RestroMenuItem item) {
    final existingIndex = state.indexWhere((line) => line.item.id == item.id);
    if (existingIndex >= 0) {
      final current = state[existingIndex];
      state = [
        ...state.sublist(0, existingIndex),
        current.copyWith(quantity: current.quantity + 1),
        ...state.sublist(existingIndex + 1),
      ];
    } else {
      state = [...state, RestroCartLineItem(item: item, quantity: 1)];
    }
  }

  void increment(int itemId) {
    final existingIndex = state.indexWhere((line) => line.item.id == itemId);
    if (existingIndex >= 0) {
      final current = state[existingIndex];
      state = [
        ...state.sublist(0, existingIndex),
        current.copyWith(quantity: current.quantity + 1),
        ...state.sublist(existingIndex + 1),
      ];
    }
  }

  void decrement(int itemId) {
    final existingIndex = state.indexWhere((line) => line.item.id == itemId);
    if (existingIndex >= 0) {
      final current = state[existingIndex];
      if (current.quantity > 1) {
        state = [
          ...state.sublist(0, existingIndex),
          current.copyWith(quantity: current.quantity - 1),
          ...state.sublist(existingIndex + 1),
        ];
      } else {
        removeItem(itemId);
      }
    }
  }

  void removeItem(int itemId) {
    state = state.where((line) => line.item.id != itemId).toList();
  }

  void clear() {
    state = [];
  }
}

final restroCartProvider =
    StateNotifierProvider<RestroCartNotifier, List<RestroCartLineItem>>((ref) {
  return RestroCartNotifier();
});

final restroCartSubtotalProvider = Provider<double>((ref) {
  final cart = ref.watch(restroCartProvider);
  return cart.fold(0.0, (sum, line) => sum + line.totalPrice);
});

final restroCartTaxProvider = Provider<double>((ref) {
  final subtotal = ref.watch(restroCartSubtotalProvider);
  return subtotal * 0.05; // 5% GST (2.5% CGST + 2.5% SGST)
});

final restroCartTotalProvider = Provider<double>((ref) {
  final subtotal = ref.watch(restroCartSubtotalProvider);
  final tax = ref.watch(restroCartTaxProvider);
  return subtotal + tax;
});

// ─── Payment & Global Search Providers ───────────────────────────────────────

final restroPaymentMethodProvider = StateProvider<String>((ref) => 'Cash');
final restroGlobalSearchProvider = StateProvider<String>((ref) => '');
final restroActiveTabProvider = StateProvider<String>((ref) => 'home'); // home, orders, tables, dashboard
