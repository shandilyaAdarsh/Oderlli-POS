import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../theme/theme.dart';
import '../mock/restro_mock_data.dart';
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

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 24.h),
      child: Container(
        width: 440.w,
        decoration: BoxDecoration(
          color: const Color(0xFF262626),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: const Color(0xFF383838)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: EdgeInsets.all(28.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Success Check Icon
            Container(
              width: 54.r,
              height: 54.r,
              decoration: BoxDecoration(
                color: const Color(0xFF2E4A40),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF22C55E), width: 3),
              ),
              child: const Icon(
                Icons.check,
                color: Color(0xFF22C55E),
                size: 28,
              ),
            ),

            Gap(16.h),

            Text(
              'Order Receipt',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 22.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFF5F5F5),
              ),
            ),
            Gap(4.h),
            Text(
              'Thank you for your order!',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13.sp,
                color: const Color(0xFFABABAB),
              ),
            ),

            Gap(20.h),
            const Divider(color: Color(0xFF383838), thickness: 1),
            Gap(12.h),

            // Order Metadata
            _buildMetaRow('Order ID:', '#$orderId'),
            _buildMetaRow('Date & Time:', formattedDate),
            _buildMetaRow('Table:', 'Table → $tableNo'),
            _buildMetaRow('Customer:', customerName.isEmpty ? 'Walk-in Guest' : customerName),
            if (customerPhone.isNotEmpty) _buildMetaRow('Phone:', customerPhone),
            _buildMetaRow('Guests:', '$guests Person'),

            Gap(16.h),
            const Divider(color: Color(0xFF383838), thickness: 1),
            Gap(12.h),

            // Items Ordered List
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Items Ordered',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFF5F5F5),
                ),
              ),
            ),
            Gap(8.h),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 180.h),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: items.length,
                separatorBuilder: (_, __) => Gap(6.h),
                itemBuilder: (context, i) {
                  final line = items[i];
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${line.item.name} × ${line.quantity}',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13.sp,
                          color: const Color(0xFFABABAB),
                        ),
                      ),
                      Text(
                        currencyFormat.format(line.totalPrice),
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFF5F5F5),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            Gap(16.h),
            const Divider(color: Color(0xFF383838), thickness: 1),
            Gap(12.h),

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
                    color: const Color(0xFFF5F5F5),
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

            Gap(12.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: const Color(0xFF1F1F1F),
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
                      color: const Color(0xFFABABAB),
                    ),
                  ),
                  Text(
                    paymentMethod,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF22C55E),
                    ),
                  ),
                ],
              ),
            ),

            Gap(24.h),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF383838)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                    ),
                    child: Text(
                      'Close',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFABABAB),
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
                          const SnackBar(
                            content: Text('Receipt sent to thermal POS printer.'),
                            backgroundColor: Color(0xFF262626),
                          ),
                        );
                      }
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: const Color(0xFF1F1F1F),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 14.h),
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
              color: const Color(0xFFABABAB),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFF5F5F5),
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
              color: const Color(0xFFABABAB),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFF5F5F5),
            ),
          ),
        ],
      ),
    );
  }
}
