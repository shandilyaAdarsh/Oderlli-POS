import 'package:flutter/material.dart';

enum PosNotificationType {
  newOrder,
  billRequested,
  paymentSuccess,
  tableAlert,
  systemAlert,
}

class PosNotification {
  final String id;
  final String title;
  final String message;
  final PosNotificationType type;
  final DateTime timestamp;
  final bool isRead;
  final String? orderId;
  final String? tableNumber;

  const PosNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.orderId,
    this.tableNumber,
  });

  PosNotification copyWith({
    String? id,
    String? title,
    String? message,
    PosNotificationType? type,
    DateTime? timestamp,
    bool? isRead,
    String? orderId,
    String? tableNumber,
  }) {
    return PosNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      orderId: orderId ?? this.orderId,
      tableNumber: tableNumber ?? this.tableNumber,
    );
  }

  IconData get icon {
    switch (type) {
      case PosNotificationType.newOrder:
        return Icons.restaurant_menu_rounded;
      case PosNotificationType.billRequested:
        return Icons.receipt_long_rounded;
      case PosNotificationType.paymentSuccess:
        return Icons.check_circle_outline_rounded;
      case PosNotificationType.tableAlert:
        return Icons.table_restaurant_rounded;
      case PosNotificationType.systemAlert:
        return Icons.info_outline_rounded;
    }
  }

  Color get iconColor {
    switch (type) {
      case PosNotificationType.newOrder:
        return const Color(0xFF60A5FA); // Blue
      case PosNotificationType.billRequested:
        return const Color(0xFFFBBF24); // Amber
      case PosNotificationType.paymentSuccess:
        return const Color(0xFF4ADE80); // Green
      case PosNotificationType.tableAlert:
        return const Color(0xFFFB923C); // Orange
      case PosNotificationType.systemAlert:
        return const Color(0xFFA78BFA); // Purple
    }
  }

  Color get iconBgColor {
    switch (type) {
      case PosNotificationType.newOrder:
        return const Color(0xFF1E293B);
      case PosNotificationType.billRequested:
        return const Color(0xFF2E2415);
      case PosNotificationType.paymentSuccess:
        return const Color(0xFF143022);
      case PosNotificationType.tableAlert:
        return const Color(0xFF332014);
      case PosNotificationType.systemAlert:
        return const Color(0xFF281C38);
    }
  }
}
