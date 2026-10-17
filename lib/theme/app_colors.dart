import 'package:flutter/material.dart';

/// ─── Orderlyy POS · Colour System ───────────────────────────────────────────
///
/// Light operational palette designed for:
///  • High-contrast light surfaces for modern restaurant environments
///  • Financial clarity (unambiguous positive / negative / neutral signals)
///  • 24-hour operational readability with Action Orange and white surfaces
///
/// Usage: AppColors.surface, AppColors.profit, AppColors.ready …
abstract final class AppColors {
  // ── Base backgrounds (Matching Restaurant_POS_System) ───────────────────────
  /// Main app background — #1f1f1f
  static const Color background = Color(0xFF1F1F1F);

  /// Primary card and surface — #262626
  static const Color surface = Color(0xFF262626);

  /// Elevated surface, hover states — #2c2c2c
  static const Color surfaceElevated = Color(0xFF2C2C2C);

  /// Active button and tab highlight — #343434 / #383838
  static const Color surfaceVariant = Color(0xFF343434);

  /// Overlay tint — hover, pressed states
  static const Color surfaceOverlay = Color(0x1AFFFFFF);

  // ── Sidebar & Header (Matching Restro Top & Bottom Navigation) ─────────────
  static const Color sidebarBg = Color(0xFF1A1A1A);
  static const Color sidebarSurface = Color(0xFF262626);
  static const Color sidebarActive = Color(0xFFF6B100);
  static const Color sidebarActiveBg = Color(0xFF343434);
  static const Color sidebarText = Color(0xFFABABAB);
  static const Color sidebarTextActive = Color(0xFFF5F5F5);
  static const Color sidebarDivider = Color(0xFF2A2A2A);

  // ── Brand / Primary (Signature Gold / Amber #F6B100) ─────────────────────────
  static const Color primary = Color(0xFFF6B100);
  static const Color primaryLight = Color(0xFFFFD54F);
  static const Color primaryDark = Color(0xFFD49700);
  static const Color primaryContainer = Color(0xFF4A452E);

  // ── Financial colours ────────────────────────────────────────────────────────
  /// Revenue, positive delta, successful payment
  static const Color profit = Color(0xFF22C55E);
  static const Color profitDim = Color(0xFF16A34A);
  static const Color profitContainer = Color(0xFF2E4A40);

  /// Refund, negative delta, loss, discount warning
  static const Color loss = Color(0xFFEF4444);
  static const Color lossDim = Color(0xFFDC2626);
  static const Color lossContainer = Color(0xFF4A2E2E);

  /// Neutral amount, pending payment, tax line, electric blue #025cca
  static const Color neutral = Color(0xFF025CCA);
  static const Color neutralDim = Color(0xFF014499);
  static const Color neutralContainer = Color(0xFF1D2569);

  /// Cash tender
  static const Color cash = Color(0xFFF6B100);
  static const Color cashContainer = Color(0xFF4A452E);

  // ── Operational status colours ────────────────────────────────────────────────
  /// Table / order: awaiting action
  static const Color statusPending = Color(0xFFF6B100);
  static const Color statusPendingContainer = Color(0xFF4A452E);

  /// Kitchen actively working on order (Preparing)
  static const Color statusPreparing = Color(0xFFF6B100);
  static const Color statusPreparingContainer = Color(0xFF4A452E);

  /// Order ready, waiting to be picked up / served (Ready - Green)
  static const Color statusReady = Color(0xFF22C55E);
  static const Color statusReadyContainer = Color(0xFF2E4A40);

  /// Order delivered to table
  static const Color statusServed = Color(0xFF025CCA);
  static const Color statusServedContainer = Color(0xFF1A2A4A);

  /// Void / cancelled
  static const Color statusCancelled = Color(0xFFEF4444);
  static const Color statusCancelledContainer = Color(0xFF4A2E2E);

  // ── Table status colours ──────────────────────────────────────────────────────
  static const Color tableAvailable = Color(0xFFF6B100); // Amber badge #664a04
  static const Color tableOccupied = Color(0xFF22C55E);  // Green badge #2e4a40 (Booked)
  static const Color tableReserved = Color(0xFF025CCA);
  static const Color tableCleaning = Color(0xFF3B82F6);
  static const Color tableBlocked = Color(0xFF6C757D);

  // ── Semantic system colours ──────────────────────────────────────────────────
  static const Color success = Color(0xFF22C55E);
  static const Color successContainer = Color(0xFF2E4A40);
  static const Color warning = Color(0xFFF6B100);
  static const Color warningContainer = Color(0xFF4A452E);
  static const Color error = Color(0xFFEF4444);
  static const Color errorContainer = Color(0xFF4A2E2E);
  static const Color info = Color(0xFF025CCA);
  static const Color infoContainer = Color(0xFF1D2569);

  // ── Operational States ────────────────────────────────────────────────────────
  static const Color preparing = Color(0xFFF6B100);
  static const Color ready = Color(0xFF22C55E);
  static const Color pending = Color(0xFFF6B100);
  static const Color delayed = Color(0xFFEF4444);
  static const Color occupied = Color(0xFF22C55E);
  static const Color available = Color(0xFFF6B100);

  // ── Financial States ──────────────────────────────────────────────────────────
  static const Color paid = Color(0xFF22C55E);
  static const Color unpaid = Color(0xFFEF4444);
  static const Color partialPaid = Color(0xFFF6B100);
  static const Color refunded = Color(0xFF6366F1);

  // ── Sync States ───────────────────────────────────────────────────────────────
  static const Color syncing = Color(0xFF0EA5E9);
  static const Color reconnecting = Color(0xFFF97316);
  static const Color offline = Color(0xFF6C757D);

  // ── Text (Matching Restaurant_POS_System #f5f5f5 & #ababab) ─────────────────
  /// Primary readable text — #f5f5f5
  static const Color textPrimary = Color(0xFFF5F5F5);

  /// Secondary / supporting text — #ababab
  static const Color textSecondary = Color(0xFFABABAB);

  /// Tertiary / captions, placeholders
  static const Color textTertiary = Color(0xFF757575);

  /// Disabled state text
  static const Color textDisabled = Color(0xFF555555);

  /// Text on coloured containers (primary buttons, badges)
  static const Color textOnPrimary = Color(0xFF1F1F1F);
  static const Color textOnDark = Color(0xFFF5F5F5);
  static const Color textOnSuccess = Color(0xFFFFFFFF);
  static const Color textOnWarning = Color(0xFF1F1F1F);

  // ── Borders & dividers ───────────────────────────────────────────────────────
  static const Color border = Color(0xFF383838);
  static const Color borderSubtle = Color(0xFF2A2A2A);
  static const Color borderFocus = Color(0xFFF6B100);
  static const Color divider = Color(0xFF2A2A2A);

  // ── Shadows ──────────────────────────────────────────────────────────────────
  static const Color shadowDeep = Color(0x40000000);    // 25% black
  static const Color shadowMedium = Color(0x28000000);  // 16% black
  static const Color shadowLight = Color(0x14000000);   // 8% black
  static const Color glowPrimary = Color(0x33F6B100);   // gold glow
  static const Color glowSuccess = Color(0x3322C55E);   // green glow
}
