import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../theme/theme.dart';
import '../routes/app_routes.dart';
import '../providers/customer_provider.dart';

class RestroBottomNav extends ConsumerStatefulWidget {
  final String activePath;

  const RestroBottomNav({
    super.key,
    required this.activePath,
  });

  @override
  ConsumerState<RestroBottomNav> createState() => _RestroBottomNavState();
}

class _RestroBottomNavState extends ConsumerState<RestroBottomNav> {
  void _openCreateOrderModal(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (ctx) => const _CreateOrderDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isHome = widget.activePath == AppRoutes.dashboard || widget.activePath == '/';
    final isOrders = widget.activePath.startsWith(AppRoutes.orders);
    final isTables = widget.activePath.startsWith(AppRoutes.floor) ||
        widget.activePath.startsWith(AppRoutes.tableSelection);
    final isMenu = widget.activePath.startsWith(AppRoutes.menu) ||
        widget.activePath.startsWith(AppRoutes.posMenu);

    return Container(
      height: 70.h,
      color: const Color(0xFF262626),
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // ── Home Tab ───────────────────────────────────────────────────
              Expanded(
                child: _buildNavButton(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  isActive: isHome,
                  onTap: () => context.go(AppRoutes.dashboard),
                ),
              ),

              // ── Orders Tab ─────────────────────────────────────────────────
              Expanded(
                child: _buildNavButton(
                  icon: Icons.receipt_long_rounded,
                  label: 'Orders',
                  isActive: isOrders,
                  onTap: () => context.go(AppRoutes.orders),
                ),
              ),

              // Spacer for the center floating button
              Gap(80.w),

              // ── Tables Tab ─────────────────────────────────────────────────
              Expanded(
                child: _buildNavButton(
                  icon: Icons.table_bar_rounded,
                  label: 'Tables',
                  isActive: isTables,
                  onTap: () => context.go(AppRoutes.floor),
                ),
              ),

              // ── Menu / More Tab ───────────────────────────────────────────
              Expanded(
                child: _buildNavButton(
                  icon: Icons.restaurant_menu_rounded,
                  label: 'Menu',
                  isActive: isMenu,
                  onTap: () => context.go(AppRoutes.menu),
                ),
              ),
            ],
          ),

          // ── Central Floating Action Button (Create Order) ───────────────────
          Positioned(
            top: -24.h,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _openCreateOrderModal(context),
                borderRadius: BorderRadius.circular(36.r),
                child: Container(
                  width: 64.r,
                  height: 64.r,
                  decoration: BoxDecoration(
                    color: AppColors.primary, // Signature #F6B100
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.dinner_dining_rounded,
                      color: Color(0xFF1F1F1F),
                      size: 32,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20.r),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 48.h,
        margin: EdgeInsets.symmetric(horizontal: 4.w),
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF343434) : Colors.transparent,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? const Color(0xFFF5F5F5) : const Color(0xFFABABAB),
              size: 20,
            ),
            Gap(8.w),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14.sp,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? const Color(0xFFF5F5F5) : const Color(0xFFABABAB),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Create Order Modal (Matching BottomNav.jsx Modal) ────────────────────────

class _CreateOrderDialog extends ConsumerStatefulWidget {
  const _CreateOrderDialog();

  @override
  ConsumerState<_CreateOrderDialog> createState() => _CreateOrderDialogState();
}

class _CreateOrderDialogState extends ConsumerState<_CreateOrderDialog> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  int _guestCount = 2;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _handleCreateOrder() {
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();

    ref.read(customerDetailsProvider.notifier).setCustomer(
          name: name.isEmpty ? 'Guest Customer' : name,
          phone: phone,
          guests: _guestCount,
        );

    Navigator.of(context).pop();
    context.go(AppRoutes.floor); // Go to Tables
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF262626),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
        side: const BorderSide(color: Color(0xFF383838), width: 1),
      ),
      insetPadding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 24.h),
      child: Container(
        width: 480.w,
        padding: EdgeInsets.all(28.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Modal Title & Close Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Create Order',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFF5F5F5),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.close,
                    color: Color(0xFFABABAB),
                    size: 22,
                  ),
                ),
              ],
            ),

            Gap(20.h),

            // Customer Name
            Text(
              'Customer Name',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFABABAB),
              ),
            ),
            Gap(8.h),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1F1F1F),
                borderRadius: BorderRadius.circular(12.r),
              ),
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: TextField(
                controller: _nameCtrl,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFFF5F5F5),
                ),
                decoration: const InputDecoration(
                  hintText: 'Enter customer name',
                  hintStyle: TextStyle(
                    fontFamily: 'Inter',
                    color: Color(0xFF666666),
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                ),
              ),
            ),

            Gap(16.h),

            // Customer Phone
            Text(
              'Customer Phone',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFABABAB),
              ),
            ),
            Gap(8.h),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1F1F1F),
                borderRadius: BorderRadius.circular(12.r),
              ),
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFFF5F5F5),
                ),
                decoration: const InputDecoration(
                  hintText: '+91-9999999999',
                  hintStyle: TextStyle(
                    fontFamily: 'Inter',
                    color: Color(0xFF666666),
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                ),
              ),
            ),

            Gap(16.h),

            // Guests Stepper
            Text(
              'Guests',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFABABAB),
              ),
            ),
            Gap(8.h),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1F1F1F),
                borderRadius: BorderRadius.circular(12.r),
              ),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {
                      if (_guestCount > 1) {
                        setState(() => _guestCount--);
                      }
                    },
                    icon: const Icon(
                      Icons.remove,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  Text(
                    '$_guestCount Person',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFF5F5F5),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      if (_guestCount < 12) {
                        setState(() => _guestCount++);
                      }
                    },
                    icon: const Icon(
                      Icons.add,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),

            Gap(28.h),

            // Create Order Button
            SizedBox(
              width: double.infinity,
              height: 50.h,
              child: ElevatedButton(
                onPressed: _handleCreateOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: const Color(0xFF1F1F1F),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Create Order',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
