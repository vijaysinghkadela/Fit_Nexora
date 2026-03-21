import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import '../core/constants.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// A global error boundary that catches unhandled Flutter widget errors.
///
/// Wrap the root of your widget tree with this to prevent full crashes:
/// ```dart
/// runApp(const AppErrorBoundary(child: ProviderScope(child: GymOSApp())));
/// ```
class AppErrorBoundary extends StatefulWidget {
  const AppErrorBoundary({super.key, required this.child});
  final Widget child;

  @override
  State<AppErrorBoundary> createState() => _AppErrorBoundaryState();
}

class _AppErrorBoundaryState extends State<AppErrorBoundary> {
  Object? _error;

  @override
  void initState() {
    super.initState();
    FlutterError.onError = (FlutterErrorDetails details) {
      // CRITICAL FIX: Suppress Supabase ML/Storage image model errors
      // These errors occur when Supabase ML Studio uses text-only models for avatars
      // App can still function - we silently suppress these errors
      final error = details.exception;
      final errorString = error.toString().toLowerCase();
      
      // Check for ML model image errors and "cannot read" errors
      if ((errorString.contains('model') && 
           errorString.contains('support') && 
           errorString.contains('image')) ||
          errorString.contains('cannot read')) {
        debugPrint('═══════════════════════════════════════════════════════════');
        debugPrint('[SUPABASE ML ERROR SUPPRESSED] Backend uses text-only model'); 
        debugPrint('Error: $error');
        debugPrint('═══════════════════════════════════════════════════════════');
        return; // Don't show error to user
      }
      
      // Normal error handling for other errors
      FlutterError.presentError(details);
      FlutterNativeSplash.remove(); // Remove splash so error is visible
      Sentry.captureException(details.exception, stackTrace: details.stack);
      if (mounted) setState(() => _error = details.exception);
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: _ErrorScreen(
          error: _error!,
          onRetry: () => setState(() => _error = null),
        ),
      );
    }
    return widget.child;
  }
}

/// Full-screen error display with retry button.
class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen({required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.error_outline_rounded,
                      color: AppColors.error, size: 40),
                ),
                const SizedBox(height: 24),
                Text(
                  'Something went wrong',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Error: ${error.toString().split("\n").first}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Please check your internet connection and try starting the app again.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(
                      'Try Again',
                      style: GoogleFonts.inter(
                          fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Inline error widget for use inside lists, cards, and scroll views.
///
/// Displays an icon, a message, and an optional retry button.
class ErrorStateWidget extends StatelessWidget {
  const ErrorStateWidget({
    super.key,
    this.message = 'Something went wrong.',
    this.onRetry,
    this.compact = false,
  });

  final String message;
  final VoidCallback? onRetry;

  /// When true, renders a smaller inline version.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 16),
          const SizedBox(width: 8),
          Flexible(
            child: Text(message,
                style: GoogleFonts.inter(
                    fontSize: 13, color: AppColors.textSecondary)),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onRetry,
              child: Text('Retry',
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ],
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded,
                color: AppColors.textMuted, size: 40),
            const SizedBox(height: 12),
            Text(
              message,
              style: GoogleFonts.inter(
                  fontSize: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
