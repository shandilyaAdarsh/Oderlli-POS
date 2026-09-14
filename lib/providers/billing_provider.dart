import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/billing_service.dart';
import 'auth_provider.dart';

final billingServiceProvider = Provider<BillingService>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return BillingService(dioClient);
});
