import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfdropcheckoutpayment.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpaymentgateway/cfpaymentgatewayservice.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfsession/cfsession.dart';
import 'package:flutter_cashfree_pg_sdk/api/cftheme/cftheme.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfenums.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfexceptions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../config/plan_limits.dart';
import '../core/constants.dart';
import '../core/enums.dart';
import '../models/subscription_model.dart';

/// Abstraction over Stripe and Cashfree for subscription management.
///
/// All payment-related operations go through this service. The frontend
/// never talks to Stripe/Cashfree directly — it calls these methods,
/// which handle the appropriate gateway based on the gym's configuration.
class PaymentService {
  final SupabaseClient _client;

  PaymentService(this._client);

  /// Safe month-offset calculation that handles December and short-month overflow.
  static DateTime _addMonths(DateTime from, int months) {
    final newMonth = from.month + months;
    final newYear = from.year + (newMonth - 1) ~/ 12;
    final month = ((newMonth - 1) % 12) + 1;
    // Clamp day to the last day of the target month
    final maxDay = DateTime(newYear, month + 1, 0).day;
    final day = from.day > maxDay ? maxDay : from.day;
    return DateTime(newYear, month, day);
  }

  // ─── SUBSCRIPTION QUERIES ──────────────────────────────────────────

  /// Get the current subscription for a gym.
  Future<Subscription?> getCurrentSubscription(String gymId) async {
    final data = await _client
        .from(AppConstants.subscriptionsTable)
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
      periodEnd = _addMonths(now, 12);
    } else {
      periodEnd = _addMonths(now, 1);
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
      'currency': gateway == PaymentGateway.cashfree ? 'INR' : 'USD',
      'gst_number': gstNumber,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    };

    final data = await _client
        .from(AppConstants.subscriptionsTable)
        .insert(subData)
        .select()
        .single();

    // Update gym's plan_tier
    await _client
        .from(AppConstants.gymsTable)
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
        .from(AppConstants.subscriptionsTable)
        .update(updateData)
        .eq('id', current.id)
        .select()
        .single();

    // Update gym's plan_tier
    await _client
        .from(AppConstants.gymsTable)
        .update({'plan_tier': newPlan.value}).eq('id', gymId);

    return Subscription.fromJson(data);
  }

  /// Cancel a subscription at end of billing period.
  Future<void> cancelSubscription(String gymId) async {
    final current = await getCurrentSubscription(gymId);
    if (current == null) return;

    await _client.from(AppConstants.subscriptionsTable).update({
      'status': 'cancelled',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', current.id);

    // Downgrade gym to basic
    await _client
        .from(AppConstants.gymsTable)
        .update({'plan_tier': 'basic'}).eq('id', gymId);
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
        ? _addMonths(now, 12)
        : _addMonths(now, 1);

    final data = await _client
        .from(AppConstants.subscriptionsTable)
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

    await _client.from(AppConstants.subscriptionsTable).update({
      'overage_charges': newTotal,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', current.id);
  }

  // ─── GATEWAY DETECTION ─────────────────────────────────────────────

  /// Determine which payment gateway to use based on config and currency.
  static PaymentGateway detectGateway({String currency = 'INR'}) {
    if (currency == 'INR' && AppConfig.hasCashfree) {
      return PaymentGateway.cashfree;
    }
    if (AppConfig.hasStripe) {
      return PaymentGateway.stripe;
    }
    return PaymentGateway.none;
  }

  // ─── CASHFREE INTEGRATION ──────────────────────────────────────────

  /// Initialize and open Cashfree checkout.
  ///
  /// The [paymentSessionId] and [orderId] must be fetched from your backend
  /// (which securely calls Cashfree's Order Creation API)
  void startCashfreeCheckout({
    required String paymentSessionId,
    required String orderId,
  }) {
    try {
      var session = CFSessionBuilder()
          .setEnvironment(AppConfig.cashfreeEnv == 'PRODUCTION'
              ? CFEnvironment.PRODUCTION
              : CFEnvironment.SANDBOX)
          .setOrderId(orderId)
          .setPaymentSessionId(paymentSessionId)
          .build();

      var theme = CFThemeBuilder()
          .setNavigationBarBackgroundColorColor('#1e1e1e')
          .setPrimaryFont('Inter')
          .setSecondaryFont('Inter')
          .build();

      var cfDropCheckoutPayment = CFDropCheckoutPaymentBuilder()
          .setSession(session)
          .setTheme(theme)
          .build();

      CFPaymentGatewayService().doPayment(cfDropCheckoutPayment);
    } on CFException catch (e) {
      debugPrint(e.message);
    }
  }

  /// Process a successful Cashfree payment and update the subscription.
  Future<Subscription> handleCashfreeSuccess({
    required String gymId,
    required PlanTier plan,
    required BillingInterval interval,
    required String orderId,
  }) async {
    // 1. In a real app, you'd verify the payment status via webhook on backend
    // 2. Here we trust the client to update DB for MVP

    return createSubscription(
      gymId: gymId,
      plan: plan,
      interval: interval,
      gateway: PaymentGateway.cashfree,
      withTrial: false,
    );
  }

  // ─── B2C MEMBER PAYMENTS (Gym Owner -> Member) ─────────────────────

  /// Simulates generating a checkout session for a gym member paying for a membership.
  ///
  /// In a real app, this calls your backend, which uses the gym owner's `cashfree_app_id`
  /// and `cashfree_secret_key` to create an order on Cashfree's servers.
  Future<Map<String, String>> createMemberCheckoutSession({
    required String gymId,
    required String membershipId,
    required double amount,
  }) async {
    // Mocking the backend call
    await Future.delayed(const Duration(milliseconds: 800));
    final mockOrderId =
        'gym_${gymId}_mem_${membershipId}_${DateTime.now().millisecondsSinceEpoch}';
    final mockSessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';

    return {
      'order_id': mockOrderId,
      'payment_session_id': mockSessionId,
    };
  }

  /// Mark a membership as paid after a successful Cashfree B2C checkout.
  Future<void> markMembershipPaid(String membershipId, String orderId) async {
    await _client.from('memberships').update({
      'payment_status': 'paid',
      'cashfree_order_id': orderId,
      'status': 'active', // Activate the membership
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', membershipId);
  }
}
