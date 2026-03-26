import 'package:equatable/equatable.dart';
import '../core/database_values.dart';
import '../core/enums.dart';

/// Gym's SaaS subscription (Basic/Pro/Elite plan from GymOS).
///
/// Supports both Stripe (international) and Razorpay (India) payment
/// gateways, free trials, and annual billing.
class Subscription extends Equatable {
  final String id;
  final String gymId;
  final PlanTier planTier;

  // Stripe fields
  final String? stripeCustomerId;
  final String? stripeSubscriptionId;

  // Cashfree fields (Indian market)
  final String? cashfreeCustomerId;
  final String? cashfreeSubscriptionId;

  // Payment gateway used
  final PaymentGateway paymentGateway;

  final SubscriptionStatus status;
  final BillingInterval billingInterval;

  // Period tracking
  final DateTime? currentPeriodStart;
  final DateTime? currentPeriodEnd;

  // Trial
  final bool isTrialing;
  final DateTime? trialStart;
  final DateTime? trialEnd;

  // Financials
  final double? amountPaid;
  final String currency; // INR or USD
  final double? overageCharges;

  // GST (India)
  final String? gstNumber;

  final DateTime createdAt;
  final DateTime updatedAt;

  const Subscription({
    required this.id,
    required this.gymId,
    this.planTier = PlanTier.basic,
    this.stripeCustomerId,
    this.stripeSubscriptionId,
    this.cashfreeCustomerId,
    this.cashfreeSubscriptionId,
    this.paymentGateway = PaymentGateway.none,
    this.status = SubscriptionStatus.active,
    this.billingInterval = BillingInterval.monthly,
    this.currentPeriodStart,
    this.currentPeriodEnd,
    this.isTrialing = false,
    this.trialStart,
    this.trialEnd,
    this.amountPaid,
    this.currency = DatabaseValues.defaultCurrency,
    this.overageCharges,
    this.gstNumber,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Whether the subscription is currently active or trialing.
  bool get isActive =>
      status == SubscriptionStatus.active ||
      status == SubscriptionStatus.trialing;

  /// Whether the gym has AI access (Pro or Elite).
  bool get hasAiAccess =>
      planTier == PlanTier.pro || planTier == PlanTier.elite;

  /// Whether the gym has full AI access (Elite only — Kimi Opus quota).
  bool get hasFullAiAccess => planTier == PlanTier.elite;

  /// Whether the trial has expired.
  bool get isTrialExpired =>
      isTrialing && trialEnd != null && trialEnd!.isBefore(DateTime.now());

  /// Days remaining in trial.
  int get trialDaysRemaining {
    if (!isTrialing || trialEnd == null) return 0;
    return trialEnd!.difference(DateTime.now()).inDays;
  }

  /// Days remaining in current billing period.
  int get periodDaysRemaining {
    if (currentPeriodEnd == null) return 0;
    return currentPeriodEnd!.difference(DateTime.now()).inDays;
  }

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'] as String,
      gymId: json['gym_id'] as String,
      planTier: PlanTier.fromString(json['plan_tier'] as String? ?? 'basic'),
      stripeCustomerId: json['stripe_customer_id'] as String?,
      stripeSubscriptionId: json['stripe_subscription_id'] as String?,
      cashfreeCustomerId: json['cashfree_customer_id'] as String?,
      cashfreeSubscriptionId: json['cashfree_subscription_id'] as String?,
      paymentGateway: PaymentGateway.fromString(
          json['payment_gateway'] as String? ?? 'none'),
      status:
          SubscriptionStatus.fromString(json['status'] as String? ?? 'active'),
      billingInterval: BillingInterval.fromString(
          json['billing_interval'] as String? ?? 'monthly'),
      currentPeriodStart: json['current_period_start'] != null
          ? DateTime.parse(json['current_period_start'] as String)
          : null,
      currentPeriodEnd: json['current_period_end'] != null
          ? DateTime.parse(json['current_period_end'] as String)
          : null,
      isTrialing: json['is_trialing'] as bool? ?? false,
      trialStart: json['trial_start'] != null
          ? DateTime.parse(json['trial_start'] as String)
          : null,
      trialEnd: json['trial_end'] != null
          ? DateTime.parse(json['trial_end'] as String)
          : null,
      amountPaid: (json['amount_paid'] as num?)?.toDouble(),
      currency: json['currency'] as String? ?? DatabaseValues.defaultCurrency,
      overageCharges: (json['overage_charges'] as num?)?.toDouble(),
      gstNumber: json['gst_number'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'gym_id': gymId,
        'plan_tier': planTier.value,
        'stripe_customer_id': stripeCustomerId,
        'stripe_subscription_id': stripeSubscriptionId,
        'cashfree_customer_id': cashfreeCustomerId,
        'cashfree_subscription_id': cashfreeSubscriptionId,
        'payment_gateway': paymentGateway.value,
        'status': status.value,
        'billing_interval': billingInterval.value,
        'current_period_start': currentPeriodStart?.toIso8601String(),
        'current_period_end': currentPeriodEnd?.toIso8601String(),
        'is_trialing': isTrialing,
        'trial_start': trialStart?.toIso8601String(),
        'trial_end': trialEnd?.toIso8601String(),
        'amount_paid': amountPaid,
        'currency': currency,
        'overage_charges': overageCharges,
        'gst_number': gstNumber,
      };

  @override
  List<Object?> get props => [id, gymId, planTier, status, billingInterval];
}

/// Payment gateway used for the subscription.
enum PaymentGateway {
  none('none', 'None'),
  stripe('stripe', 'Stripe'),
  cashfree('cashfree', 'Cashfree');

  const PaymentGateway(this.value, this.label);
  final String value;
  final String label;

  static PaymentGateway fromString(String value) {
    return PaymentGateway.values.firstWhere(
      (g) => g.value == value,
      orElse: () => PaymentGateway.none,
    );
  }
}

/// Billing interval.
enum BillingInterval {
  monthly('monthly', 'Monthly'),
  annual('annual', 'Annual');

  const BillingInterval(this.value, this.label);
  final String value;
  final String label;

  static BillingInterval fromString(String value) {
    return BillingInterval.values.firstWhere(
      (b) => b.value == value,
      orElse: () => BillingInterval.monthly,
    );
  }
}
