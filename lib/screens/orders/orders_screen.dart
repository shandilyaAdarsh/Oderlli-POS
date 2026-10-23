import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../theme/theme.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../routes/app_routes.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/extensions/extensions.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  String _statusFilter = 'all'; // 'all' | 'pending' | 'preparing' | 'served'
  String _searchQuery = '';

  Color _statusColor(OrderStatus status) {
    return switch (status) {
      OrderStatus.pending => const Color(0xFFF59E0B),
      OrderStatus.accepted || OrderStatus.preparing => const Color(0xFF3B82F6),
      OrderStatus.ready => const Color(0xFF22C55E),
      OrderStatus.served => const Color(0xFF6366F1),
      OrderStatus.completed => const Color(0xFF10B981),
      OrderStatus.cancelled || OrderStatus.syncConflict => const Color(0xFFEF4444),
    };
  }

  Color _statusBg(OrderStatus status) {
    return _statusColor(status).withValues(alpha: 0.12);
  }

  String _statusLabel(OrderStatus status) {
    return switch (status) {
      OrderStatus.pending => 'Pending',
      OrderStatus.accepted => 'Accepted',
      OrderStatus.preparing => 'Preparing',
      OrderStatus.ready => 'Ready',
      OrderStatus.served => 'Served',
      OrderStatus.completed => 'Completed',
      OrderStatus.cancelled => 'Cancelled',
      OrderStatus.syncConflict => 'Sync Conflict',
    };
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(ordersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1F1F1F),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────────
            Container(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
              decoration: const BoxDecoration(
                color: Color(0xFF1F1F1F),
                border: Border(bottom: BorderSide(color: Color(0xFF383838))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      InkWell(
                        onTap: () => context.go(AppRoutes.dashboard),
                        borderRadius: BorderRadius.circular(10.r),
                        child: Container(
                          padding: EdgeInsets.all(8.r),
                          decoration: BoxDecoration(
                            color: const Color(0xFF262626),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new, color: Color(0xFFF5F5F5), size: 18),
                        ),
                      ),
                      Gap(16.w),
                      Text(
                        'Orders',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFF5F5F5),
                        ),
                      ),
                      Gap(12.w),
                      ordersAsync.when(
                        data: (orders) => Container(
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: const Color(0xFF383838),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            '${orders.length} orders',
                            style: TextStyle(color: const Color(0xFFABABAB), fontSize: 12.sp),
                          ),
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, _) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _buildFilterChip('All', 'all'),
                      Gap(8.w),
                      _buildFilterChip('Pending', 'pending'),
                      Gap(8.w),
                      _buildFilterChip('Preparing', 'preparing'),
                      Gap(8.w),
                      _buildFilterChip('Served', 'served'),
                      Gap(8.w),
                      InkWell(
                        onTap: () => ref.read(ordersProvider.notifier).fetchOrders(),
                        borderRadius: BorderRadius.circular(8.r),
                        child: Container(
                          padding: EdgeInsets.all(8.r),
                          decoration: BoxDecoration(
                            color: const Color(0xFF262626),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: const Icon(Icons.refresh, color: Color(0xFFABABAB), size: 18),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Search bar ────────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                style: const TextStyle(color: Color(0xFFF5F5F5)),
                decoration: InputDecoration(
                  hintText: 'Search by table, order #, or customer...',
                  hintStyle: const TextStyle(color: Color(0xFF888888)),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF888888)),
                  filled: true,
                  fillColor: const Color(0xFF262626),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    borderSide: const BorderSide(color: Color(0xFF383838)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    borderSide: const BorderSide(color: Color(0xFF383838)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                ),
              ),
            ),

            // ── Orders List ───────────────────────────────────────────────
            Expanded(
              child: ordersAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                error: (err, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.wifi_off, size: 48.sp, color: const Color(0xFF888888)),
                      Gap(16.h),
                      Text('Could not load orders', style: TextStyle(color: const Color(0xFFF5F5F5), fontSize: 16.sp)),
                      Gap(8.h),
                      Text(err.toString(), style: const TextStyle(color: Color(0xFFABABAB)), textAlign: TextAlign.center),
                      Gap(16.h),
                      OutlinedButton(
                        onPressed: () => ref.read(ordersProvider.notifier).fetchOrders(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                data: (allOrders) {
                  final filtered = allOrders.where((o) {
                    if (_statusFilter == 'pending' && o.status != OrderStatus.pending) return false;
                    if (_statusFilter == 'preparing' && o.status != OrderStatus.preparing && o.status != OrderStatus.accepted) return false;
                    if (_statusFilter == 'served' && o.status != OrderStatus.served && o.status != OrderStatus.completed) return false;
                    if (_searchQuery.isNotEmpty) {
                      final tableStr = o.tableNumber.toString();
                      final orderNum = o.orderNumber?.toString() ?? '';
                      final customer = o.servedBy?.toLowerCase() ?? '';
                      return tableStr.contains(_searchQuery) ||
                          orderNum.contains(_searchQuery) ||
                          o.id.toLowerCase().contains(_searchQuery) ||
                          customer.contains(_searchQuery);
                    }
                    return true;
                  }).toList()
                    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 48.sp, color: const Color(0xFF888888)),
                          Gap(12.h),
                          Text('No orders found', style: TextStyle(color: const Color(0xFFABABAB), fontSize: 16.sp)),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const Divider(color: Color(0xFF383838), height: 1),
                    itemBuilder: (context, i) => _buildOrderRow(filtered[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _statusFilter == value;
    return InkWell(
      onTap: () => setState(() => _statusFilter = value),
      borderRadius: BorderRadius.circular(10.r),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF383838) : Colors.transparent,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13.sp,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? const Color(0xFFF5F5F5) : const Color(0xFFABABAB),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderRow(Order order) {
    final statusColor = _statusColor(order.status);
    final timeLabel = DateFormat('hh:mm a').format(order.createdAt);
    final dateLabel = order.createdAt.shortDate;
    final total = order.grandTotalMinor > 0
        ? CurrencyFormatter.format(order.grandTotalMinor / 100.0)
        : (order.total > 0 ? CurrencyFormatter.format(order.total) : '—');

    return InkWell(
      onTap: () {
        // Navigate to checkout/billing for this order
        ref.read(activeTableIdProvider.notifier).state = order.tableId;
        context.go(AppRoutes.billing);
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 14.h),
        child: Row(
          children: [
            // Status indicator
            Container(
              width: 4.w,
              height: 52.h,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            Gap(16.w),

            // Order info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Table ${order.tableNumber}',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFF5F5F5),
                        ),
                      ),
                      if (order.orderNumber != null) ...[
                        Gap(8.w),
                        Text(
                          '#${order.orderNumber}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: const Color(0xFF888888),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Gap(4.h),
                  Text(
                    '${order.items.length} item${order.items.length != 1 ? 's' : ''}'
                    '${order.servedBy != null ? ' · ${order.servedBy}' : ''}'
                    ' · $timeLabel, $dateLabel',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: const Color(0xFFABABAB),
                    ),
                  ),
                ],
              ),
            ),

            Gap(16.w),

            // Amount
            Text(
              total,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFF5F5F5),
              ),
            ),

            Gap(12.w),

            // Status badge
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
              decoration: BoxDecoration(
                color: _statusBg(order.status),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Text(
                _statusLabel(order.status),
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
            ),

            Gap(8.w),
            const Icon(Icons.chevron_right, color: Color(0xFF888888), size: 20),
          ],
        ),
      ),
    );
  }
}
