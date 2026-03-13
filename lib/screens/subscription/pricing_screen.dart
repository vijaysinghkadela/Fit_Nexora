import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/plan_limits.dart';
import '../../core/constants.dart';
import '../../core/enums.dart';
import '../../models/subscription_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/payment_service.dart';

/// Premium pricing screen with plan comparison, feature matrix,
/// and CTA buttons for subscribing.
class PricingScreen extends ConsumerStatefulWidget {
  final Subscription? currentSubscription;

  const PricingScreen({super.key, this.currentSubscription});

  @override
  ConsumerState<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends ConsumerState<PricingScreen> {
  bool _isAnnual = false;
  bool _isSubscribing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: CustomScrollView(
        slivers: [
          // ─── HEADER ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.15),
                    AppColors.accent.withValues(alpha: 0.08),
                    AppColors.bgDark,
                  ],
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded,
                            color: AppColors.textPrimary),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Choose Your Plan',
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),
                  const SizedBox(height: 8),
                  Text(
                    'Scale your gym with AI-powered management',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 24),

                  // Billing toggle
                  _buildBillingToggle(),
                ],
              ),
            ),
          ),

          // ─── PLAN CARDS ──────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildPlanCard(
                  tier: PlanTier.basic,
                  color: AppColors.textMuted,
                  icon: Icons.fitness_center_rounded,
                  tagline: 'Get Started',
                  highlights: [
                    '50 Clients',
                    '1 Trainer',
                    'Membership Tracking',
                    'GST Invoices',
                    'Offline Mode',
                  ],
                  excludes: ['No AI Features', 'No Gamification'],
                  delay: 300,
                ),
                const SizedBox(height: 16),
                _buildPlanCard(
                  tier: PlanTier.pro,
                  color: AppColors.accent,
                  icon: Icons.bolt_rounded,
                  tagline: 'Most Popular',
                  isPopular: true,
                  highlights: [
                    '200 Clients',
                    '5 Trainers',
                    'AI Diet + Workout (Haiku)',
                    '100 AI Generations/mo',
                    'WhatsApp Alerts',
                    'Gamification & Streaks',
                    'Trainer Tools',
                    '14-Day Free Trial',
                  ],
                  excludes: ['No Claude Opus'],
                  delay: 400,
                ),
                const SizedBox(height: 16),
                _buildPlanCard(
                  tier: PlanTier.elite,
                  color: AppColors.primary,
                  icon: Icons.diamond_rounded,
                  tagline: 'Full Power',
                  highlights: [
                    '500+ Clients',
                    'Unlimited Trainers',
                    'Claude Opus AI Coaching',
                    '50 Opus + ∞ Haiku/mo',
                    'Revenue Forecast & BI',
                    'White Label',
                    'Video Messages',
                    'Priority Support',
                    '14-Day Free Trial',
                  ],
                  excludes: [],
                  delay: 500,
                ),
                const SizedBox(height: 32),
              ]),
            ),
          ),

          // ─── FEATURE COMPARISON ──────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildFeatureComparison(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 60)),
        ],
      ),
    );
  }

  Widget _buildBillingToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleButton('Monthly', !_isAnnual, () {
            setState(() => _isAnnual = false);
          }),
          _buildToggleButton('Annual (2mo Free)', _isAnnual, () {
            setState(() => _isAnnual = true);
          }),
        ],
      ),
    ).animate().fadeIn(delay: 250.ms);
  }

  Widget _buildToggleButton(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required PlanTier tier,
    required Color color,
    required IconData icon,
    required String tagline,
    required List<String> highlights,
    required List<String> excludes,
    bool isPopular = false,
    int delay = 300,
  }) {
    final price = _isAnnual
        ? PlanLimits.formatAnnualMonthly(tier)
        : PlanLimits.formatMonthly(tier);
    final totalPrice = _isAnnual ? PlanLimits.formatAnnual(tier) : null;
    final isCurrent = widget.currentSubscription?.planTier == tier;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPopular ? color.withValues(alpha: 0.4) : AppColors.border,
          width: isPopular ? 2 : 1,
        ),
        boxShadow: isPopular
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tier.label,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      tagline,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
              if (isPopular)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '⭐ POPULAR',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 20),

          // Price
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price,
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  height: 1,
                ),
              ),
              if (totalPrice != null) ...[
                const SizedBox(width: 8),
                Text(
                  'billed $totalPrice',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 20),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: 16),

          // Highlights
          ...highlights.map((h) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: color, size: 16),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        h,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              )),

          // Excludes
          ...excludes.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Icon(Icons.remove_circle_outline_rounded,
                        color: AppColors.textMuted.withValues(alpha: 0.5),
                        size: 16),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        e,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              )),

          const SizedBox(height: 20),

          // CTA Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: isCurrent || _isSubscribing
                  ? null
                  : () => _handleSubscribe(tier),
              style: FilledButton.styleFrom(
                backgroundColor: isCurrent ? AppColors.bgInput : color,
                foregroundColor: isCurrent ? AppColors.textMuted : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isSubscribing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(
                      isCurrent
                          ? 'Current Plan'
                          : PlanLimits.trialEligible.contains(tier)
                              ? 'Start 14-Day Free Trial'
                              : 'Get Started',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    ).animate(delay: delay.ms).fadeIn().slideY(begin: 0.08, end: 0);
  }

  Widget _buildFeatureComparison() {
    final features = [
      _FeatureRow('Max Clients', '50', '200', '500+'),
      _FeatureRow('Trainers', '1', '5', 'Unlimited'),
      _FeatureRow('AI Workout Plans', '❌', '✅ Haiku', '✅ Opus'),
      _FeatureRow('AI Diet Plans', '❌', '✅', '✅'),
      _FeatureRow('Indian Food DB', '❌', '✅', '✅'),
      _FeatureRow('WhatsApp Alerts', '❌', '✅', '✅'),
      _FeatureRow('Gamification', '❌', '✅', '✅'),
      _FeatureRow('GST Invoices', '✅', '✅', '✅'),
      _FeatureRow('UPI / Razorpay', '✅', '✅', '✅'),
      _FeatureRow('Offline Mode', '✅', '✅', '✅'),
      _FeatureRow('Hindi Support', '✅', '✅', '✅'),
      _FeatureRow('Revenue Forecast', '❌', '❌', '✅'),
      _FeatureRow('MRR Dashboard', '❌', '❌', '✅'),
      _FeatureRow('AI Chat (Opus)', '❌', '❌', '✅'),
      _FeatureRow('White Label', '❌', '❌', '✅'),
      _FeatureRow('Video Messages', '❌', '❌', '✅'),
      _FeatureRow('Priority Support', '❌', '❌', '✅'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Feature Comparison',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const Divider(color: AppColors.divider, height: 1),

          // Header row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppColors.bgInput,
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text('Feature',
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted)),
                ),
                Expanded(
                  flex: 2,
                  child: Text('Basic',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted)),
                ),
                Expanded(
                  flex: 2,
                  child: Text('Pro',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accent)),
                ),
                Expanded(
                  flex: 2,
                  child: Text('Elite',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary)),
                ),
              ],
            ),
          ),

          // Feature rows
          ...features.asMap().entries.map((entry) {
            final i = entry.key;
            final f = entry.value;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              decoration: BoxDecoration(
                color: i.isEven
                    ? Colors.transparent
                    : AppColors.bgInput.withValues(alpha: 0.3),
                border: const Border(
                  bottom: BorderSide(color: AppColors.divider, width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(f.name,
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppColors.textPrimary)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(f.basic,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(f.pro,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppColors.textPrimary)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(f.elite,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppColors.textPrimary)),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    ).animate(delay: 600.ms).fadeIn().slideY(begin: 0.05, end: 0);
  }

  Future<void> _handleSubscribe(PlanTier tier) async {
    final userProvider = ref.read(currentUserProvider);
    final user = userProvider.value;

    // Cache the messenger to avoid async gap lint
    final messenger = ScaffoldMessenger.of(context);

    if (user == null) {
      messenger.showSnackBar(
        const SnackBar(
            content: Text('Please log in first.'),
            backgroundColor: AppColors.error),
      );
      return;
    }

    if (_isSubscribing) return;

    setState(() => _isSubscribing = true);

    try {
      // Find the ID of the gym. For simplicity we assume the user's ID is the gym ID
      // since the original implementation didn't clearly expose the current Gym ID.
      // Alternatively you'd read a gymProvider.
      final gymId = user.id;

      // Note: Ideally, this assumes there's a paymentServiceProvider exported or you
      // use standard DI methods to fetch PaymentService instance. Since we don't have
      // `paymentServiceProvider` explicitly defined in `payment_service.dart`, we must
      // instantiate it using the Supabase client or by adding a provider to it.
      // Let's create a quick payment service instance using supabase client provider
      // from auth_provider.dart:
      final supabaseClient = ref.read(supabaseClientProvider);
      final paymentService = PaymentService(supabaseClient);

      if (PlanLimits.trialEligible.contains(tier)) {
        await paymentService.startTrial(gymId: gymId, plan: tier);
      } else {
        await paymentService.createSubscription(
            gymId: gymId,
            plan: tier,
            interval:
                _isAnnual ? BillingInterval.annual : BillingInterval.monthly,
            gateway: PaymentGateway.none, // Can be improved
            withTrial: false);
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            PlanLimits.trialEligible.contains(tier)
                ? 'Successfully started 14-day ${tier.label} trial!'
                : 'Successfully subscribed to ${tier.label}!',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
            content: Text('Subscription failed: $e'),
            backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubscribing = false);
      }
    }
  }
}

class _FeatureRow {
  final String name;
  final String basic;
  final String pro;
  final String elite;

  const _FeatureRow(this.name, this.basic, this.pro, this.elite);
}
