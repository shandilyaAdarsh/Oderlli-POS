import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../theme/theme.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/restro_pos_provider.dart';
import '../routes/app_routes.dart';

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

    return Container(
      height: 72.h,
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      color: const Color(0xFF1A1A1A),
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
                      color: Color(0xFF1F1F1F),
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
                      color: const Color(0xFFF5F5F5),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Spacer(),

          // ── Global Search Box ───────────────────────────────────────────────
          Container(
            width: 420.w,
            height: 44.h,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            decoration: BoxDecoration(
              color: const Color(0xFF1F1F1F),
              borderRadius: BorderRadius.circular(15.r),
              border: Border.all(
                color: const Color(0xFF2E2E2E),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.search,
                  color: Color(0xFFABABAB),
                  size: 20,
                ),
                Gap(12.w),
                Expanded(
                  child: TextField(
                    controller: searchController,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14.sp,
                      color: const Color(0xFFF5F5F5),
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Search dishes, tables, or orders...',
                      hintStyle: TextStyle(
                        fontFamily: 'Inter',
                        color: Color(0xFF757575),
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
                      color: Color(0xFFABABAB),
                      size: 16,
                    ),
                  ),
              ],
            ),
          ),

          const Spacer(),

          // ── Action Buttons & User Details ───────────────────────────────────
          Row(
            children: [
              // Dashboard Shortcut
              InkWell(
                onTap: () => context.go(AppRoutes.dashboard),
                borderRadius: BorderRadius.circular(14.r),
                child: Container(
                  width: 44.r,
                  height: 44.r,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F1F1F),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: const Icon(
                    Icons.dashboard_outlined,
                    color: Color(0xFFF5F5F5),
                    size: 22,
                  ),
                ),
              ),

              Gap(12.w),

              // Notification Bell
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('All orders synced and up to date.'),
                      backgroundColor: Color(0xFF262626),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(14.r),
                child: Container(
                  width: 44.r,
                  height: 44.r,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F1F1F),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(
                        Icons.notifications_none_outlined,
                        color: Color(0xFFF5F5F5),
                        size: 22,
                      ),
                      Positioned(
                        top: 10.r,
                        right: 10.r,
                        child: Container(
                          width: 8.r,
                          height: 8.r,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Gap(16.w),

              // User Info Pill & Logout
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F1F1F),
                  borderRadius: BorderRadius.circular(30.r),
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
                          color: const Color(0xFF1F1F1F),
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
                            color: const Color(0xFFF5F5F5),
                          ),
                        ),
                        Text(
                          userRole,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11.sp,
                            color: const Color(0xFFABABAB),
                          ),
                        ),
                      ],
                    ),
                    Gap(12.w),
                    IconButton(
                      icon: const Icon(
                        Icons.logout,
                        color: Color(0xFFABABAB),
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
