import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../theme/theme.dart';
import '../../mock/restro_mock_data.dart';
import '../../providers/auth_provider.dart';
import '../../providers/restro_pos_provider.dart';
import '../../providers/orders_provider.dart';
import '../../providers/menu_provider.dart';
import '../../models/models.dart';
import '../../routes/app_routes.dart';
import '../../widgets/restro_header.dart';
import '../../widgets/restro_bottom_nav.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  late DateTime _currentTime;
  Timer? _timer;
  String _selectedAdminTab = 'Overview'; // 'Overview' | 'Orders'

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _currentTime = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _getGreeting() {
    final hour = _currentTime.hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final userName = user?.name ?? 'Admin User';
    final backendOrders = ref.watch(ordersProvider).valueOrNull ?? [];
    final liveOrders = backendOrders.map((o) {
      final statusStr = switch (o.status) {
        OrderStatus.ready => 'Ready',
        OrderStatus.preparing || OrderStatus.accepted => 'In Progress',
        OrderStatus.pending => 'Pending',
        OrderStatus.served => 'Served',
        OrderStatus.completed => 'Completed',
        OrderStatus.cancelled => 'Cancelled',
        OrderStatus.syncConflict => 'Conflict',
      };
      return RestroOrder(
        id: o.id,
        customer: o.notes?.replaceAll('Customer: ', '') ?? 'Walk-in Guest',
        status: statusStr,
        dateTime: o.createdAt,
        itemCount: o.items.fold(0, (sum, i) => sum + i.quantity),
        tableNo: o.tableNumber > 0 ? '${o.tableNumber}' : 'Counter',
        total: o.grandTotalMinor / 100.0,
        itemNames: o.items.map((i) => '${i.itemNameSnapshot} (${i.quantity})').toList(),
      );
    }).toList();
    final localOrders = ref.watch(restroOrdersProvider);
    final orders = liveOrders.isNotEmpty ? liveOrders : localOrders;
    final searchQuery = ref.watch(restroGlobalSearchProvider).toLowerCase();

    final filteredOrders = orders.where((o) {
      if (searchQuery.isEmpty) return true;
      return o.customer.toLowerCase().contains(searchQuery) ||
          o.tableNo.contains(searchQuery) ||
          o.status.toLowerCase().contains(searchQuery);
    }).toList();

    final inProgressOrders = orders.where((o) => o.status == 'In Progress').length;
    final totalRevenue = orders.fold(0.0, (sum, o) => sum + o.total);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Header ──────────────────────────────────────────────────
            const RestroHeader(),

            // ── Main Content Area ───────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Admin Action Buttons & Tab Bar (From Dashboard.jsx)
                    _buildAdminTopBar(),

                    Gap(16.h),

                    if (_selectedAdminTab == 'Overview')
                      // ── Home View (Greetings, MiniCards, Recent Orders, Popular Dishes)
                      _buildHomeOverview(userName, totalRevenue, inProgressOrders, filteredOrders)
                    else
                      // ── Admin Orders Table
                      _buildAdminOrdersView(filteredOrders),
                  ],
                ),
              ),
            ),

            // ── Bottom Navigation ───────────────────────────────────────────
            const RestroBottomNav(activePath: AppRoutes.dashboard),
          ],
        ),
      ),
    );
  }

  // ─── Admin Top Bar ─────────────────────────────────────────────────────────

  Widget _buildAdminTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Operational Dashboard',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),

        // Tabs Toggle
        Container(
          padding: EdgeInsets.all(4.r),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Row(
            children: [
              _buildTabPill('Overview'),
              _buildTabPill('Orders'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabPill(String tab) {
    final isSelected = _selectedAdminTab == tab;
    return InkWell(
      onTap: () => setState(() => _selectedAdminTab = tab),
      borderRadius: BorderRadius.circular(8.r),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.sidebarActiveBg : Colors.transparent,
          borderRadius: BorderRadius.circular(8.r),
          border: isSelected
              ? Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1)
              : null,
        ),
        child: Text(
          tab,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13.sp,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.sidebarTextActive : AppColors.sidebarText,
          ),
        ),
      ),
    );
  }

  // ─── Home Overview Layout (Home.jsx) ───────────────────────────────────────

  Widget _buildHomeOverview(
    String userName,
    double totalRevenue,
    int inProgressOrders,
    List<RestroOrder> orders,
  ) {
    final timeFormat = DateFormat('hh:mm:ss a');
    final dateFormat = DateFormat('EEEE, MMMM dd, yyyy');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Left Column (60%): Greetings, MiniCards, Recent Orders ───────────
        Expanded(
          flex: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greetings Banner (Greetings.jsx)
              Container(
                padding: EdgeInsets.all(20.r),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: AppColors.border, width: 1),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x06000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_getGreeting()}, $userName 👋',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 22.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Gap(4.h),
                          Text(
                            'Give your best service for customers today!',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13.sp,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Gap(16.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          timeFormat.format(_currentTime),
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                            letterSpacing: 1.0,
                          ),
                        ),
                        Gap(2.h),
                        Text(
                          dateFormat.format(_currentTime),
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12.sp,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Gap(16.h),

              // Mini Cards Row (MiniCard.jsx)
              Row(
                children: [
                  Expanded(
                    child: _buildMiniCard(
                      title: 'Total Earnings',
                      icon: Icons.monetization_on_outlined,
                      value: '₹${NumberFormat('#,##,###').format(totalRevenue)}',
                      footerPercent: '+1.6%',
                      accentColor: AppColors.primary,
                    ),
                  ),
                  Gap(16.w),
                  Expanded(
                    child: _buildMiniCard(
                      title: 'In Progress Orders',
                      icon: Icons.timelapse_rounded,
                      value: '$inProgressOrders Orders',
                      footerPercent: '+3.6%',
                      accentColor: const Color(0xFF025CCA),
                    ),
                  ),
                ],
              ),

              Gap(20.h),

              // Recent Orders Card (RecentOrders.jsx)
              _buildRecentOrdersCard(orders),
            ],
          ),
        ),

        Gap(20.w),

        // ── Right Column (40%): Popular Dishes (PopularDishes.jsx) ───────────
        Expanded(
          flex: 4,
          child: _buildPopularDishesCard(),
        ),
      ],
    );
  }

  Widget _buildMiniCard({
    required String title,
    required IconData icon,
    required String value,
    required String footerPercent,
    required Color accentColor,
  }) {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Gap(8.w),
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
            ],
          ),
          Gap(12.h),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 24.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          Gap(8.h),
          Row(
            children: [
              const Icon(Icons.arrow_upward, color: Color(0xFF22C55E), size: 14),
              Gap(4.w),
              Flexible(
                child: Text(
                  '$footerPercent from yesterday',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.sp,
                    color: const Color(0xFF22C55E),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentOrdersCard(List<RestroOrder> orders) {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Orders',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () => context.go(AppRoutes.orders),
                child: Text(
                  'View all',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.neutral,
                  ),
                ),
              ),
            ],
          ),

          Gap(12.h),

          if (orders.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 36.h),
              child: const Center(
                child: Text(
                  'No recent orders available',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: orders.take(5).length,
              separatorBuilder: (_, _) => Gap(12.h),
              itemBuilder: (context, i) {
                final order = orders[i];
                final initials = order.customer
                    .trim()
                    .split(' ')
                    .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
                    .take(2)
                    .join();

                final isReady = order.status == 'Ready';

                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: Row(
                    children: [
                      // Avatar
                      Container(
                        width: 42.r,
                        height: 42.r,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Center(
                          child: Text(
                            initials.isEmpty ? 'G' : initials,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      Gap(14.w),

                      // Customer & Items
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
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Gap(2.h),
                            Text(
                              '${order.itemCount} Items • ₹${order.total.toStringAsFixed(0)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12.sp,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Table Pill
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.primary),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          children: [
                            Text(
                              'Table',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11.sp,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Gap(4.w),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 12,
                              color: AppColors.textSecondary,
                            ),
                            Gap(4.w),
                            Text(
                              order.tableNo,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Gap(16.w),

                      // Status Pill
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: isReady ? AppColors.statusReadyContainer : AppColors.statusPendingContainer,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isReady ? Icons.done_all : Icons.circle,
                              size: 14,
                              color: isReady ? AppColors.statusReady : AppColors.sidebarActive,
                            ),
                            Gap(6.w),
                            Text(
                              order.status,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w700,
                                color: isReady ? AppColors.statusReady : AppColors.sidebarActive,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ─── Popular Dishes (PopularDishes.jsx) ─────────────────────────────────────

  Widget _buildPopularDishesCard() {
    final menuItems = ref.watch(menuItemsProvider).valueOrNull ?? [];
    final dishes = menuItems.isNotEmpty
        ? menuItems.take(5).toList().asMap().entries.map((entry) {
            final idx = entry.key + 1;
            final item = entry.value;
            return RestroPopularDish(
              id: idx,
              name: item.name,
              numberOfOrders: 10 + (idx * 3),
              price: item.price,
              emoji: '🍽️',
              category: 'Featured',
              isVeg: item.isVegetarian,
            );
          }).toList()
        : RestroMockData.popularDishes;

    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Popular Dishes',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () => context.go(AppRoutes.menu),
                child: Text(
                  'View all',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF025CCA),
                  ),
                ),
              ),
            ],
          ),

          Gap(12.h),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: dishes.length,
            separatorBuilder: (_, _) => Gap(10.h),
            itemBuilder: (context, i) {
              final dish = dishes[i];
              final rankStr = dish.id < 10 ? '0${dish.id}' : '${dish.id}';

              return Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  children: [
                    Text(
                      rankStr,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Gap(14.w),
                    Container(
                      width: 44.r,
                      height: 44.r,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Center(
                        child: Text(dish.emoji, style: TextStyle(fontSize: 22.sp)),
                      ),
                    ),
                    Gap(14.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dish.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Gap(2.h),
                          Text(
                            'Orders: ${dish.numberOfOrders}',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12.sp,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.add_shopping_cart,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      tooltip: 'Add to order',
                      onPressed: () {
                        // Add to restro cart and notify
                        ref.read(restroCartProvider.notifier).addItem(
                              RestroMenuItem(
                                id: dish.id,
                                name: dish.name,
                                price: dish.price,
                                category: dish.category,
                                isVeg: dish.isVeg,
                                emoji: dish.emoji,
                              ),
                            );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Added ${dish.name} to cart!'),
                            backgroundColor: AppColors.textPrimary,
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ─── Admin Orders Table ────────────────────────────────────────────────────

  Widget _buildAdminOrdersView(List<RestroOrder> orders) {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Restaurant Orders Log',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          Gap(16.h),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: orders.length,
            separatorBuilder: (_, _) => Divider(color: AppColors.border),
            itemBuilder: (context, i) {
              final o = orders[i];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Text(
                    o.customer.isNotEmpty ? o.customer[0].toUpperCase() : 'G',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(
                  o.customer,
                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Table ${o.tableNo} • ${o.itemCount} items • ${DateFormat('hh:mm a').format(o.dateTime)}',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '₹${o.total.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    Gap(16.w),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: o.status == 'Ready'
                            ? AppColors.statusReadyContainer
                            : (o.status == 'Completed'
                                ? const Color(0xFFEDE9FE)
                                : AppColors.statusPendingContainer),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        o.status,
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: o.status == 'Ready'
                              ? AppColors.statusReady
                              : (o.status == 'Completed'
                                  ? const Color(0xFF7C3AED)
                                  : AppColors.sidebarActive),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }


}
