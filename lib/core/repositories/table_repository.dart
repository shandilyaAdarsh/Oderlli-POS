import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../services/table_service.dart';

import '../constants/app_config.dart';
import '../../mock/restro_mock_data.dart';

class TableRepository {
  final TableService _tableService;

  // Session-based caching of floors and sections
  List<TableFloor>? _cachedFloors;
  List<TableSection>? _cachedSections;

  // Static tracking to survive repository re-creation during auth state changes
  static int _consecutive401Errors = 0;
  static bool _circuitBroken = false;
  static DateTime? _lastFailureTime;
  static bool _lastFetchFailedWith401 = false;

  TableRepository(this._tableService);

  bool get lastFetchFailedWith401 => _lastFetchFailedWith401;

  static List<TableModel> getMockTables() {
    return RestroMockData.initialTables.map((t) {
      final isBooked = t.status == 'Booked';
      return TableModel(
        id: t.id,
        tableName: t.name,
        capacity: t.seats,
        status: isBooked ? POSTableStatus.occupied : POSTableStatus.available,
        guestCount: isBooked ? t.seats : 0,
        assignedWaiterName: t.customerName,
        occupiedSince: isBooked ? DateTime.now().subtract(const Duration(minutes: 35)) : null,
        billTotal: t.currentBillTotal ?? 0.0,
        sectionName: 'Main Dining',
        floorName: 'Ground Floor',
      );
    }).toList();
  }

  static void resetCircuitBreaker({bool force = false, Ref? ref}) {
    if (!force && ref != null) {
      final user = ref.read(authProvider).user;
      if (user == null) return; // don't reset if not truly authenticated
    }
    _consecutive401Errors = 0;
    _circuitBroken = false;
    _lastFailureTime = null;
    _lastFetchFailedWith401 = false;
    debugPrint('[TableRepository] Circuit breaker reset (force=$force)');
  }

  /// Fetches floors, utilizing session cache if available.
  Future<List<TableFloor>> fetchFloors() async {
    if (_cachedFloors != null) {
      return _cachedFloors!;
    }
    try {
      final floors = await _tableService.fetchFloors();
      _cachedFloors = floors;
      return floors;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[TableRepository] fetchFloors failed: $e');
      }
      if (AppConfig.allowMockFallbackInDebug) {
        return const [
          TableFloor(
            id: 'floor-1',
            tenantId: 'mock-tenant',
            branchId: 'mock-branch',
            name: 'Ground Floor',
            sortOrder: 1,
          ),
          TableFloor(
            id: 'floor-2',
            tenantId: 'mock-tenant',
            branchId: 'mock-branch',
            name: 'First Floor',
            sortOrder: 2,
          ),
        ];
      }
      rethrow;
    }
  }

  /// Fetches sections, utilizing session cache if available.
  Future<List<TableSection>> fetchSections({String? branchId}) async {
    if (_circuitBroken) {
      throw Exception('Circuit breaker active for sections fetch due to consecutive 401 errors. Please re-authenticate or manually refresh.');
    }

    final now = DateTime.now();
    if (_lastFailureTime != null &&
        now.difference(_lastFailureTime!) < const Duration(seconds: 30)) {
      throw Exception('Retry blocked: Less than 30 seconds since last failed attempt.');
    }

    if (_cachedSections != null) {
      return _cachedSections!;
    }
    try {
      final sections = await _tableService.fetchSections(branchId: branchId);
      _consecutive401Errors = 0;
      _lastFetchFailedWith401 = false;
      _lastFailureTime = null;
      _cachedSections = sections;
      return sections;
    } catch (e) {
      _lastFailureTime = DateTime.now();
      if (e is DioException && e.response?.statusCode == 401) {
        _lastFetchFailedWith401 = true;
        _consecutive401Errors++;
        if (_consecutive401Errors >= 3) {
          _circuitBroken = true;
          debugPrint('[TableRepository] Circuit breaker activated for sections fetch after 3 consecutive 401s.');
        }
      }
      if (kDebugMode) {
        debugPrint('[TableRepository] fetchSections failed: $e');
      }
      if (AppConfig.allowMockFallbackInDebug) {
        return const [
          TableSection(
            id: 'sec-main',
            tenantId: 'mock-tenant',
            branchId: 'mock-branch',
            name: 'Main Dining',
            sortOrder: 1,
          ),
          TableSection(
            id: 'sec-outdoor',
            tenantId: 'mock-tenant',
            branchId: 'mock-branch',
            name: 'Outdoor Patio',
            sortOrder: 2,
          ),
          TableSection(
            id: 'sec-vip',
            tenantId: 'mock-tenant',
            branchId: 'mock-branch',
            name: 'VIP Lounge',
            sortOrder: 3,
          ),
        ];
      }
      rethrow;
    }
  }

  /// Fetches all active tables for the given branch and maps them to [TableModel].
  /// Enriches the tables with section and floor friendly names by resolving cached lists.
  Future<List<TableModel>> fetchTables(String branchId) async {
    try {
      // Fetch floors and sections in parallel (using cache when available)
      final results = await Future.wait([
        fetchFloors(),
        fetchSections(branchId: branchId),
        _tableService.fetchTables(branchId),
      ]);

      final floors = results[0] as List<TableFloor>;
      final sections = results[1] as List<TableSection>;
      final apiTables = results[2] as List<PosTable>;

      final floorMap = {for (final f in floors) f.id: f.name};
      final sectionMap = {for (final s in sections) s.id: s.name};

      final List<TableModel> mappedTables = [];
      for (int i = 0; i < apiTables.length; i++) {
        final t = apiTables[i];
        final sectionName = t.sectionId != null ? sectionMap[t.sectionId] : null;
        final floorName = t.floorId != null ? floorMap[t.floorId] : null;
        final json = t.toJson();

        mappedTables.add(
          TableModel(
            id: t.id,
            tableName: t.displayName ?? t.tableNumber,
            capacity: t.capacity,
            status: _mapRuntimeState(t.runtimeState),
            guestCount: (json['guest_count'] as num?)?.toInt() ?? 0,
            waiterName: null,
            assignedWaiterId: t.assignedWaiterId,
            occupiedSince: null, // Read-only from API, initialized to null if not exposed
            billTotal: 0.0,
            sectionName: sectionName,
            floorName: floorName,
            customerPaymentIntent: t.customerPaymentIntent,
          ),
        );
      }

      return mappedTables;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[TableRepository] fetchTables failed: $e');
      }
      if (AppConfig.allowMockFallbackInDebug) {
        return getMockTables();
      }
      rethrow;
    }
  }

  POSTableStatus _mapRuntimeState(String? state) {
    if (state == null) return POSTableStatus.available;
    return switch (state.toUpperCase()) {
      'FREE' => POSTableStatus.available,
      'ACTIVE_GUESTS' => POSTableStatus.occupied,
      'ORDERING' => POSTableStatus.preparing,
      'PAYMENT_PENDING' => POSTableStatus.paymentPending,
      'ASSISTANCE_REQUESTED' => POSTableStatus.ready,
      _ => POSTableStatus.available,
    };
  }



  Future<void> vacateTable(String tableId) async {
    try {
      await _tableService.vacateTable(tableId);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[TableRepository] vacateTable failed: $e');
      }
      if (AppConfig.allowMockFallbackInDebug) {
        return;
      }
      rethrow;
    }
  }
}
