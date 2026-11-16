import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../theme/theme.dart';
import '../providers/restro_pos_provider.dart';

class RestroInvoiceDialog extends StatelessWidget {
  final String orderId;
  final String customerName;
  final String customerPhone;
  final int guests;
  final String tableNo;
  final List<RestroCartLineItem> items;
  final double subtotal;
  final double tax;
  final double total;
  final String paymentMethod;
  final VoidCallback? onPrint;

  const RestroInvoiceDialog({
    super.key,
    required this.orderId,
    required this.customerName,
    required this.customerPhone,
    required this.guests,
    required this.tableNo,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.paymentMethod,
    this.onPrint,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final formattedDate = DateFormat('MMM dd, yyyy • hh:mm a').format(DateTime.now());
    final maxHeight = MediaQuery.sizeOf(context).height * 0.88;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      child: Container(
        width: 440.w,
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Success Check Icon
            Container(
              width: 50.r,
              height: 50.r,
              decoration: BoxDecoration(
                color: AppColors.statusReadyContainer,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.statusReady, width: 2.5),
              ),
              child: Icon(
                Icons.check,
                color: AppColors.statusReady,
                size: 26,
              ),
            ),

            Gap(10.h),

            Text(
              'Order Receipt',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Gap(2.h),
            Text(
              'Thank you for your order!',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.sp,
                color: AppColors.textSecondary,
              ),
            ),

            Gap(10.h),
            Divider(color: AppColors.border, thickness: 1),

            // Scrollable Content
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Gap(8.h),
                    // Order Metadata
                    _buildMetaRow('Order ID:', '#$orderId'),
                    _buildMetaRow('Date & Time:', formattedDate),
                    _buildMetaRow('Table:', 'Table → $tableNo'),
                    _buildMetaRow('Customer:', customerName.isEmpty ? 'Walk-in Guest' : customerName),
                    if (customerPhone.isNotEmpty) _buildMetaRow('Phone:', customerPhone),
                    _buildMetaRow('Guests:', '$guests Person'),

                    Gap(10.h),
                    Divider(color: AppColors.border, thickness: 1),
                    Gap(10.h),

                    // Items Ordered List
                    Text(
                      'Items Ordered',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Gap(8.h),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => Gap(6.h),
                      itemBuilder: (context, i) {
                        final line = items[i];
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${line.item.name} × ${line.quantity}',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13.sp,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            Gap(8.w),
                            Text(
                              currencyFormat.format(line.totalPrice),
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    Gap(10.h),
                    Divider(color: AppColors.border, thickness: 1),
                    Gap(10.h),

                    // Bills breakdown
                    _buildAmountRow('Subtotal', currencyFormat.format(subtotal)),
                    _buildAmountRow('Tax (GST 5%)', currencyFormat.format(tax)),
                    Gap(6.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Grand Total',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          currencyFormat.format(total),
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),

                    Gap(10.h),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Payment Mode:',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12.sp,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            paymentMethod,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.statusReady,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Gap(6.h),
                  ],
                ),
              ),
            ),

            Gap(10.h),
            Divider(color: AppColors.border, thickness: 1),
            Gap(12.h),

            // Actions (Pinned at bottom)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                    child: Text(
                      'Close',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                Gap(16.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (onPrint != null) {
                        onPrint!();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Receipt sent to thermal POS printer.'),
                            backgroundColor: AppColors.textPrimary,
                          ),
                        );
                      }
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.print, size: 18),
                        Gap(8.w),
                        Text(
                          'Print Bill',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12.sp,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13.sp,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
