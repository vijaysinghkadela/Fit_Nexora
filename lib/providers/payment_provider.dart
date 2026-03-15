import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/enums.dart';
import '../models/subscription_model.dart';
import '../services/payment_service.dart';

// ─── Service Providers ───────────────────────────────────────────────────────

/// Payment service provider (depends on Supabase client).
final paymentServiceProvider = Provider<PaymentService>((ref) {
  return PaymentService(Supabase.instance.client);
});

// ─── Subscription State ──────────────────────────────────────────────────────

/// Current gym's subscription (fetched by gym ID).
final gymSubscriptionProvider =
    FutureProvider.family<Subscription?, String>((ref, gymId) async {
  final service = ref.read(paymentServiceProvider);
  return service.getCurrentSubscription(gymId);
});

/// Current gym's plan tier (convenience shortcut).
final gymPlanTierProvider =
    FutureProvider.family<PlanTier, String>((ref, gymId) async {
  final service = ref.read(paymentServiceProvider);
  return service.getGymPlan(gymId);
});

/// Whether the current subscription is in trial.
final isTrialingProvider =
    FutureProvider.family<bool, String>((ref, gymId) async {
  final sub = await ref.watch(gymSubscriptionProvider(gymId).future);
  return sub?.isTrialing ?? false;
});

/// Trial days remaining.
final trialDaysProvider =
    FutureProvider.family<int, String>((ref, gymId) async {
  final sub = await ref.watch(gymSubscriptionProvider(gymId).future);
  return sub?.trialDaysRemaining ?? 0;
});
