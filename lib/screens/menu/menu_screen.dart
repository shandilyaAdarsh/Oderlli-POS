import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../theme/theme.dart';
import '../../mock/restro_mock_data.dart';
import '../../providers/menu_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/restro_pos_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/restro_header.dart';
import '../../widgets/restro_bottom_nav.dart';
import '../../widgets/restro_invoice_dialog.dart';

class MenuScreen extends ConsumerStatefulWidget {
  const MenuScreen({super.key});

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  int? _selectedCategoryId;
  final String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _handlePlaceOrder({
    required CustomerDetails customer,
    required List<RestroCartLineItem> cartItems,
    required double subtotal,
    required double tax,
    required double total,
    required String paymentMethod,
  }) {
    if (cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cart is empty. Please add items to place an order.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    final tableNo = customer.tableNo ?? 'Counter';
    final customerName = customer.name?.isNotEmpty == true ? customer.name! : 'Walk-in Guest';
    final customerPhone = customer.phone ?? '';
    final guests = customer.guests;
    final orderId = '${DateTime.now().millisecondsSinceEpoch}';

    // 1. Add order to Restro Orders provider
    ref.read(restroOrdersProvider.notifier).addOrder(
          customer: customerName,
          tableNo: tableNo,
          total: total,
          itemNames: cartItems.map((e) => '${e.item.name} (${e.quantity})').toList(),
        );

    // 2. Mark table as booked
    if (tableNo != 'Counter') {
      ref.read(restroTablesProvider.notifier).bookTable(
            tableNo: tableNo,
            customerName: customerName,
            customerPhone: customerPhone,
            total: total,
          );
    }

    // 3. Open Invoice Receipt Dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => RestroInvoiceDialog(
        orderId: orderId,
        customerName: customerName,
        customerPhone: customerPhone,
        guests: guests,
        tableNo: tableNo,
        items: List.of(cartItems),
        subtotal: subtotal,
        tax: tax,
        total: total,
        paymentMethod: paymentMethod,
        onPrint: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Receipt sent to thermal POS printer.'),
              backgroundColor: AppColors.textPrimary,
            ),
          );
        },
      ),
    ).then((_) {
      // 4. Clear cart and active customer
      ref.read(restroCartProvider.notifier).clear();
      ref.read(customerDetailsProvider.notifier).clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final customer = ref.watch(customerDetailsProvider);
    final cartItems = ref.watch(restroCartProvider);
    final subtotal = ref.watch(restroCartSubtotalProvider);
    final tax = ref.watch(restroCartTaxProvider);
    final total = ref.watch(restroCartTotalProvider);
    final paymentMethod = ref.watch(restroPaymentMethodProvider);

    final categoriesAsync = ref.watch(categoriesProvider);
    final menuItemsAsync = ref.watch(menuItemsProvider);

    final rawCategories = categoriesAsync.valueOrNull ?? [];
    final rawMenuItems = menuItemsAsync.valueOrNull ?? [];

    final List<RestroCategory> categories;
    if (rawMenuItems.isNotEmpty) {
      final allDishes = rawMenuItems.map((i) {
        final cat = rawCategories.where((c) => c.id == i.categoryId).firstOrNull;
        return RestroMenuItem(
          id: i.id.hashCode,
          name: i.name,
          price: i.price,
          category: cat?.name ?? 'Main',
          isVeg: i.isVegetarian,
          emoji: cat?.icon ?? '🍽️',
        );
      }).toList();

      final categoryList = rawCategories
          .map((c) {
            final items = allDishes.where((i) => i.category == c.name).toList();
            return RestroCategory(
              id: c.id.hashCode,
              name: c.name,
              bgColor: AppColors.surfaceVariant,
              icon: c.icon,
              items: items,
            );
          })
          .where((c) => c.items.isNotEmpty)
          .toList();

      categories = [
        RestroCategory(
          id: 0,
          name: 'All Dishes',
          bgColor: AppColors.surfaceVariant,
          icon: '🍽️',
          items: allDishes,
        ),
        ...categoryList,
      ];
    } else {
      categories = RestroMockData.categories;
    }

    final activeCatId = _selectedCategoryId ?? categories.first.id;
    final currentCategory = categories.firstWhere(
      (c) => c.id == activeCatId,
      orElse: () => categories.first,
    );

    final globalSearch = ref.watch(restroGlobalSearchProvider);
    final effectiveQuery = globalSearch.isNotEmpty ? globalSearch : _searchQuery;

    final allItems = currentCategory.items.where((item) {
      if (effectiveQuery.isEmpty) return true;
      return item.name.toLowerCase().contains(effectiveQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Header ──────────────────────────────────────────────────
            const RestroHeader(),

            // ── Split Menu & Billing View ───────────────────────────────────
            Expanded(
              child: Row(
                children: [
                  // ── Left: Menu Selection Panel (65%) ────────────────────────
                  Expanded(
                    flex: 65,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Subheader (Back Button, Menu Title & Customer Pill)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  InkWell(
                                    onTap: () => context.go(AppRoutes.floor),
                                    borderRadius: BorderRadius.circular(10.r),
                                    child: Container(
                                      padding: EdgeInsets.all(8.r),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceVariant,
                                        borderRadius: BorderRadius.circular(10.r),
                                      ),
                                      child: Icon(
                                        Icons.arrow_back_ios_new,
                                        color: AppColors.textPrimary,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                  Gap(16.w),
                                  Text(
                                    'Menu',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 22.sp,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),

                              // Active Customer & Table Indicator Pill
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(30.r),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.person_outline,
                                      color: AppColors.primary,
                                      size: 18,
                                    ),
                                    Gap(8.w),
                                    Text(
                                      customer.name?.isNotEmpty == true
                                          ? customer.name!
                                          : 'Walk-in Guest',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Gap(12.w),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(6.r),
                                      ),
                                      child: Text(
                                        'Table: ${customer.tableNo ?? "Counter"}',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Categories Horizontal Scroll Bar (MenuContainer.jsx)
                        SizedBox(
                          height: 52.h,
                          child: ListView.separated(
                            padding: EdgeInsets.symmetric(horizontal: 24.w),
                            scrollDirection: Axis.horizontal,
                            itemCount: categories.length,
                            separatorBuilder: (_, _) => Gap(12.w),
                            itemBuilder: (context, i) {
                              final cat = categories[i];
                              final isSelected = cat.id == activeCatId;

                              return InkWell(
                                onTap: () => setState(() => _selectedCategoryId = cat.id),
                                borderRadius: BorderRadius.circular(14.r),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.sidebarActiveBg : AppColors.surface,
                                    borderRadius: BorderRadius.circular(14.r),
                                    border: Border.all(
                                      color: isSelected ? AppColors.primary : AppColors.border,
                                    ),
                                    boxShadow: [
                                      if (isSelected)
                                        BoxShadow(
                                          color: AppColors.primary.withValues(alpha: 0.2),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Text(cat.icon, style: TextStyle(fontSize: 18.sp)),
                                      Gap(8.w),
                                      Text(
                                        cat.name,
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 13.sp,
                                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                          color: isSelected ? AppColors.sidebarActive : AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        Gap(16.h),

                        // Dish Items Grid
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24.w),
                            child: (categoriesAsync.isLoading || menuItemsAsync.isLoading)
                                ? const Center(
                                    child: CircularProgressIndicator(color: AppColors.primary),
                                  )
                                : allItems.isEmpty
                                    ? Center(
                                        child: Text(
                                          'No dishes found in ${currentCategory.name}.',
                                          style: TextStyle(color: AppColors.textSecondary),
                                        ),
                                      )
                                    : GridView.builder(
                                    padding: EdgeInsets.only(bottom: 24.h),
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      crossAxisSpacing: 16.w,
                                      mainAxisSpacing: 16.h,
                                      childAspectRatio: 1.3,
                                    ),
                                    itemCount: allItems.length,
                                    itemBuilder: (context, i) {
                                      final item = allItems[i];
                                      return _buildDishCard(item, cartItems);
                                    },
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Right: Cart & Billing Panel (35%) (CartInfo.jsx & Bill.jsx) ──
                  Expanded(
                    flex: 35,
                    child: Container(
                      margin: EdgeInsets.fromLTRB(0, 12.h, 24.w, 12.h),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: AppColors.border),
                      ),
                      padding: EdgeInsets.all(20.r),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Customer Info Section (CustomerInfo.jsx)
                          _buildCustomerInfoSection(customer),

                          Divider(color: AppColors.border, thickness: 1),
                          Gap(8.h),

                          // Cart Items Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Order Items (${cartItems.length})',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              if (cartItems.isNotEmpty)
                                TextButton(
                                  onPressed: () => ref.read(restroCartProvider.notifier).clear(),
                                  child: const Text(
                                    'Clear all',
                                    style: TextStyle(color: Color(0xFFEF4444), fontSize: 12),
                                  ),
                                ),
                            ],
                          ),

                          Gap(8.h),

                          // Scrollable Cart Items (CartInfo.jsx)
                          Expanded(
                            child: cartItems.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.shopping_bag_outlined,
                                          size: 40.sp,
                                          color: AppColors.textTertiary,
                                        ),
                                        Gap(8.h),
                                        Text(
                                          'No items in order',
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 13.sp,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.separated(
                                    itemCount: cartItems.length,
                                    separatorBuilder: (_, _) => Gap(10.h),
                                    itemBuilder: (context, i) {
                                      final line = cartItems[i];
                                      return _buildCartItemTile(line);
                                    },
                                  ),
                          ),

                          Divider(color: AppColors.border, thickness: 1),
                          Gap(10.h),

                          // Bill Summary & Taxes (Bill.jsx)
                          _buildBillSummary(subtotal, tax, total),

                          Gap(14.h),

                          // Payment Method Selector (Cash / Online / Card)
                          _buildPaymentMethodSelector(paymentMethod),

                          Gap(16.h),

                          // Place Order Button (Bill.jsx)
                          SizedBox(
                            width: double.infinity,
                            height: 50.h,
                            child: ElevatedButton(
                              onPressed: () => _handlePlaceOrder(
                                customer: customer,
                                cartItems: cartItems,
                                subtotal: subtotal,
                                tax: tax,
                                total: total,
                                paymentMethod: paymentMethod,
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                elevation: 0,
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.check_circle_outline, size: 20),
                                    Gap(8.w),
                                    Text(
                                      'Place Order & Print Bill',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 15.sp,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Bottom Navigation ───────────────────────────────────────────
            const RestroBottomNav(activePath: AppRoutes.menu),
          ],
        ),
      ),
    );
  }

  // ─── Dish Card ─────────────────────────────────────────────────────────────

  Widget _buildDishCard(RestroMenuItem item, List<RestroCartLineItem> cartItems) {
    final existingLine = cartItems.where((l) => l.item.id == item.id).firstOrNull;
    final quantity = existingLine?.quantity ?? 0;

    return Container(
      padding: EdgeInsets.all(10.r),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: quantity > 0 ? AppColors.primary : AppColors.border,
          width: quantity > 0 ? 1.5 : 1.0,
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: 190,
          height: 125,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(item.emoji, style: const TextStyle(fontSize: 20)),
                    ),
                  ),
                  // Veg / Non-Veg Indicator
                  Container(
                    width: 16,
                    height: 16,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: item.isVeg ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: item.isVeg ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),

              Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      '₹${item.price.toStringAsFixed(0)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (quantity == 0)
                    SizedBox(
                      height: 32,
                      child: ElevatedButton(
                        onPressed: () => ref.read(restroCartProvider.notifier).addItem(item),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.surfaceElevated,
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Add',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primary),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () => ref.read(restroCartProvider.notifier).decrement(item.id),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Icon(Icons.remove, size: 14, color: AppColors.primary),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              '$quantity',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () => ref.read(restroCartProvider.notifier).increment(item.id),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Icon(Icons.add, size: 14, color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Customer Info Header (CustomerInfo.jsx) ───────────────────────────────

  Widget _buildCustomerInfoSection(CustomerDetails customer) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18.r,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    customer.name?.isNotEmpty == true ? customer.name![0].toUpperCase() : 'G',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                Gap(10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.name?.isNotEmpty == true ? customer.name! : 'Guest Order',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Table ${customer.tableNo ?? "Counter"} • ${customer.guests} Person',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => context.go(AppRoutes.floor),
            icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 18),
            tooltip: 'Change Table',
          ),
        ],
      ),
    );
  }

  // ─── Cart Line Item Tile (CartInfo.jsx) ─────────────────────────────────────

  Widget _buildCartItemTile(RestroCartLineItem line) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '₹${line.item.price.toStringAsFixed(0)} each',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Stepper
          Row(
            children: [
              InkWell(
                onTap: () => ref.read(restroCartProvider.notifier).decrement(line.item.id),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: const Icon(Icons.remove, size: 14, color: AppColors.primary),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                child: Text(
                  '${line.quantity}',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              InkWell(
                onTap: () => ref.read(restroCartProvider.notifier).increment(line.item.id),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: const Icon(Icons.add, size: 14, color: AppColors.primary),
                ),
              ),
            ],
          ),
          Gap(12.w),
          Text(
            '₹${line.totalPrice.toStringAsFixed(0)}',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 16, color: Color(0xFFEF4444)),
            onPressed: () => ref.read(restroCartProvider.notifier).removeItem(line.item.id),
          ),
        ],
      ),
    );
  }

  // ─── Bill Summary Breakdown (Bill.jsx) ─────────────────────────────────────

  Widget _buildBillSummary(double subtotal, double tax, double total) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Subtotal', style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp)),
            Text('₹${subtotal.toStringAsFixed(2)}', style: TextStyle(color: AppColors.textPrimary, fontSize: 13.sp, fontWeight: FontWeight.w600)),
          ],
        ),
        Gap(4.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Tax (5%)',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12.sp),
              ),
            ),
            Text('₹${tax.toStringAsFixed(2)}', style: TextStyle(color: AppColors.textPrimary, fontSize: 12.sp)),
          ],
        ),
        Gap(8.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Total Amount', style: TextStyle(color: AppColors.textPrimary, fontSize: 16.sp, fontWeight: FontWeight.w700)),
            Text('₹${total.toStringAsFixed(2)}', style: TextStyle(color: AppColors.primary, fontSize: 18.sp, fontWeight: FontWeight.w800)),
          ],
        ),
      ],
    );
  }

  // ─── Payment Method Selector ───────────────────────────────────────────────

  Widget _buildPaymentMethodSelector(String selectedMethod) {
    const methods = ['Cash', 'Online / Card', 'UPI'];

    return Row(
      children: methods.map((method) {
        final isSelected = selectedMethod == method;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: InkWell(
              onTap: () => ref.read(restroPaymentMethodProvider.notifier).state = method,
              borderRadius: BorderRadius.circular(8.r),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: EdgeInsets.symmetric(vertical: 8.h),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Center(
                  child: Text(
                    method,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11.sp,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
