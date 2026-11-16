import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Checks if an incoming Sentry event should be filtered out to eliminate development noise.
bool isIgnoredSentryEvent(SentryEvent event) {
  final throwable = event.throwable;
  final throwableStr = throwable?.toString() ?? '';
  final msg = event.message?.formatted ?? '';

  // 1. Filter out synthetic verification test exceptions
  if (throwable is StateError &&
      (throwable.message.contains('Sentry verification test event') ||
          throwable.message.contains('This is test exception'))) {
    return true;
  }
  if (msg.contains('Sentry verification test event') ||
      msg.contains('This is test exception')) {
    return true;
  }

  // 2. Filter out Flutter Web hot restart/reload in-flight EngineFlutterView frame assertion:
  // "Assertion failed: org-dartlang-sdk:///lib/_engine/engine/window.dart:99:12 !isDisposed 'Trying to render a disposed EngineFlutterView.'"
  if (_isDisposedViewError(throwableStr) || _isDisposedViewError(msg)) {
    return true;
  }

  for (final exception in event.exceptions ?? <SentryException>[]) {
    final val = exception.value ?? '';
    if (val.contains('Sentry verification test event') ||
        val.contains('This is test exception') ||
        _isDisposedViewError(val)) {
      return true;
    }
  }

  return false;
}

bool _isDisposedViewError(String text) {
  if (text.isEmpty) return false;
  return text.contains('Trying to render a disposed EngineFlutterView') ||
      (text.contains('EngineFlutterView') && text.contains('isDisposed')) ||
      (text.contains('window.dart') && text.contains('!isDisposed'));
}

/// Sets up global Flutter and platform error handlers to suppress development-only
/// in-flight frame assertions during hot reload and hot restart on Flutter Web.
void setupGlobalErrorHandlers() {
  final originalOnError = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    final exceptionStr = details.exceptionAsString();
    if (_isDisposedViewError(exceptionStr)) {
      debugPrint('[FlutterWeb] Suppressed in-flight frame assertion on disposed EngineFlutterView during hot restart.');
      return;
    }
    originalOnError?.call(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    final errorStr = error.toString();
    if (_isDisposedViewError(errorStr)) {
      debugPrint('[FlutterWeb] Suppressed in-flight frame assertion on disposed EngineFlutterView in PlatformDispatcher.');
      return true;
    }
    return false;
  };
}
