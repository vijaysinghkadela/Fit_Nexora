import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'config/app_config.dart';
import 'services/notification_service.dart';
import 'widgets/error_widgets.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Image cache limits (RAM optimisation for 4–6 GB devices) ──
  PaintingBinding.instance.imageCache.maximumSize = 50;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 50 << 20; // 50 MB

  // ── Prevent runtime Google Fonts fetching after first run ──
  GoogleFonts.config.allowRuntimeFetching = false;

  try {
    await dotenv.load(fileName: '.env');
  } catch (error) {
    debugPrint('Unable to load .env: $error');
  }

  if (AppConfig.hasSupabase) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
  }

  // ── Local notifications ──
  await NotificationService.init();

  runApp(
    const AppErrorBoundary(
      child: ProviderScope(
        child: GymOSApp(),
      ),
    ),
  );
}
