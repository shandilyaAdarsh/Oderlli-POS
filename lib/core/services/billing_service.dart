import 'package:dio/dio.dart';
import 'dio_client.dart';

class BillingService {
  final DioClient _dioClient;

  BillingService(this._dioClient);

  /// GET /api/v1/billing/projections/table/:tableId
  Future<List<dynamic>> fetchTableProjection(String tableId) async {
    final response = await _dioClient.dio.get(
      '/api/v1/billing/projections/table/$tableId',
      options: Options(
        headers: {
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
        },
      ),
    );
    _assertSuccess(response);
    if (response.data == null) return const [];
    final data = response.data is Map ? response.data['data'] : null;
    if (data is Map<String, dynamic> && data['projections'] is List) {
      return data['projections'] as List<dynamic>;
    }
    if (data is List) {
      return data;
    }
    return const [];
  }

  /// POST /api/v1/billing/bills/aggregate
  Future<Map<String, dynamic>> aggregateOrdersIntoBill({
    required String tableId,
    required List<String> orderIds,
  }) async {
    final response = await _dioClient.dio.post(
      '/api/v1/billing/bills/aggregate',
      data: {
        'tableId': tableId,
        'orderIds': orderIds,
        'sessionId': null, // Assuming backend handles this if null
      },
    );
    _assertSuccess(response);
    final data = response.data['data'];
    if (data is Map<String, dynamic>) {
      if (data['bill'] is Map<String, dynamic>) {
        return data['bill'] as Map<String, dynamic>;
      }
      return data;
    }
    return const <String, dynamic>{};
  }

  /// GET /api/v1/billing/bills/:id
  Future<Map<String, dynamic>> getBillDetails(String billId) async {
    final response = await _dioClient.dio.get('/api/v1/billing/bills/$billId');
    _assertSuccess(response);
    final data = response.data['data'];
    if (data is Map<String, dynamic>) {
      if (data['bill'] is Map<String, dynamic>) {
        return data['bill'] as Map<String, dynamic>;
      }
      return data;
    }
    return const <String, dynamic>{};
  }

  /// POST /api/v1/billing/bills/:id/settle
  Future<Map<String, dynamic>> settleBill({
    required String billId,
    required String paymentMethod,
    required int amountMinor,
  }) async {
    final response = await _dioClient.dio.post(
      '/api/v1/billing/bills/$billId/settle',
      data: {
        'paymentMethod': paymentMethod,
        'amountMinor': amountMinor,
      },
    );
    _assertSuccess(response);
    final data = response.data['data'];
    if (data is Map<String, dynamic>) {
      if (data['updatedBill'] is Map<String, dynamic>) {
        return data['updatedBill'] as Map<String, dynamic>;
      }
      return data;
    }
    return const <String, dynamic>{};
  }

  void _assertSuccess(Response<dynamic> response) {
    if (response.data == null || (response.data['status'] != 'success' && response.data['success'] != true)) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Billing API returned an unexpected response',
      );
    }
  }
}
