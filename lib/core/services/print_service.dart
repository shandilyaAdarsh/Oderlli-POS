import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../constants/app_config.dart';
import './network_print_service.dart';
import '../../providers/providers.dart';

/// Exception thrown when printing operations fail.
class PrinterException implements Exception {
  final String message;
  const PrinterException(this.message);

  @override
  String toString() => 'PrinterException: $message';
}

/// Print service interface for POS shift audit summaries and receipts.
abstract class PrintService {
  Future<void> printXReport(ShiftSession session);
  Future<void> exportPdf(ShiftSession session);
  Future<void> printReceipt(ReceiptRequest request);
}

final printServiceProvider = Provider<PrintService>((ref) {
  final settings = ref.watch(posSettingsProvider);
  final printerIp = settings.billingPrinterIp.trim();

  // Network TCP printing requires a valid IP address and non-web environment
  final isIpAddress = RegExp(r'^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$').hasMatch(printerIp);
  if (!kIsWeb && isIpAddress) {
    return NetworkPrintService(printerIp: printerIp);
  }

  if (!kIsWeb && RegExp(r'^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$').hasMatch(AppConfig.printerIp)) {
    return NetworkPrintService(printerIp: AppConfig.printerIp);
  }

  return const MockPrintService();
});

/// Mock print service simulating hardware communication delay.
class MockPrintService implements PrintService {
  const MockPrintService();

  @override
  Future<void> printXReport(ShiftSession session) async {
    await Future.delayed(const Duration(milliseconds: 500));
    debugPrint('[MockPrintService] Printed X-Report for session ${session.shiftId}');
  }

  @override
  Future<void> exportPdf(ShiftSession session) async {
    await Future.delayed(const Duration(milliseconds: 500));
    debugPrint('[MockPrintService] Exported PDF for session ${session.shiftId}');
  }

  @override
  Future<void> printReceipt(ReceiptRequest request) async {
    await Future.delayed(const Duration(milliseconds: 600));
    debugPrint('[MockPrintService] Successfully printed receipt for Order #${request.order.orderNumber ?? request.order.id} (Total: ₹${request.amountPaid})');
  }
}
