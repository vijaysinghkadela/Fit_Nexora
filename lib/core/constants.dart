import 'package:flutter/material.dart';

/// App-wide constants.
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'FitNexora';
  static const String appTagline = 'AI-Powered Fitness Operations';
  static const String appVersion = '0.1.0';

  // Supabase Table Names
  static const String profilesTable = 'profiles';
  static const String gymsTable = 'gyms';
  static const String gymMembersTable = 'gym_members';
  static const String clientsTable = 'clients';
  static const String membershipsTable = 'memberships';
  static const String subscriptionsTable = 'subscriptions';
  static const String aiUsageTable = 'ai_usage';
  static const String gymCheckinsTable = 'gym_checkins';
  static const String foodLogsTable = 'food_logs';
  static const String workoutPlansTable = 'workout_plans';
  static const String dietPlansTable = 'diet_plans';
  static const String progressCheckInsTable = 'progress_checkins';
  static const String announcementsTable = 'gym_announcements';
  static const String occupancyView = 'gym_current_occupancy';
  static const String equipmentStatusTable = 'equipment_status';

  // Storage Buckets
  static const String avatarsBucket = 'avatars';
  static const String gymLogosBucket = 'gym-logos';
  static const String progressPhotosBucket = 'progress-photos';

  // Limits
  static const int basicMaxClients = 50;
  static const int proMaxClients = 200;
  static const int basicMaxTrainers = 1;
  static const int proMaxTrainers = 5;

  // Animation Durations & Curves
  static const Duration microAnimation = Duration(milliseconds: 150);
  static const Duration fastAnimation = Duration(milliseconds: 250);
  static const Duration normalAnimation = Duration(milliseconds: 400);
  static const Duration slowAnimation = Duration(milliseconds: 700);

  static const Curve bouncyCurve = Curves.elasticOut;
  static const Curve smoothCurve = Curves.easeInOutQuart;
  static const Curve snappyCurve = Curves.easeOutExpo;

  // Breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;
}

/// App color palette — Power & Performance (Electric Orange + Slate Charcoal).
class AppColors {
  AppColors._();

  // Primary brand colors — Electric Orange
  static const Color primary = Color(0xFFFF5C00);
  static const Color primaryLight = Color(0xFFFF8A3D);
  static const Color primaryDark = Color(0xFFCC4200);

  // Accent — Electric Teal
  static const Color accent = Color(0xFF00E5C3);
  static const Color accentLight = Color(0xFF4DFAE8);
  static const Color accentDark = Color(0xFF00A890);

  // Backgrounds — warm charcoal (slate)
  static const Color bgDark = Color(0xFF0C0C0E);
  static const Color bgCard = Color(0xFF1A1A1E);
  static const Color bgElevated = Color(0xFF222228);
  static const Color bgInput = Color(0xFF141416);

  // Text — neutral
  static const Color textPrimary = Color(0xFFF5F5F5);
  static const Color textSecondary = Color(0xFFAAAAAA);
  static const Color textMuted = Color(0xFF666672);

  // Status
  static const Color success = Color(0xFF22D48A);
  static const Color warning = Color(0xFFFFB830);
  static const Color error = Color(0xFFFF4A6B);
  static const Color info = Color(0xFF4A9FFF);

  // Borders & Dividers
  static const Color border = Color(0xFF2E2E38);
  static const Color divider = Color(0xFF1E1E24);

  // Glassmorphism — orange-tinted for P&P identity
  static const Color glassBg = Color(0x26FF5C00);
  static const Color glassBorder = Color(0x33FF5C00);

  // Outer Glows
  static const Color primaryGlow = Color(0x55FF5C00);
  static const Color accentGlow = Color(0x4000E5C3);
}
