import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'config/app_config.dart';
import 'services/notification_service.dart';
import 'widgets/error_widgets.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'dart:ui';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Catch all async unhandled errors so app doesn't silently crash
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Global Async Error: $error');
    if (AppConfig.sentryDsn.isNotEmpty) {
      Sentry.captureException(error, stackTrace: stack);
    }
    return true; // prevent app from crashing immediately
  };

  // ── Lock to portrait on phones ──
  try {
    await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    ]);
  } catch (e) {
    debugPrint('[Initialization] setPreferredOrientations failed: $e');
  }

  // ── Edge-to-edge system UI ──
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
    systemNavigationBarDividerColor: Colors.transparent,
  ));

  // ── Image cache limits (RAM optimisation for 4–6 GB devices) ──
  PaintingBinding.instance.imageCache.maximumSize = 50;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 50 << 20; // 50 MB

  // Note: GoogleFonts runtime fetching is kept enabled because the Inter font
  // is not bundled in assets/fonts/. It will be cached after first download.

  try {
    await dotenv.load(fileName: 'assets/app.env');
  } catch (error) {
    debugPrint('[Initialization] Unable to load assets/app.env: $error');
  }

  if (AppConfig.hasSupabase) {
    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        anonKey: AppConfig.supabaseAnonKey,
      );
    } catch (e) {
      debugPrint('[Initialization] Supabase init failed: $e');
    }
  } else {
    debugPrint('[Initialization] Skipping Supabase: Missing credentials.');
    FlutterNativeSplash.remove();
    runApp(
      const MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'CRITICAL ERROR:\n\nMissing SUPABASE_URL or SUPABASE_ANON_KEY in assets/app.env.\nPlease verify your environment configuration and rebuild.',
                  style: TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return;
  }

  // ── Local notifications ──
  try {
    await NotificationService.init();
  } catch (e) {
    debugPrint('[Initialization] NotificationService init failed: $e');
  }

  // ── Remove native splash screen ──
  FlutterNativeSplash.remove();

  if (AppConfig.sentryDsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        options.dsn = AppConfig.sentryDsn;
        options.tracesSampleRate = 1.0;
        // ignore: experimental_member_use
        options.profilesSampleRate = 1.0;
      },
      appRunner: () => runApp(
        SentryWidget(
          child: const AppErrorBoundary(
            child: ProviderScope(
              child: FitNexoraApp(),
            ),
          ),
        ),
      ),
    );
  } else {
    runApp(
      const AppErrorBoundary(
        child: ProviderScope(
          child: FitNexoraApp(),
        ),
      ),
    );
  }
}
