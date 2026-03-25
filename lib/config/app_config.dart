import 'package:flutter_dotenv/flutter_dotenv.dart';

/// App-wide configuration loaded from environment variables.
class AppConfig {
  static String get supabaseUrl =>
      dotenv.env['SUPABASE_URL'] ?? 'https://your-project.supabase.co';

  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  static String get supabaseServiceRoleKey =>
      dotenv.env['SUPABASE_SERVICE_ROLE_KEY'] ?? '';

  static String get stripePublishableKey =>
      dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? '';

  static String get stripeSecretKey => dotenv.env['STRIPE_SECRET_KEY'] ?? '';

  static String get razorpayKeyId => dotenv.env['RAZORPAY_KEY_ID'] ?? '';

  static String get razorpayKeySecret =>
      dotenv.env['RAZORPAY_KEY_SECRET'] ?? '';

  static String get sentryDsn => dotenv.env['SENTRY_DSN'] ?? '';

  static String get resendApiKey => dotenv.env['RESEND_API_KEY'] ?? '';

  static String get pineconeApiKey => dotenv.env['PINECONE_API_KEY'] ?? '';
  static String get pineconeHost => dotenv.env['PINECONE_HOST'] ?? '';

  // Claude legacy key (no longer used for primary AI flows).
  static String get claudeApiKey => dotenv.env['CLAUDE_API_KEY'] ?? '';

  // NVIDIA-hosted Kimi API key (primary AI provider).
  static String get nvidiaApiKey =>
      dotenv.env['NVIDIA_API_KEY'] ?? dotenv.env['KIMI_API_KEY'] ?? '';

  // Alias for Kimi key compatibility.
  static String get kimiApiKey => nvidiaApiKey;

  static String get googleWebClientId =>
      dotenv.env['GOOGLE_WEB_CLIENT_ID'] ?? '';

  /// Whether we're running with valid Supabase credentials.
  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty &&
      !supabaseUrl.contains('your-project');

  /// Whether Stripe is configured.
  static bool get hasStripe => stripePublishableKey.isNotEmpty;

  /// Whether Razorpay is configured (Indian market).
  static bool get hasRazorpay => razorpayKeyId.isNotEmpty;
}
