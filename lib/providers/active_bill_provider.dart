import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../models/models.dart';
import 'auth_provider.dart';
import 'orders_provider.dart';
import 'shift_provider.dart';
import 'inactivity_provider.dart';
import 'billing_provider.dart';
import 'table_provider.dart';

/// Tracks the active table being checked out.
final activeTableIdProvider = StateProvider<String?>((ref) => null);

/// Looks up the active order for the selected table.
final activeTableOrderProvider = Provider<Order?>((ref) {
  final tableId = ref.watch(activeTableIdProvider);
  final orders = ref.watch(ordersProvider).valueOrNull ?? [];

  if (orders.isEmpty || tableId == null) return null;

  // Match by tableId directly (most accurate — avoids the old tableNumber lookup)
  for (final o in orders) {
    if (o.tableId == tableId &&
        o.status != OrderStatus.completed &&
        o.status != OrderStatus.cancelled) {
      return o;
    }
  }

  // Fallback: match any active order for this table
  for (final o in orders) {
    if (o.tableId == tableId) {
      return o;
    }
  }

  return null;
});

/// A single payment transaction record on a bill.
class PaymentRecord {
  const PaymentRecord({
    required this.id,
    required this.method,
    required this.amount,
    required this.timestamp,
    required this.waiterName,
    required this.amountMinor,
    this.idempotencyKey,
  });

  final String id;
  final String method; // 'Cash', 'Card', 'Mobile', etc.
  final double amount;
  final DateTime timestamp;
  final String waiterName;
  final int amountMinor;
  final String? idempotencyKey;

  factory PaymentRecord.fromJson(Map<String, dynamic> json) {
    final rawMethod = json['method'] as String? ?? 'cash';
    String displayMethod = 'Cash';
    if (rawMethod.toLowerCase() == 'card') {
      displayMethod = 'Card';
    } else if (rawMethod.toLowerCase() == 'qr_pay') {
      displayMethod = 'UPI';
    } else if (rawMethod.toLowerCase() == 'upi') {
      displayMethod = 'UPI';
    } else {
      displayMethod = rawMethod.isNotEmpty
          ? rawMethod[0].toUpperCase() + rawMethod.substring(1)
          : 'Cash';
    }

    final amountMinor = json['amount_minor'] as int? ?? 0;
    final createdAtStr = json['created_at'] as String? ??
        json['completed_at'] as String? ??
        DateTime.now().toIso8601String();

    return PaymentRecord(
      id: json['id']?.toString() ?? '',
      method: displayMethod,
      amount: amountMinor / 100.0,
      timestamp: DateTime.tryParse(createdAtStr) ?? DateTime.now(),
      waiterName: 'Staff',
      amountMinor: amountMinor,
      idempotencyKey: json['idempotency_key'] as String?,
    );
  }
}

/// Checkout/billing details state.
class ActiveBillState {
  const ActiveBillState({
    required this.order,
    this.discountPercent = 0.0,
    this.serviceChargePercent = 10.0, // 10% default
    this.payments = const [],
    this.isSubmittingPayment = false,
    this.paymentError,
    this.paymentsHydrated = false,
    this.billId,
  });

  final Order order;
  final String? billId;
  final double discountPercent;
  final double serviceChargePercent;
  final List<PaymentRecord> payments;
  final bool isSubmittingPayment;

  /// Non-null when the last payment attempt failed. Cleared on next
  /// successful submission or via [ActiveBillNotifier.clearPaymentError].
  final String? paymentError;
  final bool paymentsHydrated;

  double get subtotal => order.subtotal;

  int get subtotalPaise => order.subtotalMinor > 0 ? order.subtotalMinor : (subtotal * 100).round();
  int get discountPaise => (order.status == OrderStatus.completed && order.discountTotalMinor > 0)
      ? order.discountTotalMinor
      : (subtotalPaise * discountPercent / 100).round();
  int get taxablePaise => subtotalPaise - discountPaise;
  int get taxPaise => (order.status == OrderStatus.completed && order.taxTotalMinor > 0)
      ? order.taxTotalMinor
      : (taxablePaise * order.taxPercent / 100).round();
  int get serviceChargePaise => (order.status == OrderStatus.completed && order.grandTotalMinor > 0)
      ? (order.grandTotalMinor - taxablePaise - taxPaise).clamp(0, order.grandTotalMinor)
      : (taxablePaise * serviceChargePercent / 100).round();
  int get grandTotalPaise => (order.status == OrderStatus.completed && order.grandTotalMinor > 0)
      ? order.grandTotalMinor
      : taxablePaise + taxPaise + serviceChargePaise;

  double get discountAmount => discountPaise / 100.0;
  double get taxableAmount => taxablePaise / 100.0;
  double get taxAmount => taxPaise / 100.0;
  double get serviceChargeAmount => serviceChargePaise / 100.0;
  double get total => grandTotalPaise / 100.0;

  int get amountPaidPaise => (order.status == OrderStatus.completed && payments.isEmpty)
      ? grandTotalPaise
      : payments.fold(0, (sum, p) => sum + p.amountMinor);
  int get amountRemainingPaise => grandTotalPaise - amountPaidPaise;

  double get amountPaid => amountPaidPaise / 100.0;
  double get amountRemaining => amountRemainingPaise / 100.0;

  bool get isPaid => amountRemainingPaise <= 0;
  bool get isPartiallyPaid => amountPaidPaise > 0 && amountRemainingPaise > 0;

  String get settlementStatus {
    if (isPaid) return 'Settled';
    if (isPartiallyPaid) return 'Partially Paid';
    return 'Unpaid';
  }

  String get lastPaymentMethod =>
      payments.isNotEmpty ? payments.last.method : 'Cash';

  ActiveBillState copyWith({
    Order? order,
    double? discountPercent,
    double? serviceChargePercent,
    List<PaymentRecord>? payments,
    bool? isSubmittingPayment,
    String? Function()? paymentError,
    bool? paymentsHydrated,
    String? billId,
  }) =>
      ActiveBillState(
        order: order ?? this.order,
        discountPercent: discountPercent ?? this.discountPercent,
        serviceChargePercent: serviceChargePercent ?? this.serviceChargePercent,
        payments: payments ?? this.payments,
        isSubmittingPayment: isSubmittingPayment ?? this.isSubmittingPayment,
        paymentError: paymentError != null ? paymentError() : this.paymentError,
        paymentsHydrated: paymentsHydrated ?? this.paymentsHydrated,
        billId: billId ?? this.billId,
      );
}

/// Notifier that manages the active checkout bill.
class ActiveBillNotifier extends StateNotifier<ActiveBillState?> {
  ActiveBillNotifier(this._ref) : super(null) {
    // Listen to selected table order to update bill state dynamically
    _ref.listen<Order?>(activeTableOrderProvider, (previous, next) {
      if (next != null) {
        setOrder(next);
      }
    }, fireImmediately: true);
  }

  final Ref _ref;

  void setOrder(Order order) async {
    final currentState = state;
    if (currentState != null && currentState.order.id == order.id) {
      // Keep existing items/totals, but merge in status/update info from tables provider/orders list
      final mergedOrder = currentState.order.copyWith(
        status: order.status,
        versionNum: order.versionNum,
        updatedAt: order.updatedAt,
      );
      state = currentState.copyWith(order: mergedOrder);
      if (currentState.paymentsHydrated) {
        return; // Already fetched and hydrated
      }
    } else {
      state = ActiveBillState(
        order: order,
        payments: const <PaymentRecord>[],
        paymentsHydrated: true,
      );
    }

    // Load full order details and payments from backend
    await _fetchFullOrderAndPayments(order.id, order.tableNumber);
  }

  Future<void> _fetchFullOrderAndPayments(String orderId, int tableNumber) async {
    try {
      final orderDetail = await _ref.read(orderRepositoryProvider).getOrderDetail(orderId);
      final currentOrder = state?.order;

      final items = orderDetail.items.isNotEmpty
          ? orderDetail.items
          : (currentOrder?.items.isNotEmpty == true ? currentOrder!.items : const <OrderItem>[]);

      final subtotalMinor = orderDetail.subtotalMinor > 0
          ? orderDetail.subtotalMinor
          : (currentOrder?.subtotalMinor ?? 0);

      final grandTotalMinor = orderDetail.grandTotalMinor > 0
          ? orderDetail.grandTotalMinor
          : (currentOrder?.grandTotalMinor ?? 0);

      final discountPercent = orderDetail.discountTotalMinor > 0 && subtotalMinor > 0 
          ? (orderDetail.discountTotalMinor / subtotalMinor) * 100 
          : (state?.discountPercent ?? 0.0);
      final taxableMinor = subtotalMinor - orderDetail.discountTotalMinor;
      final taxPercent = orderDetail.taxTotalMinor > 0 && taxableMinor > 0
          ? (orderDetail.taxTotalMinor / taxableMinor) * 100
          : 5.0;
      final scPaise = grandTotalMinor - taxableMinor - orderDetail.taxTotalMinor;
      final scPercent = scPaise > 0 && taxableMinor > 0
          ? (scPaise / taxableMinor) * 100
          : (state?.serviceChargePercent ?? 10.0);

      final fullOrder = Order(
        id: orderDetail.id,
        tableId: orderDetail.tableId.isNotEmpty ? orderDetail.tableId : (currentOrder?.tableId ?? ''),
        tableNumber: tableNumber > 0 ? tableNumber : (currentOrder?.tableNumber ?? 0),
        tableName: currentOrder?.tableName,
        items: items,
        createdAt: orderDetail.createdAt,
        status: orderDetail.status,
        updatedAt: orderDetail.updatedAt,
        servedBy: orderDetail.createdBy ?? currentOrder?.servedBy,
        discountPercent: discountPercent,
        taxPercent: taxPercent,
        notes: orderDetail.orderNotes ?? currentOrder?.notes,
        versionNum: orderDetail.versionNum,
        orderSnapshotId: orderDetail.orderSnapshotId,
        orderNumber: orderDetail.orderNumber.isNotEmpty ? orderDetail.orderNumber : currentOrder?.orderNumber,
        subtotalMinor: subtotalMinor,
        taxTotalMinor: orderDetail.taxTotalMinor,
        discountTotalMinor: orderDetail.discountTotalMinor,
        grandTotalMinor: grandTotalMinor,
      );

      // Verify order ID hasn't changed while request was in-flight
      if (state == null || state!.order.id != orderId) return;

      state = state!.copyWith(
        order: fullOrder,
        discountPercent: discountPercent,
        serviceChargePercent: scPercent,
        billId: orderDetail.billId ?? state!.billId,
      );

      // If authoritative settlements are attached from the bill, hydrate payments directly
      if (orderDetail.settlements != null && orderDetail.settlements!.isNotEmpty) {
        final payments = orderDetail.settlements!.map((s) {
          final smap = s is Map<String, dynamic> ? s : <String, dynamic>{};
          return PaymentRecord(
            id: smap['id']?.toString() ?? '',
            method: smap['payment_method'] ?? 'cash',
            amount: (smap['amount_minor'] as int? ?? 0) / 100.0,
            timestamp: DateTime.tryParse(smap['created_at']?.toString() ?? '') ?? DateTime.now(),
            waiterName: fullOrder.servedBy ?? 'Staff',
            amountMinor: smap['amount_minor'] as int? ?? 0,
          );
        }).toList();

        state = state!.copyWith(
          payments: payments,
          paymentsHydrated: true,
        );
        return;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ActiveBillNotifier] Failed to fetch full order detail: $e');
      }
    }

    // Load payments
    await loadPayments();
  }

  Future<void> loadPayments() async {
    final currentState = state;
    if (currentState == null) return;

    try {
      final billingService = _ref.read(billingServiceProvider);
      final projections = await billingService.fetchTableProjection(currentState.order.tableId);

      if (projections.isNotEmpty) {
        // Find if any bill contains our active order
        final proj = projections.firstWhere(
          (p) => p is Map<String, dynamic> &&
                 p['orders'] is List &&
                 (p['orders'] as List<dynamic>).any((o) => o is Map && o['id'] == currentState.order.id),
          orElse: () => null,
        );

        if (proj != null && proj is Map<String, dynamic>) {
          final bill = proj['bill'];
          final settlements = proj['settlements'] as List<dynamic>? ?? [];

          final payments = settlements.map((s) {
            final smap = s is Map<String, dynamic> ? s : <String, dynamic>{};
            return PaymentRecord(
              id: smap['id']?.toString() ?? '',
              method: smap['payment_method'] ?? 'cash',
              amount: (smap['amount_minor'] as int? ?? 0) / 100.0,
              timestamp: DateTime.tryParse(smap['created_at']?.toString() ?? '') ?? DateTime.now(),
              waiterName: currentState.order.servedBy ?? 'Staff',
              amountMinor: smap['amount_minor'] as int? ?? 0,
            );
          }).toList();

          state = state!.copyWith(
            billId: bill is Map ? (bill['id'] as String?) : null,
            payments: payments,
            paymentsHydrated: true,
          );
          return;
        }
      }

      if (currentState.order.status == OrderStatus.completed) {
        final amountPaise = currentState.grandTotalPaise;
        final completedPayment = PaymentRecord(
          id: 'completed-${currentState.order.id}',
          method: 'Completed Payment',
          amount: amountPaise / 100.0,
          timestamp: currentState.order.updatedAt ?? currentState.order.createdAt,
          waiterName: currentState.order.servedBy ?? 'Staff',
          amountMinor: amountPaise,
        );
        state = state!.copyWith(
          payments: [completedPayment],
          paymentsHydrated: true,
        );
        return;
      }

      state = state!.copyWith(
        payments: const <PaymentRecord>[],
        paymentsHydrated: true,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ActiveBillNotifier] Failed to load payments via projection: $e');
      }
      if (currentState.order.status == OrderStatus.completed) {
        final amountPaise = currentState.grandTotalPaise;
        final completedPayment = PaymentRecord(
          id: 'completed-${currentState.order.id}',
          method: 'Completed Payment',
          amount: amountPaise / 100.0,
          timestamp: currentState.order.updatedAt ?? currentState.order.createdAt,
          waiterName: currentState.order.servedBy ?? 'Staff',
          amountMinor: amountPaise,
        );
        state = state!.copyWith(
          payments: [completedPayment],
          paymentsHydrated: true,
        );
        return;
      }
      state = state!.copyWith(
        payments: const <PaymentRecord>[],
        paymentsHydrated: true,
      );
    }
  }

  void applyDiscount(double percent) {
    if (state != null) {
      state = state!.copyWith(discountPercent: percent);
    }
  }

  /// Logs a manager override action to the shift activity log.
  void auditManagerOverride({
    required double discountPercent,
    required String approvedByPin,
    required String cashierName,
  }) {
    final currentState = state;
    if (currentState == null) return;

    final orderId = currentState.order.orderNumber ?? currentState.order.id;
    final now = DateTime.now();

    final activity = ShiftActivity(
      id: 'override-${now.millisecondsSinceEpoch}',
      type: ShiftTransactionType.xReport,
      timestamp: now,
      amount: 0.0,
      title: 'Manager Override: ${discountPercent.toStringAsFixed(0)}% Discount',
      subtitle: 'Order $orderId — approved by manager PIN '
          '•••• — cashier: $cashierName',
      performedBy: 'Manager',
    );

    _ref.read(shiftProvider.notifier).state =
        _ref.read(shiftProvider.notifier).state.copyWith(
              activities: [
                activity,
                ..._ref.read(shiftProvider.notifier).state.activities,
              ],
            );
  }

  void applyServiceCharge(double percent) {
    if (state != null) {
      state = state!.copyWith(serviceChargePercent: percent);
    }
  }

  Future<void> addPayment(String method, double amount) async {
    final currentState = state;
    if (currentState == null) return;
    if (currentState.isSubmittingPayment) return; // Prevent concurrent double-taps

    final previousState = currentState;

    // Set loading/submitting flag and clear any prior error
    state = currentState.copyWith(
      isSubmittingPayment: true,
      paymentError: () => null,
    );

    final amountMinor = (amount * 100).round();
    if (amountMinor <= 0) {
      state = currentState.copyWith(
        isSubmittingPayment: false,
        paymentError: () => 'Payment amount must be greater than zero.',
      );
      return;
    }

    try {
      final billingService = _ref.read(billingServiceProvider);
      String? targetBillId = currentState.billId;

      // Always synchronize active bill totals (subtotal, tax + service charge, discount) with backend bill
      try {
        final billResult = await billingService.aggregateOrdersIntoBill(
          tableId: currentState.order.tableId,
          orderIds: [currentState.order.id],
          taxTotalMinor: currentState.taxPaise + currentState.serviceChargePaise,
          discountTotalMinor: currentState.discountPaise,
          grandTotalMinor: currentState.grandTotalPaise,
        );
        final returnedId = (billResult['id'] ?? billResult['bill_id'])?.toString();
        if (returnedId != null && returnedId.isNotEmpty) {
          targetBillId = returnedId;
          state = state?.copyWith(billId: targetBillId);
        }
      } catch (aggErr) {
        if (targetBillId == null) {
          // If aggregation fails, check if table already has an active projection/bill
          try {
            final projections = await billingService.fetchTableProjection(currentState.order.tableId);
            for (final proj in projections) {
              if (proj is Map) {
                final bill = proj['bill'];
                if (bill is Map && bill['id'] != null) {
                  targetBillId = bill['id'].toString();
                  state = state?.copyWith(billId: targetBillId);
                  break;
                }
              }
            }
          } catch (_) {}

          if (targetBillId == null && aggErr is DioException) {
            rethrow;
          }
        }
      }

      String mappedMethod = method.toLowerCase();
      // Backend /bills/:id/settle requires 'cash' or 'manual'
      final settleMethod = (mappedMethod == 'cash') ? 'cash' : 'manual';
      
      final paymentId = 'pay-${DateTime.now().millisecondsSinceEpoch}';

      if (targetBillId != null && targetBillId.isNotEmpty) {
        await billingService.settleBill(
          billId: targetBillId,
          paymentMethod: settleMethod,
          amountMinor: amountMinor,
        );
      } else {
        throw Exception('Unable to locate or aggregate an active bill for this table.');
      }

      final newPayment = PaymentRecord(
        id: paymentId,
        method: method,
        amount: amount,
        timestamp: DateTime.now(),
        waiterName: currentState.order.servedBy ?? (_ref.read(authProvider).user?.name ?? 'Staff'),
        amountMinor: amountMinor,
        idempotencyKey: paymentId,
      );
      final updatedPayments = [...currentState.payments, newPayment];
      
      state = currentState.copyWith(
        billId: targetBillId,
        payments: updatedPayments,
        isSubmittingPayment: false,
        paymentError: () => null,
      );

      _ref.read(inactivityServiceProvider).resetTimer();

      // Perform local side effects on success
      if (method == 'Cash') {
        _ref.read(shiftProvider.notifier).addCashSale(
              amount,
              currentState.order.orderNumber ?? currentState.order.id,
            );
      }

      // The table status (FREE/PAYMENT_PENDING) is now strictly driven by backend SSE.
      // 1. If bill is paid, backend automatically marks the guest_session as closed and rebuilds the projection.
      // 2. POS will receive an SSE update and reflect the new state.
      
      final currentRemaining = state?.amountRemainingPaise ?? 0;
      if (currentRemaining <= 0) {
        final tableId = currentState.order.tableId;
        final tableOrders = _ref.read(ordersProvider).valueOrNull?.where((o) => o.tableId == tableId).toList() ?? [];
        for (final o in tableOrders) {
          _ref.read(ordersProvider.notifier).updateStatus(o.id, OrderStatus.completed);
        }
        _ref.read(ordersProvider.notifier).updateStatus(currentState.order.id, OrderStatus.completed);
        if (tableId.isNotEmpty) {
          try {
            await _ref.read(posTablesProvider.notifier).clearTable(tableId);
          } catch (e) {
            debugPrint('[ActiveBill] Auto-vacate table $tableId: $e');
          }
        }
      }
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      if (statusCode == 409) {
        // Treat as success, but skip adding duplicate to local state
        state = previousState.copyWith(
          isSubmittingPayment: false,
          paymentError: () => null,
        );
        return;
      }

      final serverMsg = e.response?.data is Map
          ? (e.response!.data['error'] is Map
              ? (e.response!.data['error']['message'] as String?) ?? ''
              : (e.response!.data['message'] as String?) ?? '')
          : '';

      String userMessage;
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        userMessage = 'Payment timed out. Check connection and retry.';
      } else if (statusCode != null && statusCode >= 400 && statusCode < 500) {
        userMessage = serverMsg.isNotEmpty
            ? 'Payment declined: $serverMsg'
            : 'Payment failed. Please verify details and retry.';
      } else {
        userMessage = 'Payment failed. Check connection and retry.';
      }

      state = previousState.copyWith(
        isSubmittingPayment: false,
        paymentError: () => userMessage,
      );
    } catch (e) {
      state = previousState.copyWith(
        isSubmittingPayment: false,
        paymentError: () => e.toString().contains('Not authenticated')
            ? 'Session expired. Please log in again.'
            : 'Payment failed. Check connection and retry.',
      );
    }
  }

  /// Resets [ActiveBillState.paymentError] to null so the UI banner is
  /// dismissed without triggering a new payment attempt.
  void clearPaymentError() {
    if (state != null) {
      state = state!.copyWith(paymentError: () => null);
    }
  }

  void clear() {
    state = null;
  }
}

/// Provider exposing the active billing/checkout state.
final activeBillProvider = StateNotifierProvider<ActiveBillNotifier, ActiveBillState?>((ref) {
  return ActiveBillNotifier(ref);
});

/// Branch-level receipt metadata (GSTIN/FSSAI can be wired from API later).
class BranchConfig {
  const BranchConfig({
    required this.restaurantName,
    required this.branchName,
    this.gstin,
    this.fssai,
  });

  final String restaurantName;
  final String branchName;
  final String? gstin;
  final String? fssai;

  BranchConfig copyWith({
    String? restaurantName,
    String? branchName,
    String? gstin,
    String? fssai,
  }) =>
      BranchConfig(
        restaurantName: restaurantName ?? this.restaurantName,
        branchName: branchName ?? this.branchName,
        gstin: gstin ?? this.gstin,
        fssai: fssai ?? this.fssai,
      );
}

final branchConfigProvider = Provider<BranchConfig>((ref) {
  final auth = ref.watch(authProvider);
  return BranchConfig(
    restaurantName: auth.branchName ?? 'Orderlli Restaurant',
    branchName: auth.branchName ?? 'Main Branch',
    gstin: auth.gstin,
    fssai: auth.fssai,
  );
});
