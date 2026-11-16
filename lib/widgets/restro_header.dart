import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../theme/theme.dart';
import '../models/models.dart';
import '../providers/restro_pos_provider.dart';
import '../routes/app_routes.dart';
import '../providers/providers.dart';
import 'restro_notifications_dialog.dart';

class RestroHeader extends ConsumerWidget {
  const RestroHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final userName = user?.name ?? 'Admin User';
    final userRole = user?.role.label ?? 'Admin';
    final userInitials = userName
        .trim()
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
        .take(2)
        .join();

    final searchController = TextEditingController(
      text: ref.watch(restroGlobalSearchProvider),
    );
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    return Container(
      height: 72.h,
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      decoration: const BoxDecoration(
        color: AppColors.sidebarBg,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          // ── Brand Logo ──────────────────────────────────────────────────────
          InkWell(
            onTap: () => context.go(AppRoutes.dashboard),
            borderRadius: BorderRadius.circular(12.r),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
              child: Row(
                children: [
                  Container(
                    width: 38.r,
                    height: 38.r,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.restaurant,
                      color: AppColors.textOnWarning,
                      size: 22,
                    ),
                  ),
                  Gap(12.w),
                  Text(
                    'Restro',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Spacer(),

          // ── Global Search Box ───────────────────────────────────────────────
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: 420.w),
              height: 44.h,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(15.r),
                border: Border.all(
                  color: AppColors.border,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.search,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  Gap(12.w),
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14.sp,
                        color: AppColors.textPrimary,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Search dishes, tables, or orders...',
                        hintStyle: TextStyle(
                          fontFamily: 'Inter',
                          color: AppColors.textTertiary,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        filled: false,
                      ),
                      onChanged: (val) {
                        ref.read(restroGlobalSearchProvider.notifier).state = val;
                      },
                    ),
                  ),
                  if (searchController.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        searchController.clear();
                        ref.read(restroGlobalSearchProvider.notifier).state = '';
                      },
                      child: const Icon(
                        Icons.close,
                        color: AppColors.textSecondary,
                        size: 16,
                      ),
                    ),
                ],
              ),
            ),
          ),

          const Spacer(),

          // ── Action Buttons & User Details ───────────────────────────────────
          Row(
            children: [
              // Dashboard Shortcut
              Tooltip(
                message: 'Dashboard',
                child: InkWell(
                  onTap: () => context.go(AppRoutes.dashboard),
                  borderRadius: BorderRadius.circular(14.r),
                  child: Container(
                    width: 44.r,
                    height: 44.r,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    child: const Icon(
                      Icons.dashboard_outlined,
                      color: AppColors.textPrimary,
                      size: 22,
                    ),
                  ),
                ),
              ),

              Gap(12.w),

              // Separate Refresh Button
              Tooltip(
                message: 'Refresh & Sync Data',
                child: InkWell(
                  onTap: () async {
                    // Invalidate live data
                    ref.invalidate(ordersProvider);
                    ref.invalidate(posTablesProvider);
                    ref.invalidate(menuItemsProvider);
                    ref.invalidate(categoriesProvider);
                    ref.invalidate(floorsProvider);
                    ref.invalidate(sectionsProvider);

                    final sessionIds = ref.read(cartSessionIdsProvider);
                    final branchId = sessionIds.branchId;
                    if (branchId != null) {
                      await ref.read(ordersProvider.notifier).fetchOrders();
                      ref.read(posTablesProvider.notifier).refreshTables();
                    }

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, color: AppColors.profit, size: 18),
                              Gap(10.w),
                              const Text(
                                'Data refreshed & synced with TableOS backend.',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  color: AppColors.textOnDark,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: AppColors.textPrimary,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(14.r),
                  child: Container(
                    width: 44.r,
                    height: 44.r,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    child: const Icon(
                      Icons.refresh_rounded,
                      color: AppColors.textPrimary,
                      size: 22,
                    ),
                  ),
                ),
              ),

              Gap(12.w),

              // Notification Bell (opens Notification Dialog)
              Tooltip(
                message: 'Notifications',
                child: InkWell(
                  onTap: () {
                    RestroNotificationsDialog.show(context);
                  },
                  borderRadius: BorderRadius.circular(14.r),
                  child: Container(
                    width: 44.r,
                    height: 44.r,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          unreadCount > 0
                              ? Icons.notifications_active_rounded
                              : Icons.notifications_none_outlined,
                          color: AppColors.textPrimary,
                          size: 22,
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            top: 8.r,
                            right: 8.r,
                            child: Container(
                              padding: EdgeInsets.all(unreadCount > 9 ? 2.r : 4.r),
                              constraints: BoxConstraints(minWidth: 16.r, minHeight: 16.r),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  unreadCount > 9 ? '9+' : '$unreadCount',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 9.sp,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textOnWarning,
                                    height: 1.0,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              Gap(16.w),

              // User Info Pill & Logout
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(30.r),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16.r,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        userInitials.isEmpty ? 'AU' : userInitials,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textOnWarning,
                        ),
                      ),
                    ),
                    Gap(10.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          userName,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          userRole,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11.sp,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    Gap(12.w),
                    IconButton(
                      icon: const Icon(
                        Icons.logout,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      tooltip: 'Logout',
                      onPressed: () async {
                        await ref.read(authProvider.notifier).logout();
                        if (context.mounted) {
                          context.go(AppRoutes.login);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
