import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../routes/app_routes.dart';
import '../../providers/active_bill_provider.dart';
import '../../providers/pos_cart_provider.dart';
import '../../providers/table_provider.dart';
import '../../models/pos_models.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';

class TableSelectionScreen extends ConsumerWidget {
  const TableSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tablesAsync = ref.watch(posTablesProvider);
    final tables = tablesAsync.valueOrNull ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Select Table'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select a Dining Table', style: AppTextStyles.titleLarge),
            SizedBox(height: 12.h),
            Expanded(
              child: tablesAsync.isLoading && tables.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : tablesAsync.hasError
                      ? Center(
                          child: Text(
                            'Failed to load tables: ${tablesAsync.error}',
                            style: AppTextStyles.bodyMedium,
                          ),
                        )
                      : tables.isEmpty
                          ? const Center(
                              child: EmptyStateWidget(
                                icon: Icons.table_restaurant_outlined,
                                title: 'No Tables',
                                description: 'No tables configured for this branch.',
                              ),
                            )
                          : GridView.builder(
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 12.w,
                                mainAxisSpacing: 12.h,
                                childAspectRatio: 1.3,
                              ),
                              itemCount: tables.length,
                              itemBuilder: (context, index) {
                                final table = tables[index];
                                final counterTable = ref.read(counterTableProvider);
                                if (counterTable != null && table.id == counterTable.id) {
                                  return const SizedBox.shrink();
                                }
                                return POSTableCard(
                                  table: table,
                                  isSelected: false,
                                  onTap: () {
                                    if (table.status != POSTableStatus.available) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Table is not available for a new order.')),
                                      );
                                      return;
                                    }
                                    ref.read(cartSelectedTableProvider.notifier).state = table.id;
                                    ref.read(activeTableIdProvider.notifier).state = table.id;
                                    context.push(AppRoutes.customerDetails);
                                  },
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
