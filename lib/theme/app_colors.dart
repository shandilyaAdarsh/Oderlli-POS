import 'package:flutter/material.dart';

/// ─── Orderlyy POS · Colour System (Light Theme) ──────────────────────────────
///
/// Light operational palette designed for:
///  • High-contrast clean white and off-white surfaces for modern restaurant environments
///  • Financial clarity (unambiguous positive / negative / neutral signals)
///  • Signature Amber / Gold branding with sharp typography
///
/// Usage: AppColors.surface, AppColors.profit, AppColors.ready …
abstract final class AppColors {
  // ── Base backgrounds ────────────────────────────────────────────────────────
  /// Main app background — #F4F5F7
  static const Color background = Color(0xFFF4F5F7);

  /// Primary card and surface — #FFFFFF
  static const Color surface = Color(0xFFFFFFFF);

  /// Elevated surface, hover states — #F8F9FA
  static const Color surfaceElevated = Color(0xFFF8F9FA);

  /// Active button and tab highlight — #EDF0F2
  static const Color surfaceVariant = Color(0xFFEDF0F2);

  /// Overlay tint — hover, pressed states
  static const Color surfaceOverlay = Color(0x0D000000);

  // ── Sidebar & Header ────────────────────────────────────────────────────────
  static const Color sidebarBg = Color(0xFFFFFFFF);
  static const Color sidebarSurface = Color(0xFFF8F9FA);
  static const Color sidebarActive = Color(0xFFF6B100);
  static const Color sidebarActiveBg = Color(0xFFFFF8E7);
  static const Color sidebarText = Color(0xFF6B7280);
  static const Color sidebarTextActive = Color(0xFF111827);
  static const Color sidebarDivider = Color(0xFFE5E7EB);

  // ── Brand / Primary (Signature Gold / Amber #F6B100) ─────────────────────────
  static const Color primary = Color(0xFFF6B100);
  static const Color primaryLight = Color(0xFFFFD54F);
  static const Color primaryDark = Color(0xFFD49700);
  static const Color primaryContainer = Color(0xFFFEF3C7);

  // ── Financial colours ────────────────────────────────────────────────────────
  /// Revenue, positive delta, successful payment
  static const Color profit = Color(0xFF16A34A);
  static const Color profitDim = Color(0xFF15803D);
  static const Color profitContainer = Color(0xFFDCFCE7);

  /// Refund, negative delta, loss, discount warning
  static const Color loss = Color(0xFFDC2626);
  static const Color lossDim = Color(0xFFB91C1C);
  static const Color lossContainer = Color(0xFFFEE2E2);

  /// Neutral amount, pending payment, tax line
  static const Color neutral = Color(0xFF2563EB);
  static const Color neutralDim = Color(0xFF1D4ED8);
  static const Color neutralContainer = Color(0xFFDBEAFE);

  /// Cash tender
  static const Color cash = Color(0xFFD97706);
  static const Color cashContainer = Color(0xFFFEF3C7);

  // ── Operational status colours ────────────────────────────────────────────────
  /// Table / order: awaiting action
  static const Color statusPending = Color(0xFFD97706);
  static const Color statusPendingContainer = Color(0xFFFEF3C7);

  /// Kitchen actively working on order (Preparing)
  static const Color statusPreparing = Color(0xFFD97706);
  static const Color statusPreparingContainer = Color(0xFFFEF3C7);

  /// Order ready, waiting to be picked up / served (Ready - Green)
  static const Color statusReady = Color(0xFF16A34A);
  static const Color statusReadyContainer = Color(0xFFDCFCE7);

  /// Order delivered to table
  static const Color statusServed = Color(0xFF2563EB);
  static const Color statusServedContainer = Color(0xFFDBEAFE);

  /// Void / cancelled
  static const Color statusCancelled = Color(0xFFDC2626);
  static const Color statusCancelledContainer = Color(0xFFFEE2E2);

  // ── Table status colours ──────────────────────────────────────────────────────
  static const Color tableAvailable = Color(0xFFD97706);
  static const Color tableOccupied = Color(0xFF16A34A);
  static const Color tableReserved = Color(0xFF2563EB);
  static const Color tableCleaning = Color(0xFF3B82F6);
  static const Color tableBlocked = Color(0xFF9CA3AF);

  // ── Semantic system colours ──────────────────────────────────────────────────
  static const Color success = Color(0xFF16A34A);
  static const Color successContainer = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFD97706);
  static const Color warningContainer = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFDC2626);
  static const Color errorContainer = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF2563EB);
  static const Color infoContainer = Color(0xFFDBEAFE);

  // ── Operational States ────────────────────────────────────────────────────────
  static const Color preparing = Color(0xFFD97706);
  static const Color ready = Color(0xFF16A34A);
  static const Color pending = Color(0xFFD97706);
  static const Color delayed = Color(0xFFDC2626);
  static const Color occupied = Color(0xFF16A34A);
  static const Color available = Color(0xFFD97706);

  // ── Financial States ──────────────────────────────────────────────────────────
  static const Color paid = Color(0xFF16A34A);
  static const Color unpaid = Color(0xFFDC2626);
  static const Color partialPaid = Color(0xFFD97706);
  static const Color refunded = Color(0xFF4F46E5);

  // ── Sync States ───────────────────────────────────────────────────────────────
  static const Color syncing = Color(0xFF0284C7);
  static const Color reconnecting = Color(0xFFEA580C);
  static const Color offline = Color(0xFF9CA3AF);

  // ── Text ─────────────────────────────────────────────────────────────────────
  /// Primary readable text — sharp dark slate
  static const Color textPrimary = Color(0xFF111827);

  /// Secondary / supporting text — neutral slate
  static const Color textSecondary = Color(0xFF4B5563);

  /// Tertiary / captions, placeholders
  static const Color textTertiary = Color(0xFF9CA3AF);

  /// Disabled state text
  static const Color textDisabled = Color(0xFFD1D5DB);

  /// Text on coloured containers (primary buttons, badges)
  static const Color textOnPrimary = Color(0xFF111827);
  static const Color textOnDark = Color(0xFFF9FAFB);
  static const Color textOnSuccess = Color(0xFFFFFFFF);
  static const Color textOnWarning = Color(0xFF111827);

  // ── Borders & dividers ───────────────────────────────────────────────────────
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderSubtle = Color(0xFFF3F4F6);
  static const Color borderFocus = Color(0xFFF6B100);
  static const Color divider = Color(0xFFE5E7EB);

  // ── Shadows ──────────────────────────────────────────────────────────────────
  static const Color shadowDeep = Color(0x14000000);    // 8% black
  static const Color shadowMedium = Color(0x0F000000);  // 6% black
  static const Color shadowLight = Color(0x08000000);   // 3% black
  static const Color glowPrimary = Color(0x26F6B100);
  static const Color glowSuccess = Color(0x2616A34A);
}
