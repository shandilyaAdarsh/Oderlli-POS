import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:orderlli_pos/core/utils/sentry_filter.dart';

void main() {
  group('isIgnoredSentryEvent', () {
    test('filters out test verification StateError', () {
      final event = SentryEvent(
        throwable: StateError('Sentry verification test event: ping'),
      );
      expect(isIgnoredSentryEvent(event), isTrue);
    });

    test('filters out test verification formatted message', () {
      final event = SentryEvent(
        message: SentryMessage('This is test exception dispatched for verification'),
      );
      expect(isIgnoredSentryEvent(event), isTrue);
    });

    test('filters out EngineFlutterView disposed assertion from throwable', () {
      final event = SentryEvent(
        throwable: AssertionError(
          'Assertion failed: org-dartlang-sdk:///lib/_engine/engine/window.dart:99:12 !isDisposed "Trying to render a disposed EngineFlutterView."',
        ),
      );
      expect(isIgnoredSentryEvent(event), isTrue);
    });

    test('filters out EngineFlutterView disposed assertion from SentryException list', () {
      final event = SentryEvent(
        exceptions: [
          SentryException(
            type: 'AssertionError',
            value: 'Trying to render a disposed EngineFlutterView.',
          ),
        ],
      );
      expect(isIgnoredSentryEvent(event), isTrue);
    });

    test('filters out window.dart !isDisposed assertion message', () {
      final event = SentryEvent(
        message: SentryMessage(
          'Assertion failed: org-dartlang-sdk:///lib/_engine/engine/window.dart:99:12\n!isDisposed',
        ),
      );
      expect(isIgnoredSentryEvent(event), isTrue);
    });

    test('retains genuine production exceptions', () {
      final event = SentryEvent(
        throwable: Exception('Database connection failed'),
        message: SentryMessage('Payment gateway timeout at /checkout/payment'),
        exceptions: [
          SentryException(
            type: 'HttpException',
            value: '500 Internal Server Error',
          ),
        ],
      );
      expect(isIgnoredSentryEvent(event), isFalse);
    });
  });

  group('setupGlobalErrorHandlers', () {
    test('suppresses disposed EngineFlutterView FlutterError', () {
      setupGlobalErrorHandlers();

      var reported = false;
      final originalOnError = FlutterError.onError;
      addTearDown(() => FlutterError.onError = originalOnError);
      FlutterError.onError = (details) {
        reported = true;
      };

      setupGlobalErrorHandlers();

      FlutterError.reportError(
        FlutterErrorDetails(
          exception: AssertionError(
            'Assertion failed: org-dartlang-sdk:///lib/_engine/engine/window.dart:99:12 !isDisposed "Trying to render a disposed EngineFlutterView."',
          ),
        ),
      );

      expect(reported, isFalse);
    });
  });
}
