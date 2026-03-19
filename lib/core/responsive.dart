import 'package:flutter/material.dart';

/// Consistent spacing scale (4-pt grid).
///
/// Use [AppSpacing.xs] through [AppSpacing.xxxl] for margins, paddings, and gaps.
class AppSpacing {
  AppSpacing._();

  static const double xxs  = 2.0;
  static const double xs   = 4.0;
  static const double sm   = 8.0;
  static const double md   = 12.0;
  static const double lg   = 16.0;
  static const double xl   = 20.0;
  static const double xxl  = 24.0;
  static const double xxxl = 32.0;
  static const double huge = 48.0;
  static const double giant = 64.0;

  /// Standard screen horizontal padding.
  static const double screenH = 20.0;

  /// Standard card inner padding.
  static const EdgeInsets cardPadding = EdgeInsets.all(20);

  /// Standard screen padding.
  static const EdgeInsets screenPadding =
      EdgeInsets.symmetric(horizontal: screenH, vertical: 16);

  /// Gap widget helpers — use instead of SizedBox(height: N).
  static const SizedBox gap4   = SizedBox(height: xs);
  static const SizedBox gap8   = SizedBox(height: sm);
  static const SizedBox gap12  = SizedBox(height: md);
  static const SizedBox gap16  = SizedBox(height: lg);
  static const SizedBox gap20  = SizedBox(height: xl);
  static const SizedBox gap24  = SizedBox(height: xxl);
  static const SizedBox gap32  = SizedBox(height: xxxl);
  static const SizedBox gap48  = SizedBox(height: huge);

  /// Horizontal gap widget helpers.
  static const SizedBox hGap4  = SizedBox(width: xs);
  static const SizedBox hGap8  = SizedBox(width: sm);
  static const SizedBox hGap12 = SizedBox(width: md);
  static const SizedBox hGap16 = SizedBox(width: lg);
  static const SizedBox hGap20 = SizedBox(width: xl);
}

/// Semantic font size scale.
///
/// Prefer these over raw `fontSize` values so a single change
/// can update the whole app.
class AppFontSizes {
  AppFontSizes._();

  static const double xs    = 10.0;
  static const double sm    = 12.0;
  static const double body  = 14.0;
  static const double md    = 15.0;
  static const double lg    = 16.0;
  static const double xl    = 18.0;
  static const double xxl   = 20.0;
  static const double h3    = 22.0;
  static const double h2    = 24.0;
  static const double h1    = 28.0;
  static const double display = 32.0;
  static const double hero  = 40.0;
}

/// Border radius constants.
class AppRadius {
  AppRadius._();

  static const double xs  = 4.0;
  static const double sm  = 8.0;
  static const double md  = 12.0;
  static const double lg  = 16.0;
  static const double xl  = 20.0;
  static const double pill = 100.0;

  static const BorderRadius smAll  = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll  = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll  = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlAll  = BorderRadius.all(Radius.circular(xl));
}

/// Responsive sizing helper — scales values based on screen width.
///
/// Usage:
/// ```dart
/// final rs = ResponsiveSize.of(context);
/// Container(width: rs.sp(100), height: rs.sp(100))
/// ```
class ResponsiveSize {
  ResponsiveSize._(this._width, [this._context]);

  final double _width;
  final BuildContext? _context;

  /// Build from a [BuildContext].
  static ResponsiveSize of(BuildContext context) {
    return ResponsiveSize._(MediaQuery.sizeOf(context).width, context);
  }

  /// Whether the screen is a small phone (< 375 dp, e.g. iPhone SE, budget Androids).
  bool get isSmallPhone => _width < 375;

  /// Whether the screen is mobile (< 600).
  bool get isMobile => _width < 600;

  /// Whether the screen is a large phone (>= 414 dp, e.g. iPhone Pro Max, Galaxy Ultra).
  bool get isLargePhone => _width >= 414 && _width < 600;

  /// Whether the screen is a tablet (600 – 1199).
  bool get isTablet => _width >= 600 && _width < 1200;

  /// Whether the screen is desktop (≥ 1200).
  bool get isDesktop => _width >= 1200;

  /// Scale a value proportionally to screen width.
  /// Reference design width is 390 (iPhone 14 Pro).
  double sp(double design) => (design * _width / 390).clamp(design * 0.7, design * 1.5);

  /// Clamp-based adaptive size — returns [mobile] on small screens,
  /// [tablet] on medium, [desktop] on large.
  double adaptive({
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    if (isDesktop) return desktop ?? tablet ?? mobile;
    if (isTablet) return tablet ?? mobile;
    return mobile;
  }

  /// Minimum touch target size (48 dp per Material/Apple guidelines).
  static const double minTouchTarget = 48.0;

  /// Horizontal padding for full-width cards.
  double get screenPadding => adaptive(mobile: 20, tablet: 28, desktop: 40);

  /// Max width for content column on tablets/desktop.
  double get maxContentWidth => adaptive(mobile: double.infinity, tablet: 680, desktop: 900);

  /// Bottom safe area (accounts for gesture bar / home indicator).
  double get bottomSafeArea {
    final ctx = _context;
    if (ctx == null) return 0;
    return MediaQuery.paddingOf(ctx).bottom;
  }

  /// Bottom padding that accounts for safe area + extra spacing.
  double get bottomNavSafePadding {
    final safeBottom = bottomSafeArea;
    return safeBottom > 0 ? safeBottom : 16.0;
  }
}

