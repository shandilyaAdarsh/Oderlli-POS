import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../constants/app_config.dart';
import '../../providers/providers.dart';

class RealtimeSyncService with WidgetsBindingObserver {
  // Native WebSocket transport
  WebSocketChannel? _wsChannel;
  StreamSubscription? _wsSubscription;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  bool _isDisposed = false;
  final Set<String> _processedEventIds = {};

  // Supabase fallback channel (mobile/desktop if configured)
  RealtimeChannel? _supabaseChannel;

  String? _lastBranchId;
  Ref? _lastRef;

  RealtimeSyncService() {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_lastBranchId != null && _lastRef != null) {
        debugPrint('[RealtimeSyncService] App resumed. Re-establishing realtime sync & fetching orders...');
        _lastRef!.read(ordersProvider.notifier).fetchOrders();
        _lastRef!.read(posTablesProvider.notifier).refreshTables();
        subscribe(_lastBranchId!, _lastRef!);
      }
    }
  }

  void subscribe(String branchId, Ref ref) {
    _lastBranchId = branchId;
    _lastRef = ref;

    _disconnect();

    if (AppConfig.allowMockFallbackInDebug) {
      debugPrint('[RealtimeSyncService] Mock mode active. Realtime sync skipped.');
      return;
    }

    debugPrint('[RealtimeSyncService] Subscribing to realtime for branch: $branchId');

    // 1. Primary: Native Backend WebSocket connection
    _connectNativeWebSocket(branchId, ref);

    // 2. Secondary: Supabase fallback if initialized and non-web
    _initSupabaseFallback(branchId, ref);
  }

  Future<void> _connectNativeWebSocket(String branchId, Ref ref) async {
    if (_isDisposed) return;
    _cancelReconnectTimer();

    try {
      final secureStorage = ref.read(secureStorageProvider);
      final runtimeToken = await secureStorage.getRuntimeToken();
      final creds = await secureStorage.getCredentials();
      final authToken = runtimeToken ?? creds['accessToken'];

      if (authToken == null || authToken.isEmpty) {
        debugPrint('[RealtimeSyncService] No auth token available yet. Retrying in 3s...');
        _scheduleReconnect();
        return;
      }

      final wsUrl = Uri.parse('${AppConfig.websocketUrl}?branchId=$branchId');
      debugPrint('[RealtimeSyncService] Connecting to WebSocket: $wsUrl');

      final channel = WebSocketChannel.connect(wsUrl, protocols: [authToken]);
      await channel.ready;

      _wsChannel = channel;
      _reconnectAttempts = 0;
      debugPrint('[RealtimeSyncService] Native WebSocket connected successfully for branch: $branchId');

      // Refresh orders immediately upon connection to sync any missed state
      ref.read(ordersProvider.notifier).fetchOrders();
      ref.read(posTablesProvider.notifier).refreshTables();

      _startHeartbeat();

      _wsSubscription = _wsChannel!.stream.listen(
        (data) => _onWebSocketMessage(data, ref),
        onError: (err) {
          debugPrint('[RealtimeSyncService] WebSocket error: $err');
          _scheduleReconnect();
        },
        onDone: () {
          debugPrint('[RealtimeSyncService] WebSocket closed.');
          _scheduleReconnect();
        },
        cancelOnError: false,
      );
    } catch (e) {
      debugPrint('[RealtimeSyncService] Failed to establish native WebSocket: $e');
      _scheduleReconnect();
    }
  }

  void _onWebSocketMessage(dynamic rawData, Ref ref) {
    try {
      final Map<String, dynamic> data = rawData is String
          ? jsonDecode(rawData) as Map<String, dynamic>
          : jsonDecode(utf8.decode(rawData as List<int>)) as Map<String, dynamic>;

      final type = data['type'] as String?;
      if (type == 'pong') {
        return;
      }
      if (type == 'server_ping') {
        _wsChannel?.sink.add(jsonEncode({'type': 'pong'}));
        return;
      }

      final eventId = (data['event_id'] ?? data['idempotencyKey'] ?? data['id']) as String?;
      if (eventId != null && eventId.isNotEmpty) {
        if (_processedEventIds.contains(eventId)) {
          debugPrint('[RealtimeSyncService] Duplicate event screened: $eventId');
          return;
        }
        _processedEventIds.add(eventId);
        if (_processedEventIds.length > 500) {
          _processedEventIds.remove(_processedEventIds.first);
        }
      }

      final eventType = (data['event_type'] ?? data['type']) as String?;
      final streamType = data['stream_type'] as String?;
      debugPrint('[RealtimeSyncService] Event received: eventType=$eventType streamType=$streamType');

      // Refresh orders & tables on any relevant operational or alert event
      if (eventType == 'order_update' ||
          eventType == 'order_assigned' ||
          eventType == 'ORDER_ACCEPTED' ||
          eventType == 'ORDER_READY_FOR_PICKUP' ||
          eventType == 'ORDER_PREPARING' ||
          eventType == 'TABLE_WAITER_ASSIGNED' ||
          streamType == 'OPERATIONAL_STREAM' ||
          streamType == 'ALERT_STREAM' ||
          streamType == 'ORDER_ALERTS') {
        debugPrint('[RealtimeSyncService] Triggering realtime orders & tables refresh.');
        ref.read(ordersProvider.notifier).fetchOrders();
        ref.read(posTablesProvider.notifier).refreshTables();
      }
    } catch (e) {
      debugPrint('[RealtimeSyncService] Error parsing WebSocket message: $e');
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (_wsChannel != null) {
        try {
          _wsChannel!.sink.add(jsonEncode({'type': 'ping'}));
        } catch (_) {}
      }
    });
  }

  void _scheduleReconnect() {
    if (_isDisposed) return;
    _heartbeatTimer?.cancel();
    _wsSubscription?.cancel();
    _wsSubscription = null;
    _wsChannel = null;

    _reconnectAttempts++;
    final delaySeconds = _reconnectAttempts > 4 ? 15 : _reconnectAttempts * 2;
    debugPrint('[RealtimeSyncService] Scheduling reconnect attempt $_reconnectAttempts in ${delaySeconds}s');

    _cancelReconnectTimer();
    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      if (_lastBranchId != null && _lastRef != null) {
        _connectNativeWebSocket(_lastBranchId!, _lastRef!);
      }
    });
  }

  void _cancelReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  void _initSupabaseFallback(String branchId, Ref ref) {
    if (kIsWeb) return;
    try {
      _supabaseChannel = Supabase.instance.client
          .channel('pos:branch:$branchId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'orders',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'branch_id',
              value: branchId,
            ),
            callback: (payload) {
              debugPrint('[RealtimeSyncService] Supabase fallback: changes detected on orders.');
              ref.read(ordersProvider.notifier).fetchOrders();
            },
          );

      _supabaseChannel?.subscribe();
    } catch (e) {
      debugPrint('[RealtimeSyncService] Supabase fallback not initialized: $e');
    }
  }

  void _disconnect() {
    _cancelReconnectTimer();
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;

    _wsSubscription?.cancel();
    _wsSubscription = null;

    try {
      _wsChannel?.sink.close();
    } catch (_) {}
    _wsChannel = null;

    if (_supabaseChannel != null) {
      try {
        _supabaseChannel!.unsubscribe();
      } catch (_) {}
      _supabaseChannel = null;
    }
  }

  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _disconnect();
  }
}

final realtimeSyncServiceProvider = Provider<RealtimeSyncService>((ref) {
  final service = RealtimeSyncService();
  ref.onDispose(() => service.dispose());
  return service;
});
