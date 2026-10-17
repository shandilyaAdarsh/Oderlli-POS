import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../theme/theme.dart';
import '../../mock/restro_mock_data.dart';
import '../../providers/customer_provider.dart';
import '../../providers/restro_pos_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/restro_header.dart';
import '../../widgets/restro_bottom_nav.dart';

class FloorScreen extends ConsumerStatefulWidget {
  const FloorScreen({super.key});

  @override
  ConsumerState<FloorScreen> createState() => _FloorScreenState();
}

class _FloorScreenState extends ConsumerState<FloorScreen> {
  String _statusFilter = 'all'; // 'all' | 'booked' | 'available'

  // Colors list from utils.js in Restaurant_POS_System
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

  Color _getAvatarColor(String initial) {
    if (initial.isEmpty || initial == 'N/A') return const Color(0xFF1F1F1F);
    final code = initial.codeUnitAt(0);
    return _avatarColors[code % _avatarColors.length];
  }

  void _handleTableClick(RestroTableItem table) {
    if (table.isBooked) {
      _showBookedTableModal(table);
      return;
    }

    // Assign table to active customer and navigate to menu
    ref.read(customerDetailsProvider.notifier).updateTable(
          tableId: table.id,
          tableNo: table.name,
        );

    context.go(AppRoutes.menu);
  }

  void _showBookedTableModal(RestroTableItem table) {
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
                        'Table → ${table.name}',
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
                      color: const Color(0xFF2E4A40),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      'Booked',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF22C55E),
                      ),
                    ),
                  ),
                ],
              ),
              Gap(20.h),
              _buildDetailItem('Customer:', table.customerName ?? 'Walk-in Guest'),
              if (table.customerPhone != null)
                _buildDetailItem('Phone:', table.customerPhone!),
              _buildDetailItem('Seats:', '${table.seats} Person'),
              if (table.currentBillTotal != null)
                _buildDetailItem('Current Bill:', '₹${table.currentBillTotal!.toStringAsFixed(2)}'),
              Gap(24.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        ref.read(restroTablesProvider.notifier).freeTable(table.name);
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Table ${table.name} has been vacated and cleaned.'),
                            backgroundColor: const Color(0xFF262626),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF383838)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                      child: Text(
                        'Vacate / Settle',
                        style: TextStyle(color: const Color(0xFFEF4444), fontSize: 13.sp),
                      ),
                    ),
                  ),
                  Gap(12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Switch active customer to this table and open Menu
                        ref.read(customerDetailsProvider.notifier).setCustomer(
                              name: table.customerName ?? 'Table ${table.name}',
                              phone: table.customerPhone,
                              guests: table.seats,
                            );
                        ref.read(customerDetailsProvider.notifier).updateTable(
                              tableId: table.id,
                              tableNo: table.name,
                            );
                        Navigator.of(ctx).pop();
                        context.go(AppRoutes.menu);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: const Color(0xFF1F1F1F),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
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
          Text(
            value,
            style: const TextStyle(color: Color(0xFFF5F5F5), fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tables = ref.watch(restroTablesProvider);
    final searchQuery = ref.watch(restroGlobalSearchProvider).toLowerCase();

    final filteredTables = tables.where((table) {
      if (_statusFilter == 'booked' && !table.isBooked) return false;
      if (_statusFilter == 'available' && table.isBooked) return false;
      if (searchQuery.isNotEmpty && !table.name.toLowerCase().contains(searchQuery)) return false;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF1F1F1F),
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Header ──────────────────────────────────────────────────
            const RestroHeader(),

            // ── Action Bar: Back button, Title & Status Filters ──────────────
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
                        'Tables',
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

                  // Filter Buttons
                  Row(
                    children: [
                      _buildFilterChip(label: 'All', value: 'all'),
                      Gap(10.w),
                      _buildFilterChip(label: 'Booked', value: 'booked'),
                      Gap(10.w),
                      _buildFilterChip(label: 'Available', value: 'available'),
                    ],
                  ),
                ],
              ),
            ),

            // ── Tables Grid (TableCard.jsx in grid-cols-5) ───────────────────
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: GridView.builder(
                  padding: EdgeInsets.only(bottom: 24.h),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 16.w,
                    mainAxisSpacing: 16.h,
                    childAspectRatio: 1.25,
                  ),
                  itemCount: filteredTables.length,
                  itemBuilder: (context, i) {
                    final table = filteredTables[i];
                    return _buildTableCard(table);
                  },
                ),
              ),
            ),

            // ── Bottom Navigation ───────────────────────────────────────────
            const RestroBottomNav(activePath: AppRoutes.floor),
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

  // ─── Table Card (TableCard.jsx) ────────────────────────────────────────────

  Widget _buildTableCard(RestroTableItem table) {
    final isBooked = table.isBooked;
    final avatarColor = _getAvatarColor(table.initial);

    return InkWell(
      onTap: () => _handleTableClick(table),
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: const Color(0xFF262626),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: isBooked ? const Color(0xFF2E4A40) : const Color(0xFF383838),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Header: Table -> N and Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Table',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFF5F5F5),
                      ),
                    ),
                    Gap(4.w),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: Color(0xFFABABAB),
                    ),
                    Gap(4.w),
                    Text(
                      table.name,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFF5F5F5),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: isBooked ? const Color(0xFF2E4A40) : const Color(0xFF664A04),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    table.status,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: isBooked ? const Color(0xFF22C55E) : const Color(0xFFF5F5F5),
                    ),
                  ),
                ),
              ],
            ),

            // Center Initials Avatar Circle
            Center(
              child: Container(
                width: 60.r,
                height: 60.r,
                decoration: BoxDecoration(
                  color: avatarColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    if (isBooked)
                      BoxShadow(
                        color: avatarColor.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                child: Center(
                  child: Text(
                    table.initial.isNotEmpty ? table.initial : 'N/A',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

            // Footer: Seats Count
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                RichText(
                  text: TextSpan(
                    text: 'Seats: ',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.sp,
                      color: const Color(0xFFABABAB),
                    ),
                    children: [
                      TextSpan(
                        text: '${table.seats}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFF5F5F5),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isBooked && table.currentBillTotal != null)
                  Text(
                    '₹${table.currentBillTotal!.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
