import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../theme/theme.dart';
import '../../providers/table_provider.dart';
import '../../providers/orders_provider.dart';
import '../../providers/pos_cart_provider.dart';
import '../../models/models.dart';
import '../../routes/app_routes.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/extensions/extensions.dart';

class FloorScreen extends ConsumerStatefulWidget {
  const FloorScreen({super.key});

  @override
  ConsumerState<FloorScreen> createState() => _FloorScreenState();
}

class _FloorScreenState extends ConsumerState<FloorScreen> {
  String _statusFilter = 'all'; // 'all' | 'occupied' | 'available'

  static const List<Color> _avatarColors = [
    Color(0xFFB73E3E),
    Color(0xFF5B45B0),
    Color(0xFF7F167F),
    Color(0xFF735F32),
    Color(0xFF1D2569),
    Color(0xFF285430),
    Color(0xFFB85D19),
    Color(0xFF025CCA),
  ];

  Color _getAvatarColor(String name) {
    if (name.isEmpty) return const Color(0xFF383838);
    final code = name.codeUnitAt(0);
    return _avatarColors[code % _avatarColors.length];
  }

  String _initials(String? name) {
    if (name == null || name.trim().isEmpty) return '';
    final parts = name.trim().split(' ');
    return parts.map((p) => p.isNotEmpty ? p[0].toUpperCase() : '').take(2).join();
  }

  void _handleTableTap(TableModel table) {
    if (table.status == POSTableStatus.available) {
      _onNewOrder(table);
    } else {
      _showOccupiedTableSheet(table);
    }
  }

  void _onNewOrder(TableModel table) {
    // Set table context in cart and navigate to cart screen
    ref.read(cartSelectedTableProvider.notifier).state = table.id;
    context.go(AppRoutes.cart);
  }

  void _showOccupiedTableSheet(TableModel table) {
    final orders = ref.read(ordersProvider).valueOrNull ?? [];
    final activeOrder = orders.where((o) =>
      o.tableId == table.id &&
      o.status != OrderStatus.served &&
      o.status != OrderStatus.completed &&
      o.status != OrderStatus.cancelled
    ).firstOrNull;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF262626),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: const BorderSide(color: Color(0xFF383838)),
        ),
        child: Container(
          width: 420.w,
          padding: EdgeInsets.all(24.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E4A40),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: const Icon(Icons.table_bar, color: Color(0xFF22C55E), size: 20),
                      ),
                      Gap(12.w),
                      Text(
                        'Table ${table.tableName}',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFF5F5F5),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: _statusBgColor(table.status),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      _statusLabel(table.status),
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: _statusTextColor(table.status),
                      ),
                    ),
                  ),
                ],
              ),
              Gap(20.h),
              if (table.assignedWaiterName != null)
                _buildDetailItem('Waiter:', table.assignedWaiterName!),
              if (table.occupiedSince != null)
                _buildDetailItem('Seated at:', _timeLabel(table.occupiedSince!)),
              _buildDetailItem('Capacity:', '${table.capacity} seats'),
              if (table.billTotal > 0)
                _buildDetailItem('Current Bill:', CurrencyFormatter.format(table.billTotal)),
              if (activeOrder != null)
                _buildDetailItem('Order #:', activeOrder.orderNumber?.toString() ?? activeOrder.id.substring(0, 8)),
              Gap(24.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        Navigator.of(ctx).pop();
                        try {
                          await ref.read(posTablesProvider.notifier).clearTable(table.id);
                          if (!mounted) return;
                          context.showSuccessSnack('Table ${table.tableName} cleared.');
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Could not clear table: $e'),
                            backgroundColor: AppColors.error,
                          ));
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF383838)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                      child: Text(
                        'Vacate / Settle',
                        style: TextStyle(color: AppColors.error, fontSize: 13.sp),
                      ),
                    ),
                  ),
                  Gap(12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        // Set table context and go to cart to add more items
                        ref.read(cartSelectedTableProvider.notifier).state = table.id;
                        context.go(AppRoutes.cart);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        elevation: 0,
                      ),
                      child: Text(
                        'Add Items',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFFABABAB), fontSize: 13)),
          Text(value, style: const TextStyle(color: Color(0xFFF5F5F5), fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  String _statusLabel(POSTableStatus status) {
    return switch (status) {
      POSTableStatus.available => 'Available',
      POSTableStatus.occupied => 'Occupied',
      POSTableStatus.preparing => 'Preparing',
      POSTableStatus.ready => 'Ready',
      POSTableStatus.paymentPending => 'Pay Pending',
    };
  }

  Color _statusBgColor(POSTableStatus status) {
    return switch (status) {
      POSTableStatus.available => const Color(0xFF664A04),
      POSTableStatus.occupied || POSTableStatus.preparing || POSTableStatus.ready => const Color(0xFF2E4A40),
      POSTableStatus.paymentPending => const Color(0xFF4A2E2E),
    };
  }

  Color _statusTextColor(POSTableStatus status) {
    return switch (status) {
      POSTableStatus.available => const Color(0xFFF5F5F5),
      POSTableStatus.occupied || POSTableStatus.preparing || POSTableStatus.ready => const Color(0xFF22C55E),
      POSTableStatus.paymentPending => const Color(0xFFEF4444),
    };
  }

  String _timeLabel(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ${diff.inMinutes % 60}m ago';
  }

  @override
  Widget build(BuildContext context) {
    final tablesAsync = ref.watch(posTablesProvider);
    final liveTablesRaw = ref.watch(liveTableStatusProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1F1F1F),
      body: SafeArea(
        child: Column(
          children: [
            // ── Action Bar ─────────────────────────────────────────────────
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
                        'Tables',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFF5F5F5),
                          letterSpacing: 0.5,
                        ),
                      ),
                      Gap(12.w),
                      tablesAsync.when(
                        data: (tables) => Container(
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: const Color(0xFF383838),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            '${tables.length} tables',
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
                      _buildFilterChip(label: 'All', value: 'all'),
                      Gap(10.w),
                      _buildFilterChip(label: 'Occupied', value: 'occupied'),
                      Gap(10.w),
                      _buildFilterChip(label: 'Available', value: 'available'),
                      Gap(10.w),
                      // Refresh button
                      InkWell(
                        onTap: () => ref.read(posTablesProvider.notifier).refreshTables(),
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

            // ── Tables Grid ────────────────────────────────────────────────
            Expanded(
              child: tablesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                error: (err, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.wifi_off, size: 48.sp, color: AppColors.textSecondary),
                      Gap(16.h),
                      Text('Could not load tables', style: AppTextStyles.titleMedium),
                      Gap(8.h),
                      Text(err.toString(), style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
                      Gap(16.h),
                      OutlinedButton(
                        onPressed: () => ref.read(posTablesProvider.notifier).refreshTables(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                data: (_) {
                  final liveTables = liveTablesRaw.where((table) {
                    if (_statusFilter == 'occupied') return table.status != POSTableStatus.available;
                    if (_statusFilter == 'available') return table.status == POSTableStatus.available;
                    return true;
                  }).toList();

                  if (liveTables.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.table_restaurant_outlined, size: 48.sp, color: AppColors.textSecondary),
                          Gap(12.h),
                          Text('No tables found', style: AppTextStyles.titleMedium),
                        ],
                      ),
                    );
                  }

                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: GridView.builder(
                      padding: EdgeInsets.only(top: 16.h, bottom: 24.h),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        crossAxisSpacing: 16.w,
                        mainAxisSpacing: 16.h,
                        childAspectRatio: 1.25,
                      ),
                      itemCount: liveTables.length,
                      itemBuilder: (context, i) => _buildTableCard(liveTables[i]),
                    ),
                  );
                },
              ),
            ),
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
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF383838) : Colors.transparent,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14.sp,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? const Color(0xFFF5F5F5) : const Color(0xFFABABAB),
          ),
        ),
      ),
    );
  }

  Widget _buildTableCard(TableModel table) {
    final isOccupied = table.status != POSTableStatus.available;
    final initials = _initials(table.assignedWaiterName);
    final avatarColor = _getAvatarColor(table.assignedWaiterName ?? table.tableName);
    final cleanTableNumber = table.tableName.toLowerCase().startsWith('table')
        ? table.tableName.replaceFirst(RegExp(r'^table\s*', caseSensitive: false), '').trim()
        : table.tableName.trim();

    return InkWell(
      onTap: () => _handleTableTap(table),
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: const Color(0xFF262626),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: isOccupied ? _statusBgColor(table.status) : const Color(0xFF383838),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Table',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFF5F5F5),
                        ),
                      ),
                      Gap(4.w),
                      const Icon(Icons.arrow_forward_rounded, size: 12, color: Color(0xFFABABAB)),
                      Gap(4.w),
                      Flexible(
                        child: Text(
                          cleanTableNumber,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFF5F5F5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Gap(4.w),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: _statusBgColor(table.status),
                    borderRadius: BorderRadius.circular(5.r),
                  ),
                  child: Text(
                    _statusLabel(table.status),
                    style: TextStyle(
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w700,
                      color: _statusTextColor(table.status),
                    ),
                  ),
                ),
              ],
            ),

            // Avatar
            Center(
              child: Container(
                width: 56.r,
                height: 56.r,
                decoration: BoxDecoration(
                  color: isOccupied ? avatarColor : const Color(0xFF383838),
                  shape: BoxShape.circle,
                  boxShadow: [
                    if (isOccupied)
                      BoxShadow(
                        color: avatarColor.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                  ],
                ),
                child: Center(
                  child: isOccupied && initials.isNotEmpty
                      ? Text(
                          initials,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          isOccupied ? Icons.person : Icons.table_restaurant,
                          color: const Color(0xFF888888),
                          size: 22.sp,
                        ),
                ),
              ),
            ),

            // Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${table.capacity} seats',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 11.sp, color: const Color(0xFFABABAB)),
                ),
                if (isOccupied && table.billTotal > 0)
                  Text(
                    CurrencyFormatter.format(table.billTotal),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                if (isOccupied && table.occupiedSince != null && table.billTotal == 0)
                  Text(
                    _timeLabel(table.occupiedSince!),
                    style: TextStyle(fontFamily: 'Inter', fontSize: 10.sp, color: const Color(0xFF888888)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
