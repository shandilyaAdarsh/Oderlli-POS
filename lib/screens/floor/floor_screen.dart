import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../theme/theme.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';
import '../../core/extensions/extensions.dart';
import '../../providers/inactivity_provider.dart';

class FloorScreen extends ConsumerStatefulWidget {
  const FloorScreen({super.key});

  @override
  ConsumerState<FloorScreen> createState() => _FloorScreenState();
}

class _FloorScreenState extends ConsumerState<FloorScreen> {
  Timer? _refreshTimer;

  void _startRefreshTimer(int seconds) {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(Duration(seconds: seconds), (_) {
      if (mounted) {
        final repo = ref.read(tableRepositoryProvider);
        if (repo.lastFetchFailedWith401) {
          debugPrint('[FloorScreen] Skipping refresh poll cycle because the last attempt failed with 401.');
          return;
        }
        ref.read(posTablesProvider.notifier).refreshTables();
        ref.read(ordersProvider.notifier).fetchOrders();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    final initialSeconds = ref.read(posSettingsProvider).autoRefreshInterval;
    _startRefreshTimer(initialSeconds);
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    ref.listen<int>(
      posSettingsProvider.select((s) => s.autoRefreshInterval),
      (previous, next) {
        if (next != previous) {
          _startRefreshTimer(next);
        }
      },
    );

    final tables = ref.watch(liveTableStatusProvider);
    // Filter by selected section (mirrors posFilteredTablesProvider logic but on enriched tables)
    final selectedSection = ref.watch(posSelectedSectionProvider);
    final counterTable = ref.watch(counterTableProvider);
    final filteredTables = selectedSection == null
        ? tables.where((t) => t.id != counterTable?.id).toList()
        : tables.where((t) => t.sectionName == selectedSection && t.id != counterTable?.id).toList();

    // sections is watched to allow posTableSectionsProvider to rebuild on change
    ref.watch(posTableSectionsProvider);
    // Calculate operational summary stats dynamically
    final allTables = tables; // liveTableStatusProvider already returns all tables enriched
    final occupiedCount = allTables.where((t) => t.status == POSTableStatus.occupied).length;
    final preparingCount = allTables.where((t) => t.status == POSTableStatus.preparing).length;
    final readyCount = allTables.where((t) => t.status == POSTableStatus.ready).length;
    final activeOrdersCount = occupiedCount + preparingCount + readyCount;

    final paymentPendingCount = allTables.where((t) => t.status == POSTableStatus.paymentPending).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── 1. Top Bar & Section Filter ────────────────────────────────────
          Container(
            height: 72.h,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Text('Floor Overview', style: AppTextStyles.headlineMedium),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
                  tooltip: 'Refresh Floor Plan',
                  onPressed: () {
                    ref.read(posTablesProvider.notifier).refreshTables();
                    ref.read(inactivityServiceProvider).resetTimer();
                  },
                ),
                Gap(16.w),
                const StatusChip(label: 'LIVE FLOORS', color: AppColors.success),
              ],
            ),
          ),

          // ── 2. Top Operational Summary Bar ─────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              color: AppColors.sidebarBg,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: context.isVerticalLayout ? 12.w : 16.w,
              vertical: 12.h,
            ),
            child: Row(
              children: [
                Expanded(
                  child: _SummaryIndicator(
                    label: 'Occupied Tables',
                    value: '$occupiedCount',
                    icon: Icons.table_bar,
                    color: AppColors.primary,
                  ),
                ),
                Gap(context.isVerticalLayout ? 8.w : 16.w),
                Expanded(
                  child: _SummaryIndicator(
                    label: 'Payment Pending',
                    value: '$paymentPendingCount',
                    icon: Icons.pending_actions,
                    color: AppColors.cash,
                  ),
                ),
                Gap(context.isVerticalLayout ? 8.w : 16.w),
                Expanded(
                  child: _SummaryIndicator(
                    label: 'Active Kitchen Orders',
                    value: '$activeOrdersCount',
                    icon: Icons.restaurant,
                    color: AppColors.statusPreparing,
                  ),
                ),
              ],
            ),
          ),


          Expanded(
            child: _buildGrid(filteredTables),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(List<TableModel> tables) {
    final allTablesAsync = ref.watch(posTablesProvider);

    if (allTablesAsync.isLoading && (allTablesAsync.valueOrNull ?? []).isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
        ),
      );
    }

    if (allTablesAsync.hasError) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.r),
          child: EmptyStateWidget(
            icon: Icons.wifi_off_outlined,
            title: 'Connection Error',
            description: 'Failed to fetch tables from the server. Please check your connection.\n${allTablesAsync.error}',
          ),
        ),
      );
    }

    if (tables.isEmpty) {
      return const Center(
        child: EmptyStateWidget(
          icon: Icons.table_restaurant_outlined,
          title: 'No Tables Configured',
          description: 'No tables found for this branch in the selected section.',
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width > 1600
            ? 5
            : (width > 1200
                ? 4
                : (width > 900
                    ? 3
                    : 2));
        final childAspectRatio = context.isVerticalLayout
            ? (width > 600 ? 1.42 : 1.50)
            : (width > 1200 ? 1.32 : 1.38);

        return GridView.builder(
          padding: EdgeInsets.all(16.r),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12.w,
            mainAxisSpacing: 12.h,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: tables.length,
          itemBuilder: (context, i) {
            final table = tables[i];
            return POSTableCard(
              table: table,
              isSelected: false,
              onTap: () {},
            );
          },
        );
      },
    );
  }


}


class _SummaryIndicator extends StatelessWidget {
  const _SummaryIndicator({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMD.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.12),
            radius: 18.r,
            child: Icon(icon, color: color, size: 18.sp),
          ),
          Gap(12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w800),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
