import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';
import '../config/plan_limits.dart';
import '../core/enums.dart';
import '../models/subscription_model.dart';

/// Abstraction over Stripe and Razorpay for subscription management.
///
/// All payment-related operations go through this service. The frontend
/// never talks to Stripe/Razorpay directly — it calls these methods,
/// which handle the appropriate gateway based on the gym's configuration.
class PaymentService {
  final SupabaseClient _client;

  PaymentService(this._client);

  // ─── SUBSCRIPTION QUERIES ──────────────────────────────────────────

  /// Get the current subscription for a gym.
  Future<Subscription?> getCurrentSubscription(String gymId) async {
    final data = await _client
        .from('subscriptions')
        .select()
        .eq('gym_id', gymId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    return data != null ? Subscription.fromJson(data) : null;
  }

  /// Get the plan tier for a gym (convenience shortcut).
  Future<PlanTier> getGymPlan(String gymId) async {
    final sub = await getCurrentSubscription(gymId);
    return sub?.planTier ?? PlanTier.basic;
  }

  // ─── PLAN CREATION ─────────────────────────────────────────────────

  /// Create a new subscription for a gym (initial signup).
  ///
  /// For Basic plan: no payment gateway needed.
  /// For Pro/Elite: if [withTrial] is true, starts a 14-day trial.
  Future<Subscription> createSubscription({
    required String gymId,
    required PlanTier plan,
    BillingInterval interval = BillingInterval.monthly,
    PaymentGateway gateway = PaymentGateway.none,
    bool withTrial = false,
    String? gstNumber,
  }) async {
    final now = DateTime.now();
    DateTime periodEnd;

    if (interval == BillingInterval.annual) {
      periodEnd = DateTime(now.year + 1, now.month, now.day);
    } else {
      periodEnd = DateTime(now.year, now.month + 1, now.day);
    }

    final trialEnd = withTrial && PlanLimits.trialEligible.contains(plan)
        ? now.add(const Duration(days: PlanLimits.trialDays))
        : null;

    final price = interval == BillingInterval.annual
        ? PlanLimits.annualPrice[plan]
        : PlanLimits.monthlyPrice[plan];

    final subData = {
      'gym_id': gymId,
      'plan_tier': plan.value,
      'payment_gateway': gateway.value,
      'status': withTrial ? 'trialing' : 'active',
      'billing_interval': interval.value,
      'current_period_start': now.toIso8601String(),
      'current_period_end': periodEnd.toIso8601String(),
      'is_trialing': withTrial,
      'trial_start': withTrial ? now.toIso8601String() : null,
      'trial_end': trialEnd?.toIso8601String(),
      'amount_paid': withTrial ? 0 : price,
      'currency': gateway == PaymentGateway.razorpay ? 'INR' : 'USD',
      'gst_number': gstNumber,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    };

    final data =
        await _client.from('subscriptions').insert(subData).select().single();

    // Update gym's plan_tier
    await _client
        .from('gyms')
        .update({'plan_tier': plan.value}).eq('id', gymId);

    return Subscription.fromJson(data);
  }

  // ─── PLAN CHANGES ──────────────────────────────────────────────────

  /// Upgrade or downgrade a gym's plan.
  Future<Subscription> changePlan({
    required String gymId,
    required PlanTier newPlan,
    BillingInterval? newInterval,
  }) async {
    final current = await getCurrentSubscription(gymId);
    if (current == null) {
      throw Exception('No active subscription to change');
    }

    final interval = newInterval ?? current.billingInterval;
    final price = interval == BillingInterval.annual
        ? PlanLimits.annualPrice[newPlan]
        : PlanLimits.monthlyPrice[newPlan];

    final updateData = {
      'plan_tier': newPlan.value,
      'billing_interval': interval.value,
      'amount_paid': price,
      'updated_at': DateTime.now().toIso8601String(),
    };

    final data = await _client
        .from('subscriptions')
        .update(updateData)
        .eq('id', current.id)
        .select()
        .single();

    // Update gym's plan_tier
    await _client
        .from('gyms')
        .update({'plan_tier': newPlan.value}).eq('id', gymId);

    return Subscription.fromJson(data);
  }

  /// Cancel a subscription at end of billing period.
  Future<void> cancelSubscription(String gymId) async {
    final current = await getCurrentSubscription(gymId);
    if (current == null) return;

    await _client.from('subscriptions').update({
      'status': 'cancelled',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', current.id);

    // Downgrade gym to basic
    await _client.from('gyms').update({'plan_tier': 'basic'}).eq('id', gymId);
  }

  // ─── TRIAL MANAGEMENT ──────────────────────────────────────────────

  /// Start a free trial on Pro or Elite.
  Future<Subscription> startTrial({
    required String gymId,
    required PlanTier plan,
    PaymentGateway gateway = PaymentGateway.none,
  }) async {
    if (!PlanLimits.trialEligible.contains(plan)) {
      throw Exception('${plan.label} plan is not eligible for free trial');
    }

    return createSubscription(
      gymId: gymId,
      plan: plan,
      gateway: gateway,
      withTrial: true,
    );
  }

  /// Convert trial to paid subscription.
  Future<Subscription> convertTrial({
    required String gymId,
    BillingInterval interval = BillingInterval.monthly,
  }) async {
    final current = await getCurrentSubscription(gymId);
    if (current == null || !current.isTrialing) {
      throw Exception('No active trial to convert');
    }

    final now = DateTime.now();
    final price = interval == BillingInterval.annual
        ? PlanLimits.annualPrice[current.planTier]
        : PlanLimits.monthlyPrice[current.planTier];

    final periodEnd = interval == BillingInterval.annual
        ? DateTime(now.year + 1, now.month, now.day)
        : DateTime(now.year, now.month + 1, now.day);

    final data = await _client
        .from('subscriptions')
        .update({
          'status': 'active',
          'billing_interval': interval.value,
          'is_trialing': false,
          'current_period_start': now.toIso8601String(),
          'current_period_end': periodEnd.toIso8601String(),
          'amount_paid': price,
          'updated_at': now.toIso8601String(),
        })
        .eq('id', current.id)
        .select()
        .single();

    return Subscription.fromJson(data);
  }

  // ─── OVERAGE BILLING ───────────────────────────────────────────────

  /// Record an overage charge for AI usage beyond plan limits.
  Future<void> addOverageCharge(String gymId, double amount) async {
    final current = await getCurrentSubscription(gymId);
    if (current == null) return;

    final newTotal = (current.overageCharges ?? 0) + amount;

    await _client.from('subscriptions').update({
      'overage_charges': newTotal,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', current.id);
  }

  // ─── GATEWAY DETECTION ─────────────────────────────────────────────

  /// Determine which payment gateway to use based on config and currency.
  static PaymentGateway detectGateway({String currency = 'INR'}) {
    if (currency == 'INR' && AppConfig.hasRazorpay) {
      return PaymentGateway.razorpay;
    }
    if (AppConfig.hasStripe) {
      return PaymentGateway.stripe;
    }
    return PaymentGateway.none;
  }
}
