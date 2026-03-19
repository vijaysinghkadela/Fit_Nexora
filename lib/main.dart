import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'config/app_config.dart';
import 'services/notification_service.dart';
import 'widgets/error_widgets.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Lock to portrait on phones ──
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

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

  // ── Prevent runtime Google Fonts fetching after first run ──
  GoogleFonts.config.allowRuntimeFetching = false;

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
    debugPrint('[Initialization] Skipping Supabase: Missing credentials in app.env');
  }

  // ── Local notifications ──
  await NotificationService.init();

  // ── Remove native splash screen ──
  FlutterNativeSplash.remove();

  if (AppConfig.sentryDsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        options.dsn = AppConfig.sentryDsn;
        options.tracesSampleRate = 1.0;
        options.profilesSampleRate = 1.0;
      },
      appRunner: () => runApp(
        SentryWidget(
          child: const AppErrorBoundary(
            child: ProviderScope(
              child: GymOSApp(),
            ),
          ),
        ),
      ),
    );
  } else {
    runApp(
      const AppErrorBoundary(
        child: ProviderScope(
          child: GymOSApp(),
        ),
      ),
    );
  }
}
