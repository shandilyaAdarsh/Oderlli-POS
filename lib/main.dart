import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'routes/app_router.dart';
import 'theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'core/constants/app_config.dart';
import 'widgets/widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Disable runtime Google Fonts network fetching — all fonts are bundled locally.
  GoogleFonts.config.allowRuntimeFetching = false;

  // Force landscape for tablet POS
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Hide status / navigation bars for full-screen POS experience
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Initialize Supabase only when not in mock fallback mode and not running on Web
  if (!AppConfig.allowMockFallbackInDebug && !kIsWeb) {
    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        // ignore: deprecated_member_use
        anonKey: AppConfig.supabaseAnonKey,
      );
    } catch (e, stack) {
      debugPrint('[Main] Supabase initialization failed: $e\n$stack');
    }
  }

  // If SENTRY_DSN is provided, initialize Sentry telemetry & error monitoring
  if (AppConfig.sentryDsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        options.dsn = AppConfig.sentryDsn;
        options.sendDefaultPii = true;
        options.tracesSampleRate = 1.0;
        options.profilesSampleRate = 1.0;
        options.replay.sessionSampleRate = 0.1;
        options.replay.onErrorSampleRate = 1.0;
        options.enableLogs = true;
        options.environment = kReleaseMode ? 'production' : 'development';
      },
      appRunner: () => runApp(
        SentryWidget(
          child: const ProviderScope(
            child: OrderlyyApp(),
          ),
        ),
      ),
    );
  } else {
    runApp(
      const ProviderScope(
        child: OrderlyyApp(),
      ),
    );
  }
}

class OrderlyyApp extends ConsumerWidget {
  const OrderlyyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return ScreenUtilInit(
      // Design canvas matches a 10-inch tablet in landscape
      designSize: const Size(
        AppConstants.designWidth,
        AppConstants.designHeight,
      ),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return InactivityScope(
          child: MaterialApp.router(
            title: 'Restro POS',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.dark,
            darkTheme: AppTheme.dark,
            themeMode: ThemeMode.dark,
            routerConfig: router,
            builder: (context, child) {
              final mediaQueryData = MediaQuery.of(context);
              // Clamp text scaling: prevents Windows 125%/150% DPI from
              // breaking POS layouts while still supporting mild accessibility scaling.
              final clampedTextScaler = mediaQueryData.textScaler.clamp(
                minScaleFactor: 0.85,
                maxScaleFactor: 1.10,
              );
              return MediaQuery(
                data: mediaQueryData.copyWith(textScaler: clampedTextScaler),
                child: child!,
              );
            },
          ),
        );
      },
    );
  }
}
