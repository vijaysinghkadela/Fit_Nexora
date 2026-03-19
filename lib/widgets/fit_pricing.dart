import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/extensions.dart';
import 'glassmorphic_card.dart';

@immutable
class FitPlanPalette {
  final Color primary;
  final Color secondary;
  final bool darkOnAccent;

  const FitPlanPalette({
    required this.primary,
    required this.secondary,
    this.darkOnAccent = false,
  });

  LinearGradient get buttonGradient => LinearGradient(
        colors: [primary, secondary],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  LinearGradient surfaceGradient(BuildContext context) {
    final colors = context.fitTheme;
    return LinearGradient(
      colors: [
        primary.withOpacity(0.18),
        secondary.withOpacity(0.08),
        colors.surface.withOpacity(0.96),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  Color get onAccent => darkOnAccent ? Colors.black : Colors.white;
}

@immutable
class FitPricingFeatureData {
  final String label;
  final bool included;
  final bool emphasize;

  const FitPricingFeatureData({
    required this.label,
    this.included = true,
    this.emphasize = false,
  });
}

@immutable
class FitPricingPlanData {
  final String title;
  final String price;
  final String period;
  final String description;
  final String ctaLabel;
  final FitPlanPalette palette;
  final List<FitPricingFeatureData> features;
  final bool highlighted;
  final String? badge;

  const FitPricingPlanData({
    required this.title,
    required this.price,
    required this.period,
    required this.description,
    required this.ctaLabel,
    required this.palette,
    required this.features,
    this.highlighted = false,
    this.badge,
  });
}

@immutable
class FitComparisonRowData {
  final String label;
  final List<String> values;
  final int? highlightedIndex;

  const FitComparisonRowData({
    required this.label,
    required this.values,
    this.highlightedIndex,
  });
}

@immutable
class FitUpgradeFeatureItemData {
  final IconData icon;
  final String title;
  final String subtitle;
  final FitPlanPalette palette;
  final bool accent;

  const FitUpgradeFeatureItemData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.palette,
    this.accent = false,
  });
}

class FitPricingLandingPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final String headerActionLabel;
  final List<FitPricingPlanData> plans;
  final List<FitComparisonRowData> comparisonRows;
  final VoidCallback? onHeaderAction;
  final ValueChanged<FitPricingPlanData>? onPlanSelected;
  final Widget? billingToggle;

  const FitPricingLandingPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.headerActionLabel,
    required this.plans,
    required this.comparisonRows,
    this.onHeaderAction,
    this.onPlanSelected,
    this.billingToggle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.fitTheme;

    return Scaffold(
      backgroundColor: colors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: colors.background.withOpacity(0.9),
            surfaceTintColor: Colors.transparent,
            toolbarHeight: 76,
            titleSpacing: 20,
            title: Row(
              children: [
                _brandLockup(context),
                if (!context.isMobile) ...[
                  const Spacer(),
                  _navText(context, 'Features'),
                  const SizedBox(width: 18),
                  _navText(context, 'Pricing', active: true),
                  const SizedBox(width: 18),
                  _navText(context, 'Testimonials'),
                ],
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 20),
                child: _actionButton(
                  context,
                  label: headerActionLabel,
                  palette: const FitPlanPalette(
                    primary: Color(0xFF895AF6),
                    secondary: Color(0xFFB895FF),
                  ),
                  onTap: onHeaderAction,
                  filled: true,
                  compact: true,
                ),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  _headline(context, title),
                  const SizedBox(height: 16),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: context.isMobile ? 16 : 18,
                        height: 1.55,
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (billingToggle != null)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Center(child: billingToggle!),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 36, 20, 0),
            sliver: SliverToBoxAdapter(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 1120
                      ? 3
                      : constraints.maxWidth >= 720
                          ? 2
                          : 1;
                  final spacing = 20.0;
                  final itemWidth =
                      (constraints.maxWidth - (spacing * (columns - 1))) / columns;

                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: [
                      for (final plan in plans)
                        SizedBox(
                          width: itemWidth,
                          child: _planCard(
                            context,
                            plan: plan,
                            onTap: onPlanSelected == null
                                ? null
                                : () => onPlanSelected!(plan),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 72, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Compare features',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: context.isMobile ? 28 : 34,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                  letterSpacing: -0.8,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            sliver: SliverToBoxAdapter(
              child: _comparisonTable(context, columns: const ['Basic', 'Pro', 'Elite']),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(20, 72, 20, context.isMobile ? 88 : 48),
            sliver: SliverToBoxAdapter(
              child: _footer(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _comparisonTable(
    BuildContext context, {
    required List<String> columns,
  }) {
    final colors = context.fitTheme;
    final firstColumnWidth = context.isMobile ? 200.0 : 260.0;
    final valueColumnWidth = context.isMobile ? 150.0 : 190.0;
    final minWidth = math
        .max(
          firstColumnWidth + (valueColumnWidth * columns.length),
          context.screenSize.width - 40,
        )
        .toDouble();

    return GlassmorphicCard(
      borderRadius: 28,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: minWidth),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: colors.border)),
                ),
                child: Row(
                  children: [
                    SizedBox(width: firstColumnWidth),
                    for (final column in columns)
                      SizedBox(
                        width: valueColumnWidth,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          child: Text(
                            column,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: column == 'Elite' ? colors.brand : colors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              for (final row in comparisonRows.asMap().entries)
                Container(
                  decoration: BoxDecoration(
                    border: row.key == comparisonRows.length - 1
                        ? null
                        : Border(bottom: BorderSide(color: colors.divider)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: firstColumnWidth,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                          child: Text(
                            row.value.label,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      for (final cell in row.value.values.asMap().entries)
                        SizedBox(
                          width: valueColumnWidth,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                            child: Text(
                              cell.value,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                height: 1.45,
                                fontWeight: row.value.highlightedIndex == cell.key
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: row.value.highlightedIndex == cell.key
                                    ? colors.brand
                                    : colors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class FitPlanUpgradePage extends StatelessWidget {
  final String title;
  final String subtitle;
  final String sectionTitle;
  final FitPricingPlanData offer;
  final List<FitUpgradeFeatureItemData> featureItems;
  final String contactTitle;
  final String contactMessage;
  final String primaryActionLabel;
  final String? gymName;
  final String? gymPhone;
  final VoidCallback? onPrimaryAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final List<Widget>? actions;

  const FitPlanUpgradePage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.sectionTitle,
    required this.offer,
    required this.featureItems,
    required this.contactTitle,
    required this.contactMessage,
    required this.primaryActionLabel,
    this.gymName,
    this.gymPhone,
    this.onPrimaryAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.fitTheme;

    return Scaffold(
      backgroundColor: colors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: colors.background.withOpacity(0.92),
            surfaceTintColor: Colors.transparent,
            toolbarHeight: 76,
            leading: Navigator.of(context).canPop()
                ? IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
                  )
                : null,
            title: _brandLockup(context),
            actions: actions,
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: context.isMobile ? 34 : 44,
                      fontWeight: FontWeight.w900,
                      color: colors.textPrimary,
                      letterSpacing: -1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 620),
                    child: Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: context.isMobile ? 15 : 17,
                        height: 1.55,
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: _planCard(context, plan: offer, onTap: onPrimaryAction),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 36, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Text(
                sectionTitle,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: colors.textMuted,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            sliver: SliverToBoxAdapter(
              child: GlassmorphicCard(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      for (final item in featureItems.asMap().entries) ...[
                        _upgradeItem(context, item.value),
                        if (item.key != featureItems.length - 1)
                          Divider(color: colors.divider, height: 1),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(20, 28, 20, context.isMobile ? 56 : 40),
            sliver: SliverToBoxAdapter(
              child: _contactCard(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactCard(BuildContext context) {
    final colors = context.fitTheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: offer.palette.surfaceGradient(context),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: offer.palette.primary.withOpacity(0.38)),
        boxShadow: [
          BoxShadow(
            color: offer.palette.primary.withOpacity(0.14),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: offer.palette.buttonGradient,
              borderRadius: BorderRadius.circular(18),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.storefront_rounded, color: offer.palette.onAccent, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            contactTitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            gymName ?? 'Your gym',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          if (gymPhone != null && gymPhone!.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              gymPhone!,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            contactMessage,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              height: 1.55,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              _actionButton(
                context,
                label: primaryActionLabel,
                palette: offer.palette,
                onTap: onPrimaryAction,
                filled: true,
              ),
              if (secondaryActionLabel != null && onSecondaryAction != null)
                _actionButton(
                  context,
                  label: secondaryActionLabel!,
                  palette: offer.palette,
                  onTap: onSecondaryAction,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

Widget _brandLockup(BuildContext context) {
  final colors = context.fitTheme;

  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF895AF6), Color(0xFFB895FF)],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
      ),
      const SizedBox(width: 10),
      Text(
        'FitNexora',
        style: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: colors.textPrimary,
          letterSpacing: -0.5,
        ),
      ),
    ],
  );
}

Widget _headline(BuildContext context, String text) {
  final colors = context.fitTheme;

  return ShaderMask(
    shaderCallback: (bounds) => LinearGradient(
      colors: [colors.textPrimary, colors.brand],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ).createShader(bounds),
    blendMode: BlendMode.srcIn,
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: GoogleFonts.inter(
        fontSize: context.isMobile ? 40 : 60,
        fontWeight: FontWeight.w900,
        letterSpacing: -2,
        height: 1.05,
      ),
    ),
  );
}

Widget _navText(BuildContext context, String label, {bool active = false}) {
  final colors = context.fitTheme;
  return Text(
    label,
    style: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: active ? FontWeight.w800 : FontWeight.w600,
      color: active ? colors.brand : colors.textSecondary,
    ),
  );
}

Widget _actionButton(
  BuildContext context, {
  required String label,
  required FitPlanPalette palette,
  VoidCallback? onTap,
  bool filled = false,
  bool compact = false,
}) {
  final colors = context.fitTheme;

  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(compact ? 999 : 18),
      child: Ink(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 18 : 20,
          vertical: compact ? 10 : 14,
        ),
        decoration: BoxDecoration(
          gradient: filled ? palette.buttonGradient : null,
          color: filled ? null : colors.surface.withOpacity(0.8),
          borderRadius: BorderRadius.circular(compact ? 999 : 18),
          border: Border.all(color: filled ? Colors.transparent : colors.border),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: compact ? 13 : 14,
            fontWeight: FontWeight.w800,
            color: filled ? palette.onAccent : colors.textPrimary,
          ),
        ),
      ),
    ),
  );
}

Widget _planCard(
  BuildContext context, {
  required FitPricingPlanData plan,
  VoidCallback? onTap,
}) {
  final colors = context.fitTheme;

  return Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      gradient: plan.highlighted ? plan.palette.surfaceGradient(context) : null,
      color: plan.highlighted ? null : colors.surface.withOpacity(0.72),
      borderRadius: BorderRadius.circular(28),
      border: Border.all(
        color: plan.highlighted
            ? plan.palette.primary.withOpacity(0.7)
            : colors.border,
        width: plan.highlighted ? 1.8 : 1,
      ),
      boxShadow: [
        BoxShadow(
          color: (plan.highlighted ? plan.palette.primary : colors.glow)
              .withOpacity(0.18),
          blurRadius: plan.highlighted ? 34 : 24,
          offset: const Offset(0, 18),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.title,
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: plan.highlighted
                          ? plan.palette.primary
                          : colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Text(
                          plan.price,
                          style: GoogleFonts.inter(
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            color: colors.textPrimary,
                            letterSpacing: -1.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 7),
                        child: Text(
                          plan.period,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    plan.description,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      height: 1.55,
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (plan.badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  gradient: plan.palette.buttonGradient,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  plan.badge!,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: plan.palette.onAccent,
                    letterSpacing: 1,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 24),
        _actionButton(
          context,
          label: plan.ctaLabel,
          palette: plan.palette,
          onTap: onTap,
          filled: plan.highlighted,
        ),
        const SizedBox(height: 22),
        for (final item in plan.features.asMap().entries) ...[
          _featureRow(context, plan: plan, feature: item.value),
          if (item.key != plan.features.length - 1) const SizedBox(height: 16),
        ],
      ],
    ),
  );
}

Widget _featureRow(
  BuildContext context, {
  required FitPricingPlanData plan,
  required FitPricingFeatureData feature,
}) {
  final colors = context.fitTheme;
  final iconColor = feature.included ? plan.palette.primary : colors.textMuted;

  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 1),
        child: Icon(
          feature.included ? Icons.check_circle_rounded : Icons.cancel_outlined,
          size: 20,
          color: iconColor,
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          feature.label,
          style: GoogleFonts.inter(
            fontSize: 14,
            height: 1.45,
            fontWeight: feature.emphasize ? FontWeight.w700 : FontWeight.w500,
            color: feature.included ? colors.textPrimary : colors.textMuted,
            decoration: feature.included
                ? TextDecoration.none
                : TextDecoration.lineThrough,
          ),
        ),
      ),
    ],
  );
}

Widget _upgradeItem(BuildContext context, FitUpgradeFeatureItemData item) {
  final colors = context.fitTheme;

  return ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    leading: Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        gradient: item.accent ? item.palette.buttonGradient : null,
        color: item.accent ? null : item.palette.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Icon(
        item.icon,
        size: 20,
        color: item.accent ? item.palette.onAccent : item.palette.primary,
      ),
    ),
    title: Text(
      item.title,
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: colors.textPrimary,
      ),
    ),
    subtitle: Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        item.subtitle,
        style: GoogleFonts.inter(
          fontSize: 12.5,
          height: 1.45,
          color: colors.textSecondary,
        ),
      ),
    ),
  );
}

Widget _footer(BuildContext context) {
  final colors = context.fitTheme;

  return Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: colors.surface.withOpacity(0.72),
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: colors.border),
    ),
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      runSpacing: 24,
      spacing: 24,
      children: [
        SizedBox(
          width: context.isMobile ? context.screenSize.width - 88 : 260,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _brandLockup(context),
              const SizedBox(height: 12),
              Text(
                'Reimagining fitness operations with elegant AI-first tooling.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  height: 1.55,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        _footerColumn(context, 'Product', const ['Features', 'Integrations', 'AI Docs']),
        _footerColumn(context, 'Company', const ['About', 'Roadmap', 'Careers']),
        _footerColumn(context, 'Legal', const ['Privacy', 'Terms', 'Contact']),
      ],
    ),
  );
}

Widget _footerColumn(BuildContext context, String title, List<String> items) {
  final colors = context.fitTheme;

  return SizedBox(
    width: 150,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: colors.brand,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        for (final item in items.asMap().entries) ...[
          Text(
            item.value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
            ),
          ),
          if (item.key != items.length - 1) const SizedBox(height: 8),
        ],
      ],
    ),
  );
}
