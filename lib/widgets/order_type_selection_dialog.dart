import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../theme/theme.dart';
import '../providers/providers.dart';
import '../routes/app_routes.dart';

class OrderTypeSelectionDialog extends ConsumerWidget {
  const OrderTypeSelectionDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      backgroundColor: AppColors.surface,
      child: Container(
        width: 400.w,
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'NEW ORDER',
              style: AppTextStyles.headlineSmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            Gap(8.h),
            Text(
              'How would you like to create this order?',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            Gap(32.h),
            // TABLE ORDER
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.push('/table-selection');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 20.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Column(
                children: [
                  Icon(Icons.table_restaurant, size: 28.sp),
                  Gap(8.h),
                  Text('TABLE ORDER', style: AppTextStyles.titleMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text('Dine-in', style: AppTextStyles.labelSmall.copyWith(color: Colors.white70)),
                ],
              ),
            ),
            Gap(16.h),
            // WALK-IN ORDER
            ElevatedButton(
              onPressed: () {
                final counterTable = ref.read(counterTableProvider);
                if (counterTable != null) {
                  ref.read(activeTableIdProvider.notifier).state = counterTable.id;
                } else {
                  // Fallback: clear table selection to imply counter context
                  ref.read(activeTableIdProvider.notifier).state = null;
                }
                Navigator.pop(context);
                context.push(AppRoutes.customerDetails);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cash,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 20.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Column(
                children: [
                  Icon(Icons.storefront, size: 28.sp),
                  Gap(8.h),
                  Text('WALK-IN ORDER', style: AppTextStyles.titleMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text('Counter / Takeaway', style: AppTextStyles.labelSmall.copyWith(color: Colors.white70)),
                ],
              ),
            ),
            Gap(16.h),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'CANCEL',
                style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
