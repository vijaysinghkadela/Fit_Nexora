import 'package:equatable/equatable.dart';
import '../core/database_values.dart';

/// GST-compliant invoice for Indian market.
///
/// Auto-generated on subscription payment or client fee collection.
/// Legal requirement for Indian businesses.
class GstInvoice extends Equatable {
  final String id;
  final String gymId;
  final String? subscriptionId;
  final String? clientId;

  // Invoice details
  final String invoiceNumber; // e.g., "GYMOS-2026-0001"
  final DateTime invoiceDate;
  final DateTime? dueDate;

  // Amounts
  final double subtotal;
  final double gstRate; // typically 18%
  final double cgstAmount; // Central GST (9%)
  final double sgstAmount; // State GST (9%)
  final double
      igstAmount; // Inter-state GST (18%) — used when CGST+SGST don't apply
  final double totalAmount;
  final String currency; // INR

  // GST details
  final String? sellerGstin; // GymOS platform GSTIN
  final String? buyerGstin; // Gym owner's GSTIN (optional)
  final String? placeOfSupply; // State code
  final String hsn; // HSN/SAC code for SaaS services

  // Line items description
  final String description; // e.g., "GymOS Pro Plan - Monthly Subscription"
  final int quantity;

  // Status
  final InvoiceStatus status;
  final String? paymentId; // Stripe or Razorpay payment ID

  final DateTime createdAt;

  const GstInvoice({
    required this.id,
    required this.gymId,
    this.subscriptionId,
    this.clientId,
    required this.invoiceNumber,
    required this.invoiceDate,
    this.dueDate,
    required this.subtotal,
    this.gstRate = 18.0,
    required this.cgstAmount,
    required this.sgstAmount,
    this.igstAmount = 0.0,
    required this.totalAmount,
    this.currency = DatabaseValues.defaultCurrency,
    this.sellerGstin,
    this.buyerGstin,
    this.placeOfSupply,
    this.hsn = '998314', // SAC code for IT/SaaS services
    required this.description,
    this.quantity = 1,
    this.status = InvoiceStatus.paid,
    this.paymentId,
    required this.createdAt,
  });

  /// Generate a GST invoice from a subscription payment.
  factory GstInvoice.fromSubscription({
    required String id,
    required String gymId,
    required String subscriptionId,
    required String planName,
    required double amount,
    required String invoiceNumber,
    String? buyerGstin,
    String? placeOfSupply,
    String? paymentId,
  }) {
    // For intra-state: split into CGST + SGST (9% each)
    // For inter-state: use IGST (18%)
    final isInterState =
        placeOfSupply != null && placeOfSupply != '29'; // default KA
    final gstAmount = amount * 0.18;
    final subtotal = amount;
    final total = amount + gstAmount;

    return GstInvoice(
      id: id,
      gymId: gymId,
      subscriptionId: subscriptionId,
      invoiceNumber: invoiceNumber,
      invoiceDate: DateTime.now(),
      subtotal: subtotal,
      cgstAmount: isInterState ? 0 : gstAmount / 2,
      sgstAmount: isInterState ? 0 : gstAmount / 2,
      igstAmount: isInterState ? gstAmount : 0,
      totalAmount: total,
      buyerGstin: buyerGstin,
      placeOfSupply: placeOfSupply,
      description: '$planName — Monthly Subscription',
      paymentId: paymentId,
      createdAt: DateTime.now(),
    );
  }

  factory GstInvoice.fromJson(Map<String, dynamic> json) {
    return GstInvoice(
      id: json['id'] as String,
      gymId: json['gym_id'] as String,
      subscriptionId: json['subscription_id'] as String?,
      clientId: json['client_id'] as String?,
      invoiceNumber: json['invoice_number'] as String,
      invoiceDate: DateTime.parse(json['invoice_date'] as String),
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : null,
      subtotal: (json['subtotal'] as num).toDouble(),
      gstRate: (json['gst_rate'] as num?)?.toDouble() ?? 18.0,
      cgstAmount: (json['cgst_amount'] as num).toDouble(),
      sgstAmount: (json['sgst_amount'] as num).toDouble(),
      igstAmount: (json['igst_amount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['total_amount'] as num).toDouble(),
      currency:
          json['currency'] as String? ?? DatabaseValues.defaultCurrency,
      sellerGstin: json['seller_gstin'] as String?,
      buyerGstin: json['buyer_gstin'] as String?,
      placeOfSupply: json['place_of_supply'] as String?,
      hsn: json['hsn'] as String? ?? '998314',
      description: json['description'] as String,
      quantity: json['quantity'] as int? ?? 1,
      status: InvoiceStatus.fromString(json['status'] as String? ?? 'paid'),
      paymentId: json['payment_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'gym_id': gymId,
        'subscription_id': subscriptionId,
        'client_id': clientId,
        'invoice_number': invoiceNumber,
        'invoice_date': invoiceDate.toIso8601String(),
        'due_date': dueDate?.toIso8601String(),
        'subtotal': subtotal,
        'gst_rate': gstRate,
        'cgst_amount': cgstAmount,
        'sgst_amount': sgstAmount,
        'igst_amount': igstAmount,
        'total_amount': totalAmount,
        'currency': currency,
        'seller_gstin': sellerGstin,
        'buyer_gstin': buyerGstin,
        'place_of_supply': placeOfSupply,
        'hsn': hsn,
        'description': description,
        'quantity': quantity,
        'status': status.value,
        'payment_id': paymentId,
        'created_at': createdAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [id, invoiceNumber, gymId];
}

/// Invoice status.
enum InvoiceStatus {
  draft('draft', 'Draft'),
  paid('paid', 'Paid'),
  void_('void', 'Void'),
  refunded('refunded', 'Refunded');

  const InvoiceStatus(this.value, this.label);
  final String value;
  final String label;

  static InvoiceStatus fromString(String value) {
    return InvoiceStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => InvoiceStatus.draft,
    );
  }
}
