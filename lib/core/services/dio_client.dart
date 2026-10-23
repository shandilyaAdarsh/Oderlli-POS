import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../mock/restro_mock_data.dart';
import '../constants/app_config.dart';
import 'device_fingerprint_service.dart';
import 'secure_storage_service.dart';

class DioClient {
  final Dio dio;
  final SecureStorageService _secureStorage;
  final DeviceFingerprintService _fingerprintService;
  final Ref? _ref;

  // Stream controller to notify when a session has expired (true = org, false = staff)
  final _sessionExpiredController = StreamController<bool>.broadcast();
  Stream<bool> get onSessionExpired => _sessionExpiredController.stream;

  // Single-flight refresh locks
  bool _isRefreshing = false;
  Completer<String?>? _refreshCompleter;

  DioClient(
    this._secureStorage,
    this._fingerprintService, [
    this._ref,
  ]) : dio = Dio(BaseOptions(
          baseUrl: AppConfig.baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        )) {
    _initInterceptors();
  }

  void _initInterceptors() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Prevent duplicate /api/v1 when combined with baseUrl ending in /api/v1
          if (options.path.startsWith('/api/v1') &&
              (options.baseUrl.endsWith('/api/v1') || options.baseUrl.endsWith('/api/v1/'))) {
            options.path = options.path.substring(7);
          }

          // Mock fallback for offline web development
          if (AppConfig.allowMockFallbackInDebug) {
            if (options.path.contains('/auth/login')) {
              return handler.resolve(Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'success': true,
                  'data': {
                    'accessToken': 'demo-access-token-12345',
                    'refreshToken': 'demo-refresh-token-12345',
                    'deviceSessionId': 'demo-session-id-12345',
                    'user': {
                      'id': 'staff-demo-1',
                      'name': 'Amrit Maurya',
                      'role': 'manager',
                      'employeeId': 'EMP-001',
                      'email': 'admin@restropos.com',
                      'tenantId': 'tenant-demo-restro',
                    }
                  }
                },
              ));
            }
            if (options.path.contains('/tenants/current')) {
              return handler.resolve(Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'success': true,
                  'data': {
                    'id': 'tenant-demo-restro',
                    'name': 'Restro POS Demo',
                    'branches': [
                      {
                        'id': 'branch-restro-main',
                        'name': 'Restro Main Branch',
                        'address': '101 Gourmet Ave, City Center',
                        'tenantId': 'tenant-demo-restro',
                      }
                    ]
                  }
                },
              ));
            }
            if (options.path.contains('/auth/staff')) {
              return handler.resolve(Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'success': true,
                  'data': [
                    {
                      'id': 'staff-demo-1',
                      'name': 'Amrit Maurya',
                      'role': 'manager',
                      'pin': '1234',
                      'terminalId': 'term-demo-1',
                      'employeeId': 'EMP-001',
                      'email': 'admin@restropos.com',
                    }
                  ]
                },
              ));
            }
            if (options.path.contains('/admin/tables/floors')) {
              return handler.resolve(Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'success': true,
                  'data': [
                    {
                      'id': 'floor-1',
                      'tenant_id': 'tenant-demo-restro',
                      'branch_id': 'branch-restro-main',
                      'name': 'Ground Floor',
                      'sort_order': 1,
                    },
                    {
                      'id': 'floor-2',
                      'tenant_id': 'tenant-demo-restro',
                      'branch_id': 'branch-restro-main',
                      'name': 'First Floor',
                      'sort_order': 2,
                    },
                  ],
                },
              ));
            }
            if (options.path.contains('/admin/tables/sections')) {
              return handler.resolve(Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'success': true,
                  'data': [
                    {
                      'id': 'sec-main',
                      'tenant_id': 'tenant-demo-restro',
                      'branch_id': 'branch-restro-main',
                      'name': 'Main Dining',
                      'sort_order': 1,
                    },
                    {
                      'id': 'sec-outdoor',
                      'tenant_id': 'tenant-demo-restro',
                      'branch_id': 'branch-restro-main',
                      'name': 'Outdoor Patio',
                      'sort_order': 2,
                    },
                    {
                      'id': 'sec-vip',
                      'tenant_id': 'tenant-demo-restro',
                      'branch_id': 'branch-restro-main',
                      'name': 'VIP Lounge',
                      'sort_order': 3,
                    },
                  ],
                },
              ));
            }
            if (options.path.contains('/admin/tables') && options.method == 'GET') {
              final mockTablesData = RestroMockData.initialTables.map((t) => {
                'id': t.id,
                'tenant_id': 'tenant-demo-restro',
                'branch_id': 'branch-restro-main',
                'table_number': t.name,
                'display_name': t.name,
                'capacity': t.seats,
                'floor_id': 'floor-1',
                'section_id': 'sec-main',
                'sort_order': int.tryParse(t.name) ?? 1,
                'assigned_waiter_id': 'staff-demo-1',
                'notes': null,
                'is_active': true,
                'version_num': 1,
                'runtime_state': t.status.toLowerCase() == 'booked' ? 'ACTIVE_GUESTS' : 'FREE',
                'customer_payment_intent': null,
                'guest_count': t.status.toLowerCase() == 'booked' ? t.seats : 0,
              }).toList();
              return handler.resolve(Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'success': true,
                  'data': mockTablesData,
                },
              ));
            }
            if (options.path.contains('/admin/tables/') && options.method == 'POST') {
              return handler.resolve(Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'success': true,
                  'message': 'Success',
                },
              ));
            }
            if (options.path.contains('/menu/categories/tree')) {
              final categoriesData = RestroMockData.categories.map((c) => {
                'id': 'cat-${c.id}',
                'tenant_id': 'tenant-demo-restro',
                'parent_id': null,
                'name': c.name,
                'slug': c.name.toLowerCase().replaceAll(' ', '-'),
                'description': null,
                'image_url': null,
                'sort_order': c.id,
                'is_active': true,
                'version_num': 1,
                'created_at': DateTime.now().toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
                'deleted_at': null,
                'children': const [],
              }).toList();
              return handler.resolve(Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'success': true,
                  'data': categoriesData,
                },
              ));
            }
            if (options.path.contains('/menu/branch/')) {
              final List<Map<String, dynamic>> itemsData = [];
              for (final c in RestroMockData.categories) {
                for (final item in c.items) {
                  itemsData.add({
                    'id': 'item-${item.id}',
                    'tenant_id': 'tenant-demo-restro',
                    'branch_id': 'branch-restro-main',
                    'category_id': 'cat-${c.id}',
                    'name': item.name,
                    'slug': item.name.toLowerCase().replaceAll(' ', '-'),
                    'description': '${item.emoji} Delicious ${item.name}',
                    'short_description': item.name,
                    'sku': 'SKU-${item.id}',
                    'effective_price': item.price,
                    'pricing_type': 'FIXED',
                    'effective_tax_group_id': null,
                    'dietary_tags': item.isVeg ? ['vegetarian'] : ['non-vegetarian'],
                    'spice_level': 'medium',
                    'prep_time_minutes': 15,
                    'is_available': true,
                    'is_featured': true,
                    'image_url': null,
                    'thumbnail_url': null,
                    'sort_order': item.id,
                    'modifier_groups': const [],
                  });
                }
              }
              return handler.resolve(Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'success': true,
                  'data': itemsData,
                },
              ));
            }
            if (options.path.contains('/orders/checkout')) {
              return handler.resolve(Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'success': true,
                  'data': {
                    'order': {
                      'id': 'ord-${DateTime.now().millisecondsSinceEpoch}',
                      'tenant_id': 'tenant-demo-restro',
                      'branch_id': 'branch-restro-main',
                      'table_id': 't-1',
                      'table_number': 1,
                      'status': 'pending',
                      'created_at': DateTime.now().toIso8601String(),
                      'subtotal_minor': 1500,
                      'tax_total_minor': 75,
                      'discount_total_minor': 0,
                      'grand_total_minor': 1575,
                      'items': [],
                    },
                  },
                },
              ));
            }
            if (options.path.contains('/orders') && options.method == 'GET') {
              final mockOrdersData = RestroMockData.initialOrders.map((o) => {
                'id': 'ord-${o.id}',
                'order_number': 'ORD-${o.id.substring(o.id.length.clamp(0, 4))}',
                'status': o.status.toLowerCase() == 'ready'
                    ? 'ready'
                    : (o.status.toLowerCase() == 'in progress'
                        ? 'preparing'
                        : 'pending'),
                'created_at': o.dateTime.toIso8601String(),
                'table_id': 't-${o.tableNo}',
                'order_notes': 'Customer: ${o.customer}',
                'grand_total_minor': (o.total * 100).toInt(),
                'customer_payment_intent': null,
                'items': o.itemNames.map((name) => {'name': name, 'qty': 1}).toList(),
              }).toList();
              return handler.resolve(Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'success': true,
                  'data': {
                    'orders': mockOrdersData,
                  },
                },
              ));
            }
            if (options.path.contains('/billing/')) {
              return handler.resolve(Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'success': true,
                  'status': 'success',
                  'data': {
                    'projections': [],
                    'bill': {
                      'id': 'bill-demo-1',
                      'totalMinor': 1575,
                      'status': 'UNPAID',
                    },
                    'updatedBill': {
                      'id': 'bill-demo-1',
                      'status': 'PAID',
                    },
                  },
                },
              ));
            }
            if (options.path.contains('/cart')) {
              return handler.resolve(Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'success': true,
                  'data': {
                    'cart': {
                      'id': 'cart-demo-1',
                      'items': [],
                      'revision': 1,
                    },
                    'sessionId': 'session-demo-1',
                  },
                },
              ));
            }
          }

          // Inject Fingerprint header
          final fingerprint = await _fingerprintService.getOrCreateFingerprint();
          options.headers['X-Device-Fingerprint'] = fingerprint;

          // Inject tenant id if present in auth state and not already set
          if (_ref != null) {
            final authState = _ref.read(authProvider);
            if (authState.tenantId != null && !options.headers.containsKey('x-tenant-id')) {
              options.headers['x-tenant-id'] = authState.tenantId;
            }
          }

          // Inject Access/Runtime Token header (if not already set manually)
          if (!options.headers.containsKey('Authorization')) {
            final staffToken = await _secureStorage.getRuntimeToken();
            if (staffToken != null && staffToken.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $staffToken';
              debugPrint('[AUTH] STAFF RUNTIME HEADER ADDED: Bearer $staffToken');
            } else {
              final credentials = await _secureStorage.getCredentials();
              final accessToken = credentials['accessToken'];
              if (accessToken != null && accessToken.isNotEmpty) {
                options.headers['Authorization'] = 'Bearer $accessToken';
                debugPrint('[AUTH] OWNER AUTHORIZATION HEADER ADDED: Bearer $accessToken');
              } else {
                debugPrint('[AUTH] AUTHORIZATION HEADER NOT ADDED (token is null/empty)');
              }
            }
          } else {
            debugPrint('[AUTH] AUTHORIZATION HEADER PRESERVED: ${options.headers['Authorization']}');
          }

          if (kDebugMode) {
            debugPrint('--> [DIO REQUEST] ${options.method} ${options.uri}');
            debugPrint('Headers: ${options.headers}');
            if (options.data != null) {
              debugPrint('Body: ${options.data}');
            }
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            debugPrint('<-- [DIO RESPONSE] ${response.statusCode} ${response.requestOptions.uri}');
            debugPrint('Data: ${response.data}');
          }
          return handler.next(response);
        },
        onError: (DioException error, handler) async {
          if (kDebugMode) {
            debugPrint('[DIO ERROR] ${error.response?.statusCode} ${error.requestOptions.uri}');
            debugPrint('Message: ${error.message}');
            debugPrint('Response: ${error.response?.data}');
          }

          // If the request was unauthorized, attempt token refresh
          if (error.response?.statusCode == 401) {
            final path = error.requestOptions.path;

            // These endpoints return 401 for wrong credentials — that is
            // expected, not a session expiry. Pass through untouched.
            final isAuthEndpoint =
                path.contains('/auth/staff') ||
                path.contains('/auth/login') ||
                path.contains('/auth/pin');

            if (isAuthEndpoint) {
              return handler.next(error); // let it bubble as DioException
            }

            // Avoid infinite loops if refreshing fails
            if (path.contains('/auth/refresh') ||
                path.contains('/auth/login')) {
              return handler.next(error);
            }

            // Check if the 401 was caused by an expired Staff Runtime Token
            final authHeader = error.requestOptions.headers['Authorization'] as String?;
            final staffToken = await _secureStorage.getRuntimeToken();
            final isStaffToken = authHeader != null && staffToken != null && authHeader == 'Bearer $staffToken';

            if (isStaffToken) {
              // The STAFF token expired. Do not refresh the org token.
              // Clear staff token and force employee logout.
              await _secureStorage.clearRuntimeToken();
              _sessionExpiredController.add(false); // false = staff expired
              return handler.next(error);
            }

            final credentials = await _secureStorage.getCredentials();
            final refreshToken = credentials['refreshToken'];
            final deviceSessionId = credentials['deviceSessionId'];

            if (refreshToken == null || refreshToken.trim().isEmpty) {
              _triggerSessionExpired();
              return handler.next(error);
            }

            if (deviceSessionId == null) {
              _triggerSessionExpired();
              return handler.next(error);
            }

            try {
              String? newAccessToken;

              if (_isRefreshing) {
                // Another request is already refreshing. Wait for it to complete.
                newAccessToken = await _refreshCompleter?.future;
              } else {
                _isRefreshing = true;
                _refreshCompleter = Completer<String?>();

                // Trigger token refresh call
                newAccessToken = await _performRefresh(refreshToken, deviceSessionId);

                _refreshCompleter?.complete(newAccessToken);
                _isRefreshing = false;
                _refreshCompleter = null;
              }

              if (newAccessToken != null) {
                // Retry the original request with the new access token
                final options = error.requestOptions;
                options.headers['Authorization'] = 'Bearer $newAccessToken';

                final response = await dio.fetch(options);
                return handler.resolve(response);
              }
            } catch (refreshError) {
              _isRefreshing = false;
              _refreshCompleter = null;
              _triggerSessionExpired();
              return handler.next(error);
            }
          }

          return handler.next(error);
        },
      ),
    );
  }

  Future<String?> _performRefresh(String refreshToken, String deviceSessionId) async {
    try {
      final fingerprint = await _fingerprintService.getOrCreateFingerprint();
      
      // Use clean options to avoid interceptor recursion
      final refreshResponse = await Dio(BaseOptions(baseUrl: AppConfig.baseUrl)).post(
        '/auth/refresh',
        data: {
          'refresh_token': refreshToken,
          'device_fingerprint': fingerprint,
        },
        options: Options(
          headers: {
            'X-Device-Fingerprint': fingerprint,
            'X-Device-Session-Id': deviceSessionId,
          },
        ),
      );

      if (refreshResponse.statusCode == 200) {
        final data = refreshResponse.data;
        if (data != null && data['success'] == true) {
          final resData = data['data'];
          
          final newAccessToken = resData?['access_token'] as String?;
          final newRefreshToken = resData?['refresh_token'] as String?;
          final newDeviceSessionId = resData?['device_session_id'] as String?;

          if (newAccessToken == null || newRefreshToken == null || newDeviceSessionId == null) {
            throw Exception('Token response contains null values');
          }

          await _secureStorage.saveTokens(
            accessToken: newAccessToken,
            refreshToken: newRefreshToken,
            deviceSessionId: newDeviceSessionId,
          );

          return newAccessToken;
        }
      }
      throw Exception('Token refresh response status code was not 200 or success flag was false');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[DioClient] Refresh token request failed: $e');
      }
      _triggerSessionExpired();
      return null;
    }
  }

  void _triggerSessionExpired() {
    _secureStorage.clearSession();
    _sessionExpiredController.add(true); // true = org expired
  }

  void dispose() {
    _sessionExpiredController.close();
  }
}
