import 'package:flutter/material.dart';

/// App-wide constants.
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'GymOS';
  static const String appTagline = 'AI-Powered Gym Management';
  static const String appVersion = '0.1.0';

  // Supabase Table Names
  static const String profilesTable = 'profiles';
  static const String gymsTable = 'gyms';
  static const String gymMembersTable = 'gym_members';
  static const String clientsTable = 'clients';
  static const String membershipsTable = 'memberships';
  static const String subscriptionsTable = 'subscriptions';

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

/// App color palette — dark-first premium aesthetic.
class AppColors {
  AppColors._();

  // Primary brand colors
  static const Color primary = Color(0xFF7C3AED); // Deeper, more vibrant violet
  static const Color primaryLight = Color(0xFFA78BFA);
  static const Color primaryDark = Color(0xFF5B21B6);

  // Accent
  static const Color accent = Color(0xFF10B981); // Bright neon mint/emerald
  static const Color accentLight = Color(0xFF34D399);
  static const Color accentDark = Color(0xFF047857);

  // Backgrounds - deep, rich voids
  static const Color bgDark = Color(0xFF030712); // Extreme near black
  static const Color bgCard = Color(0xFF0F172A); // Slate-tinted card surface
  static const Color bgElevated = Color(0xFF1E293B); // Elevated surface
  static const Color bgInput = Color(0xFF161B22); // Input fields

  // Text
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF475569);

  // Status (using slightly more tailored neon shades)
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Borders & Dividers
  static const Color border = Color(0xFF1E293B);
  static const Color divider = Color(0xFF0F172A);

  // Glassmorphism - adjusting opacities for better depth
  static const Color glassBg = Color(0x0CFFFFFF); // ~5% white for deeper blur
  static const Color glassBorder = Color(0x26FFFFFF); // 15% white

  // Outer Glows
  static const Color primaryGlow = Color(0x407C3AED);
  static const Color accentGlow = Color(0x4010B981);
}
