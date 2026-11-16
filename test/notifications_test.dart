import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orderlli_pos/models/models.dart';
import 'package:orderlli_pos/providers/providers.dart';
import 'package:orderlli_pos/widgets/restro_notifications_dialog.dart';

void main() {
  test('PosNotificationsNotifier adds, marks read, and clears notifications', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notif1 = PosNotification(
      id: 'notif_1',
      title: 'New Order #1001',
      message: 'Table 4 • 2 items',
      type: PosNotificationType.newOrder,
      timestamp: DateTime.now(),
      isRead: false,
    );

    final notif2 = PosNotification(
      id: 'notif_2',
      title: 'Payment Received',
      message: 'Table 2 • ₹850 via UPI',
      type: PosNotificationType.paymentSuccess,
      timestamp: DateTime.now(),
      isRead: false,
    );

    final notifier = container.read(posNotificationsProvider.notifier);
    notifier.addNotification(notif1);
    notifier.addNotification(notif2);

    expect(container.read(posNotificationsProvider).length, 2);
    expect(container.read(unreadNotificationsCountProvider), 2);

    // Mark single as read
    notifier.markAsRead('notif_1');
    expect(container.read(unreadNotificationsCountProvider), 1);

    // Mark all as read
    notifier.markAllAsRead();
    expect(container.read(unreadNotificationsCountProvider), 0);

    // Dismiss one
    notifier.dismiss('notif_1');
    expect(container.read(posNotificationsProvider).length, 1);

    // Clear all
    notifier.clearAll();
    expect(container.read(posNotificationsProvider).isEmpty, true);
  });

  testWidgets('RestroNotificationsDialog renders notifications and handles mark-read and dismiss', (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(posNotificationsProvider.notifier).addNotification(
      PosNotification(
        id: 'test_order_alert',
        title: 'New Order #ORD-2024',
        message: 'Table 5 • 3 items • ₹1,200',
        type: PosNotificationType.newOrder,
        timestamp: DateTime.now(),
        isRead: false,
        orderId: 'ord_123',
        tableNumber: '5',
      ),
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: ScreenUtilInit(
          designSize: const Size(1920, 1080),
          builder: (context, child) => const MaterialApp(
            home: Scaffold(
              body: RestroNotificationsDialog(),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify dialog header and item
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('1 new'), findsOneWidget);
    expect(find.text('New Order #ORD-2024'), findsOneWidget);
    expect(find.text('Table 5 • 3 items • ₹1,200'), findsOneWidget);
    expect(find.text('Mark read'), findsOneWidget);

    // Tap "Mark read"
    await tester.tap(find.text('Mark read'));
    await tester.pumpAndSettle();

    expect(container.read(unreadNotificationsCountProvider), 0);
  });
}
