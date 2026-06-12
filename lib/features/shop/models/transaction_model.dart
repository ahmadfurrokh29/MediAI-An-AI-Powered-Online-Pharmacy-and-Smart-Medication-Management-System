import 'package:cloud_firestore/cloud_firestore.dart';

/// Transaction lifecycle statuses.
enum TransactionStatus { pending, processing, success, failed, cancelled }

/// A transaction record written to the top-level Firestore collection
/// `Transactions/{transactionId}`.
///
/// Created by [PaymentService] before a non-COD payment and updated once the
/// mock engine completes.  A real gateway (e.g. PayFast) would replace only
/// [PaymentService.processPayment] while this model remains unchanged.
class TransactionModel {
  final String transactionId;
  final String orderId;
  final String userId;
  final String paymentMethod; // e.g. "Card Payment", "Easypaisa", "JazzCash"
  final double amount;
  final TransactionStatus status;
  final DateTime createdAt;

  const TransactionModel({
    required this.transactionId,
    required this.orderId,
    required this.userId,
    required this.paymentMethod,
    required this.amount,
    required this.status,
    required this.createdAt,
  });

  // ── Helpers ──────────────────────────────────────────────────────────────

  String get statusString {
    switch (status) {
      case TransactionStatus.pending:
        return 'PENDING';
      case TransactionStatus.processing:
        return 'PROCESSING';
      case TransactionStatus.success:
        return 'SUCCESS';
      case TransactionStatus.failed:
        return 'FAILED';
      case TransactionStatus.cancelled:
        return 'CANCELLED';
    }
  }

  static TransactionStatus statusFromString(String s) {
    switch (s.toUpperCase()) {
      case 'PROCESSING':
        return TransactionStatus.processing;
      case 'SUCCESS':
        return TransactionStatus.success;
      case 'FAILED':
        return TransactionStatus.failed;
      case 'CANCELLED':
        return TransactionStatus.cancelled;
      default:
        return TransactionStatus.pending;
    }
  }

  // ── Serialisation ─────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
    'transactionId': transactionId,
    'orderId': orderId,
    'userId': userId,
    'paymentMethod': paymentMethod,
    'amount': amount,
    'status': statusString,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  factory TransactionModel.fromMap(Map<String, dynamic> map) =>
      TransactionModel(
        transactionId: map['transactionId'] as String? ?? '',
        orderId: map['orderId'] as String? ?? '',
        userId: map['userId'] as String? ?? '',
        paymentMethod: map['paymentMethod'] as String? ?? '',
        amount: (map['amount'] as num? ?? 0).toDouble(),
        status: statusFromString(map['status'] as String? ?? 'PENDING'),
        createdAt: map['createdAt'] is Timestamp
            ? (map['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
      );
}
