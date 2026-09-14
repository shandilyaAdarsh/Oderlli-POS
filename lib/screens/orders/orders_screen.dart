import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../theme/theme.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../core/extensions/extensions.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = [
    (label: 'All', status: null),
    (label: 'Pending', status: OrderStatus.pending),
    (label: 'Preparing', status: OrderStatus.preparing),
    (label: 'Ready', status: OrderStatus.ready),
    (label: 'Served', status: OrderStatus.served),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(ordersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ordersAsync.when(
        data: (allOrders) => _buildBody(context, allOrders),
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48.sp, color: AppColors.error),
              Gap(12.h),
              Text('Unable to load orders.', style: AppTextStyles.titleLarge),
              Gap(8.h),
              Text(e.toString(), style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
              Gap(16.h),
              ElevatedButton(
                onPressed: () => ref.read(ordersProvider.notifier).fetchOrders(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, List<Order> allOrders) {
    return Column(
      children: [
        // ── Top bar ─────────────────────────────────────────────────────
        Container(
          color: AppColors.surface,
          child: Column(
            children: [
              SizedBox(
                height: 72.h,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Row(
                    children: [
                      Text('Orders', style: AppTextStyles.headlineMedium),
                      Gap(12.w),
                      _CountBadge(count: allOrders.length),
                    ],
                  ),
                ),
              ),
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: _tabs
                    .map((t) => Tab(
                          child: Row(
                            children: [
                              Text(t.label),
                              if (t.status != null) ...[
                                Gap(6.w),
                                _CountBadge(
                                  count: allOrders
                                      .where((o) => o.status == t.status)
                                      .length,
                                  small: true,
                                ),
                              ],
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
        // ── Tab views ────────────────────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: _tabs.map((t) {
              final filtered = t.status == null
                  ? allOrders
                  : allOrders.where((o) => o.status == t.status).toList();
              return _OrderList(
                orders: filtered,
                emptyMessage: t.status == null 
                    ? 'No orders' 
                    : 'No ${t.label.toLowerCase()} orders',
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ── Order list ────────────────────────────────────────────────────────────────

class _OrderList extends StatelessWidget {
  const _OrderList({required this.orders, required this.emptyMessage});
  final List<Order> orders;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 48.sp, color: AppColors.textDisabled),
            Gap(12.h),
            Text(emptyMessage, style: AppTextStyles.bodyLarge),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.all(24.r),
      itemCount: orders.length,
      separatorBuilder: (_, _) => Gap(12.h),
      itemBuilder: (context, i) => _OrderRow(order: orders[i]),
    );
  }
}

// ── Single order row ──────────────────────────────────────────────────────────

class _OrderRow extends ConsumerWidget {
  const _OrderRow({required this.order});
  final Order order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = _statusColor(order.status);
    final isCompact = context.screenWidth < 850;
    
    final hasPaymentIntent = order.customerPaymentIntent != null;
    final borderColor = hasPaymentIntent ? AppColors.warning : AppColors.border;
    final paymentIntentLabel = order.customerPaymentIntent == 'upi' ? 'UPI PENDING' : 'CASH REQ';

    final counterTable = ref.watch(counterTableProvider);
    final isWalkIn = counterTable?.id == order.tableId;
    final tableTitle = isWalkIn ? 'WALK-IN' : 'TABLE ${order.tableNumber}';

    final itemsSummary = order.items.isEmpty 
      ? '0 items' 
      : '${order.items.length} items · ${order.total.asCurrency}';

    final detailsString = '${order.status.label.toUpperCase()} · ${order.createdAt.minutesAgoLabel}';

    if (isCompact) {
      return Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: hasPaymentIntent ? AppColors.warning.withValues(alpha: 0.05) : AppColors.surface,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: borderColor, width: hasPaymentIntent ? 2 : 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status indicator
            Container(
              width: 4.w,
              height: 64.h,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
            Gap(12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '#${order.orderNumber ?? "..."}',
                        style: AppTextStyles.titleMedium.copyWith(color: AppColors.textSecondary),
                      ),
                      Text(tableTitle, style: AppTextStyles.titleLarge),
                    ],
                  ),
                  Gap(4.h),
                  Text(itemsSummary, style: AppTextStyles.bodySmall),
                  Gap(8.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(detailsString, style: AppTextStyles.bodySmall),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (hasPaymentIntent) ...[
                            _PaymentBadge(label: paymentIntentLabel),
                            Gap(8.w),
                          ],
                          _StatusPill(status: order.status, color: statusColor),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: hasPaymentIntent ? AppColors.warning.withValues(alpha: 0.05) : AppColors.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: borderColor, width: hasPaymentIntent ? 2 : 1),
      ),
      child: Row(
        children: [
          // Status indicator
          Container(
            width: 4.w,
            height: 56.h,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(4.r),
            ),
          ),
          Gap(16.w),
          // Order num + Table
          SizedBox(
            width: 140.w,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#${order.orderNumber ?? "..."}',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
                Gap(4.h),
                Text(tableTitle, style: AppTextStyles.titleLarge),
              ],
            ),
          ),
          Gap(24.w),
          // Items summary
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(itemsSummary, style: AppTextStyles.titleMedium),
                Gap(4.h),
                Text(
                  order.items.map((i) => '${i.quantity}× ${i.itemNameSnapshot}').join(', '),
                  style: AppTextStyles.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Gap(16.w),
          // Time
          SizedBox(
            width: 80.w,
            child: Text(order.createdAt.minutesAgoLabel, style: AppTextStyles.bodySmall),
          ),
          Gap(16.w),
          // Status badge
          if (hasPaymentIntent) ...[
            _PaymentBadge(label: paymentIntentLabel),
            Gap(8.w),
          ],
          _StatusPill(status: order.status, color: statusColor),
        ],
      ),
    );
  }


  Color _statusColor(OrderStatus status) => switch (status) {
        OrderStatus.pending => AppColors.statusPending,
        OrderStatus.accepted => AppColors.statusPreparing,
        OrderStatus.preparing => AppColors.statusPreparing,
        OrderStatus.ready => AppColors.statusReady,
        OrderStatus.served => AppColors.statusServed,
        OrderStatus.completed => AppColors.statusReady,
        OrderStatus.cancelled => AppColors.statusCancelled,
        OrderStatus.syncConflict => AppColors.statusCancelled,
      };
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status, required this.color});
  final OrderStatus status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100.r),
      ),
      child: Text(
        status.label,
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PaymentBadge extends StatelessWidget {
  const _PaymentBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppColors.warning,
        borderRadius: BorderRadius.circular(100.r),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}


class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count, this.small = false});
  final int count;
  final bool small;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: small ? 6.w : 8.w, vertical: small ? 2.h : 3.h),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(100.r),
      ),
      child: Text(
        '$count',
        style: AppTextStyles.badgeText.copyWith(
          fontSize: small ? 9.sp : 11.sp,
        ),
      ),
    );
  }
}
