import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../theme/theme.dart';
import '../../mock/restro_mock_data.dart';
import '../../providers/auth_provider.dart';
import '../../providers/restro_pos_provider.dart';
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
  String _selectedAdminTab = 'Metrics'; // 'Metrics' | 'Orders' | 'Overview'

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
    final orders = ref.watch(restroOrdersProvider);
    final searchQuery = ref.watch(restroGlobalSearchProvider).toLowerCase();

    final filteredOrders = orders.where((o) {
      if (searchQuery.isEmpty) return true;
      return o.customer.toLowerCase().contains(searchQuery) ||
          o.tableNo.contains(searchQuery) ||
          o.status.toLowerCase().contains(searchQuery);
    }).toList();

    final readyOrders = orders.where((o) => o.status == 'Ready').length;
    final inProgressOrders = orders.where((o) => o.status == 'In Progress').length;
    final totalRevenue = orders.fold(0.0, (sum, o) => sum + o.total);

    return Scaffold(
      backgroundColor: const Color(0xFF1F1F1F),
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
                    else if (_selectedAdminTab == 'Metrics')
                      // ── Metrics View (Overall Performance + Item Details from Metrics.jsx)
                      _buildMetricsView()
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
        // Action Buttons
        Row(
          children: [
            _buildAdminActionButton(
              label: 'Add Table',
              icon: Icons.table_restaurant_rounded,
              onTap: () => _showAddTableDialog(),
            ),
            Gap(12.w),
            _buildAdminActionButton(
              label: 'Add Dishes',
              icon: Icons.fastfood_rounded,
              onTap: () => context.go(AppRoutes.menu),
            ),
            if (kDebugMode) ...[
              Gap(12.w),
              _buildAdminActionButton(
                label: 'Verify Sentry',
                icon: Icons.bug_report_outlined,
                onTap: () async {
                  try {
                    throw StateError('Sentry verification test event from Restro POS Dashboard');
                  } catch (e, st) {
                    await Sentry.captureException(e, stackTrace: st);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          '✅ Sentry test event captured and reported!',
                          style: TextStyle(fontFamily: 'PlusJakartaSans', color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                        backgroundColor: Color(0xFF2E7D32),
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                },
              ),
            ],
          ],
        ),

        // Tabs Toggle
        Container(
          padding: EdgeInsets.all(4.r),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            children: [
              _buildTabPill('Overview'),
              _buildTabPill('Metrics'),
              _buildTabPill('Orders'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdminActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: const Color(0xFFF5F5F5)),
      label: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 13.sp,
          fontWeight: FontWeight.w600,
          color: const Color(0xFFF5F5F5),
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF262626),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
        elevation: 0,
      ),
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
          color: isSelected ? const Color(0xFF262626) : Colors.transparent,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Text(
          tab,
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
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(16.r),
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
                              color: const Color(0xFFF5F5F5),
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
                              color: const Color(0xFFABABAB),
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
                            color: const Color(0xFFABABAB),
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
                      value: '₹${NumberFormat('#,##,###').format(totalRevenue + 512000)}',
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
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16.r),
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
                    color: const Color(0xFFABABAB),
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
              color: const Color(0xFFF5F5F5),
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
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16.r),
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
                  color: const Color(0xFFF5F5F5),
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
                    color: const Color(0xFF025CCA),
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
                  style: TextStyle(color: Color(0xFFABABAB)),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: orders.take(5).length,
              separatorBuilder: (_, __) => Gap(12.h),
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
                    color: const Color(0xFF1F1F1F),
                    borderRadius: BorderRadius.circular(12.r),
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
                              color: const Color(0xFF1F1F1F),
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
                                color: const Color(0xFFF5F5F5),
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
                                color: const Color(0xFFABABAB),
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
                          color: isReady ? const Color(0xFF2E4A40) : const Color(0xFF4A452E),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isReady ? Icons.done_all : Icons.circle,
                              size: 14,
                              color: isReady ? const Color(0xFF22C55E) : AppColors.primary,
                            ),
                            Gap(6.w),
                            Text(
                              order.status,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w700,
                                color: isReady ? const Color(0xFF22C55E) : AppColors.primary,
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
    final dishes = RestroMockData.popularDishes;

    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16.r),
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
                  color: const Color(0xFFF5F5F5),
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
            separatorBuilder: (_, __) => Gap(10.h),
            itemBuilder: (context, i) {
              final dish = dishes[i];
              final rankStr = dish.id < 10 ? '0${dish.id}' : '${dish.id}';

              return Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F1F1F),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Row(
                  children: [
                    Text(
                      rankStr,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFF5F5F5),
                      ),
                    ),
                    Gap(14.w),
                    Container(
                      width: 44.r,
                      height: 44.r,
                      decoration: BoxDecoration(
                        color: const Color(0xFF262626),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF383838)),
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
                              color: const Color(0xFFF5F5F5),
                            ),
                          ),
                          Gap(2.h),
                          Text(
                            'Orders: ${dish.numberOfOrders}',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12.sp,
                              color: const Color(0xFFABABAB),
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
                            backgroundColor: const Color(0xFF262626),
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

  // ─── Metrics View (Metrics.jsx) ───────────────────────────────────────────

  Widget _buildMetricsView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Overall Performance Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Overall Performance',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFF5F5F5),
                  ),
                ),
                Gap(4.h),
                Text(
                  'Real-time revenue, customer traffic, and event volume',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13.sp,
                    color: const Color(0xFFABABAB),
                  ),
                ),
              ],
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  Text(
                    'Last 1 Month',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.sp,
                      color: const Color(0xFFF5F5F5),
                    ),
                  ),
                  Gap(6.w),
                  const Icon(Icons.arrow_drop_down, color: Color(0xFFF5F5F5), size: 16),
                ],
              ),
            ),
          ],
        ),

        Gap(16.h),

        // Overall Performance 4-Card Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 16.w,
            mainAxisSpacing: 16.h,
            childAspectRatio: 2.2,
          ),
          itemCount: RestroMockData.overallPerformance.length,
          itemBuilder: (context, i) {
            final metric = RestroMockData.overallPerformance[i];
            return Container(
              padding: EdgeInsets.all(18.r),
              decoration: BoxDecoration(
                color: metric.color,
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: metric.color.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        metric.title,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFF5F5F5),
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            metric.isIncrease ? Icons.arrow_upward : Icons.arrow_downward,
                            size: 14,
                            color: metric.isIncrease ? Colors.white : Colors.redAccent,
                          ),
                          Gap(2.w),
                          Text(
                            metric.percentage,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                              color: metric.isIncrease ? Colors.white : Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Text(
                    metric.value,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFF5F5F5),
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        Gap(32.h),

        // Item Details Header
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Item Details',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFF5F5F5),
              ),
            ),
            Gap(4.h),
            Text(
              'Active inventory, live dishes, categories, and table capacity',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13.sp,
                color: const Color(0xFFABABAB),
              ),
            ),
          ],
        ),

        Gap(16.h),

        // Item Details 4-Card Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 16.w,
            mainAxisSpacing: 16.h,
            childAspectRatio: 2.2,
          ),
          itemCount: RestroMockData.itemDetails.length,
          itemBuilder: (context, i) {
            final item = RestroMockData.itemDetails[i];
            return Container(
              padding: EdgeInsets.all(18.r),
              decoration: BoxDecoration(
                color: item.color,
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: item.color.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFF5F5F5),
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            item.isIncrease ? Icons.arrow_upward : Icons.arrow_downward,
                            size: 14,
                            color: Colors.white,
                          ),
                          Gap(2.w),
                          Text(
                            item.percentage,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Text(
                    item.value,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFF5F5F5),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // ─── Admin Orders Table ────────────────────────────────────────────────────

  Widget _buildAdminOrdersView(List<RestroOrder> orders) {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16.r),
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
              color: const Color(0xFFF5F5F5),
            ),
          ),
          Gap(16.h),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const Divider(color: Color(0xFF2E2E2E)),
            itemBuilder: (context, i) {
              final o = orders[i];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Text(
                    o.customer.isNotEmpty ? o.customer[0].toUpperCase() : 'G',
                    style: const TextStyle(color: Color(0xFF1F1F1F), fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(
                  o.customer,
                  style: const TextStyle(color: Color(0xFFF5F5F5), fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Table ${o.tableNo} • ${o.itemCount} items • ${DateFormat('hh:mm a').format(o.dateTime)}',
                  style: const TextStyle(color: Color(0xFFABABAB)),
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
                            ? const Color(0xFF2E4A40)
                            : (o.status == 'Completed'
                                ? const Color(0xFF1D2569)
                                : const Color(0xFF4A452E)),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        o.status,
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: o.status == 'Ready'
                              ? const Color(0xFF22C55E)
                              : (o.status == 'Completed'
                                  ? const Color(0xFF8B5CF6)
                                  : AppColors.primary),
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

  // ─── Add Table Dialog (Modal.jsx in Dashboard) ─────────────────────────────

  void _showAddTableDialog() {
    final tableNoCtrl = TextEditingController();
    int seats = 4;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          backgroundColor: const Color(0xFF262626),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
            side: const BorderSide(color: Color(0xFF383838)),
          ),
          child: Container(
            width: 400.w,
            padding: EdgeInsets.all(24.r),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Add Table',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFF5F5F5),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(Icons.close, color: Color(0xFFABABAB)),
                    ),
                  ],
                ),
                Gap(16.h),
                Text(
                  'Table Number / Name',
                  style: TextStyle(color: const Color(0xFFABABAB), fontSize: 13.sp),
                ),
                Gap(6.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 14.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F1F1F),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: TextField(
                    controller: tableNoCtrl,
                    style: const TextStyle(color: Color(0xFFF5F5F5)),
                    decoration: const InputDecoration(
                      hintText: 'e.g. 16, Patio-1',
                      hintStyle: TextStyle(color: Color(0xFF666666)),
                      border: InputBorder.none,
                      filled: false,
                    ),
                  ),
                ),
                Gap(16.h),
                Text(
                  'Seats Capacity: $seats',
                  style: TextStyle(color: const Color(0xFFABABAB), fontSize: 13.sp),
                ),
                Gap(6.h),
                Slider(
                  value: seats.toDouble(),
                  min: 1,
                  max: 12,
                  divisions: 11,
                  activeColor: AppColors.primary,
                  inactiveColor: const Color(0xFF383838),
                  onChanged: (val) {
                    setDialogState(() => seats = val.toInt());
                  },
                ),
                Gap(20.h),
                SizedBox(
                  width: double.infinity,
                  height: 46.h,
                  child: ElevatedButton(
                    onPressed: () {
                      final tableNo = tableNoCtrl.text.trim();
                      if (tableNo.isNotEmpty) {
                        ref.read(restroTablesProvider.notifier).addTable(
                              tableNo: tableNo,
                              seats: seats,
                            );
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Table $tableNo added successfully!'),
                            backgroundColor: const Color(0xFF262626),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: const Color(0xFF1F1F1F),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      elevation: 0,
                    ),
                    child: const Text('Add Table', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
