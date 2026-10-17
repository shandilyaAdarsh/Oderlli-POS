import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../theme/theme.dart';
import '../../mock/restro_mock_data.dart';
import '../../providers/restro_pos_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/restro_header.dart';
import '../../widgets/restro_bottom_nav.dart';
import '../../widgets/restro_invoice_dialog.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  String _statusFilter = 'all'; // 'all' | 'progress' | 'ready' | 'completed'

  void _showOrderReceipt(RestroOrder order) {
    showDialog(
      context: context,
      builder: (ctx) => RestroInvoiceDialog(
        orderId: order.id,
        customerName: order.customer,
        customerPhone: '',
        guests: 2,
        tableNo: order.tableNo,
        items: order.itemNames.map((name) {
          return RestroCartLineItem(
            item: RestroMenuItem(
              id: 999,
              name: name,
              price: order.total / (order.itemCount > 0 ? order.itemCount : 1),
              category: 'Food',
              isVeg: true,
              emoji: '🍽️',
            ),
            quantity: 1,
          );
        }).toList(),
        subtotal: order.total / 1.05,
        tax: order.total - (order.total / 1.05),
        total: order.total,
        paymentMethod: 'Cash',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(restroOrdersProvider);
    final searchQuery = ref.watch(restroGlobalSearchProvider).toLowerCase();

    final filteredOrders = orders.where((o) {
      if (_statusFilter == 'progress' && o.status != 'In Progress') return false;
      if (_statusFilter == 'ready' && o.status != 'Ready') return false;
      if (_statusFilter == 'completed' && o.status != 'Completed') return false;
      if (searchQuery.isNotEmpty) {
        return o.customer.toLowerCase().contains(searchQuery) ||
            o.tableNo.contains(searchQuery) ||
            o.id.contains(searchQuery);
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF1F1F1F),
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Header ──────────────────────────────────────────────────
            const RestroHeader(),

            // ── Subheader: Back Button, Title & Filter Tabs (Orders.jsx) ─────
            Container(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
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
                          child: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Color(0xFFF5F5F5),
                            size: 18,
                          ),
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
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),

                  // Filter Buttons (All, In Progress, Ready, Completed)
                  Row(
                    children: [
                      _buildFilterChip(label: 'All', value: 'all'),
                      Gap(8.w),
                      _buildFilterChip(label: 'In Progress', value: 'progress'),
                      Gap(8.w),
                      _buildFilterChip(label: 'Ready', value: 'ready'),
                      Gap(8.w),
                      _buildFilterChip(label: 'Completed', value: 'completed'),
                    ],
                  ),
                ],
              ),
            ),

            // ── Orders Grid (OrderCard.jsx in grid-cols-3) ───────────────────
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: filteredOrders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 48.sp,
                              color: const Color(0xFF555555),
                            ),
                            Gap(12.h),
                            Text(
                              'No orders available in this view',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14.sp,
                                color: const Color(0xFF888888),
                              ),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: EdgeInsets.only(bottom: 24.h),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 16.w,
                          mainAxisSpacing: 16.h,
                          childAspectRatio: 1.45,
                        ),
                        itemCount: filteredOrders.length,
                        itemBuilder: (context, i) {
                          final order = filteredOrders[i];
                          return _buildOrderCard(order);
                        },
                      ),
              ),
            ),

            // ── Bottom Navigation ───────────────────────────────────────────
            const RestroBottomNav(activePath: AppRoutes.orders),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({required String label, required String value}) {
    final isSelected = _statusFilter == value;
    return InkWell(
      onTap: () => setState(() => _statusFilter = value),
      borderRadius: BorderRadius.circular(10.r),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 8.h),
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

  // ─── Order Card (OrderCard.jsx) ────────────────────────────────────────────

  Widget _buildOrderCard(RestroOrder order) {
    final initials = order.customer
        .trim()
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
        .take(2)
        .join();

    final isReady = order.status == 'Ready';
    final isCompleted = order.status == 'Completed';
    final formattedDateTime = DateFormat('MMMM dd, yyyy  hh:mm a').format(order.dateTime);

    return Container(
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: const Color(0xFF262626),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: isReady
              ? const Color(0xFF2E4A40)
              : (isCompleted ? const Color(0xFF1D2569) : const Color(0xFF383838)),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top Row: Avatar Button + Customer Info + Status Indicators
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Initials Box in Gold #f6b100
              Container(
                width: 48.r,
                height: 48.r,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Center(
                  child: Text(
                    initials.isEmpty ? 'G' : initials,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1F1F1F),
                    ),
                  ),
                ),
              ),

              Gap(14.w),

              // Customer & Table
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.customer,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFF5F5F5),
                        letterSpacing: 0.3,
                      ),
                    ),
                    Gap(2.h),
                    Text(
                      '#${order.id.length > 8 ? order.id.substring(order.id.length - 8) : order.id} / Dine in',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11.sp,
                        color: const Color(0xFFABABAB),
                      ),
                    ),
                    Gap(2.h),
                    Row(
                      children: [
                        Text(
                          'Table',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11.sp,
                            color: const Color(0xFFABABAB),
                          ),
                        ),
                        Gap(4.w),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 12,
                          color: Color(0xFFABABAB),
                        ),
                        Gap(4.w),
                        Text(
                          order.tableNo,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFF5F5F5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Status Badges & Descriptions
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: isReady
                          ? const Color(0xFF2E4A40)
                          : (isCompleted ? const Color(0xFF1D2569) : const Color(0xFF4A452E)),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isReady ? Icons.done_all : Icons.circle,
                          size: 12,
                          color: isReady
                              ? const Color(0xFF22C55E)
                              : (isCompleted ? const Color(0xFF8B5CF6) : AppColors.primary),
                        ),
                        Gap(4.w),
                        Text(
                          order.status,
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: isReady
                                ? const Color(0xFF22C55E)
                                : (isCompleted ? const Color(0xFF8B5CF6) : AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Gap(4.h),
                  Row(
                    children: [
                      Container(
                        width: 6.r,
                        height: 6.r,
                        decoration: BoxDecoration(
                          color: isReady ? const Color(0xFF22C55E) : AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Gap(4.w),
                      Text(
                        isReady
                            ? 'Ready to serve'
                            : (isCompleted ? 'Order closed' : 'Preparing order'),
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10.sp,
                          color: const Color(0xFFABABAB),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          // Date & Time + Item count
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formattedDateTime,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11.sp,
                  color: const Color(0xFFABABAB),
                ),
              ),
              Text(
                '${order.itemCount} Items',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11.sp,
                  color: const Color(0xFFABABAB),
                ),
              ),
            ],
          ),

          const Divider(color: Color(0xFF383838), thickness: 1),

          // Bottom: Total & Quick Action Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.sp,
                      color: const Color(0xFFABABAB),
                    ),
                  ),
                  Text(
                    '₹${order.total.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFF5F5F5),
                    ),
                  ),
                ],
              ),

              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.receipt_long, color: Color(0xFFABABAB), size: 20),
                    tooltip: 'View Receipt',
                    onPressed: () => _showOrderReceipt(order),
                  ),
                  Gap(6.w),
                  if (order.status == 'In Progress')
                    ElevatedButton(
                      onPressed: () {
                        ref
                            .read(restroOrdersProvider.notifier)
                            .updateOrderStatus(order.id, 'Ready');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E4A40),
                        foregroundColor: const Color(0xFF22C55E),
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Mark Ready',
                        style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold),
                      ),
                    )
                  else if (order.status == 'Ready')
                    ElevatedButton(
                      onPressed: () {
                        ref
                            .read(restroOrdersProvider.notifier)
                            .updateOrderStatus(order.id, 'Completed');
                        ref.read(restroTablesProvider.notifier).freeTable(order.tableNo);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Order #${order.id.substring(order.id.length - 6)} completed and settled.'),
                            backgroundColor: const Color(0xFF262626),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: const Color(0xFF1F1F1F),
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Complete & Pay',
                        style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
