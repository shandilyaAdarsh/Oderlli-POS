import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orderlli_pos/mock/restro_mock_data.dart';
import 'package:orderlli_pos/providers/restro_pos_provider.dart';
import 'package:orderlli_pos/widgets/restro_invoice_dialog.dart';

void main() {
  testWidgets('RestroInvoiceDialog renders without overflow on constrained height (600px)', (tester) async {
    // Set a constrained viewport simulating browser inner height
    tester.view.physicalSize = const Size(1024, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final mockItems = [
      RestroCartLineItem(
        item: const RestroMenuItem(
          id: 1,
          name: 'Butter Chicken Special with Naan and Rice',
          price: 450.0,
          category: 'Main Course',
          isVeg: false,
          emoji: '🍗',
        ),
        quantity: 2,
      ),
      RestroCartLineItem(
        item: const RestroMenuItem(
          id: 2,
          name: 'Paneer Tikka Masala',
          price: 320.0,
          category: 'Main Course',
          isVeg: true,
          emoji: '🧀',
        ),
        quantity: 1,
      ),
      RestroCartLineItem(
        item: const RestroMenuItem(
          id: 3,
          name: 'Garlic Naan Butter Flavour',
          price: 60.0,
          category: 'Breads',
          isVeg: true,
          emoji: '🫓',
        ),
        quantity: 4,
      ),
    ];

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(1920, 1080),
        builder: (context, child) => MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => Center(
                child: ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: ctx,
                      builder: (_) => RestroInvoiceDialog(
                        orderId: 'ORD-9876543210',
                        tableNo: 'T-04',
                        customerName: 'Rahul Sharma',
                        customerPhone: '+91 98765 43210',
                        guests: 4,
                        items: mockItems,
                        subtotal: 1460.0,
                        tax: 73.0,
                        total: 1533.0,
                        paymentMethod: 'UPI',
                      ),
                    );
                  },
                  child: const Text('Open Invoice'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // Tap button to open dialog
    await tester.tap(find.text('Open Invoice'));
    await tester.pumpAndSettle();

    // Verify dialog content is displayed
    expect(find.text('Order Receipt'), findsOneWidget);
    expect(find.text('#ORD-9876543210'), findsOneWidget);
    expect(find.text('Table → T-04'), findsOneWidget);
    expect(find.text('Rahul Sharma'), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);
    expect(find.text('Print Bill'), findsOneWidget);

    // Ensure no overflow errors occurred
    expect(tester.takeException(), isNull);
  });
}
