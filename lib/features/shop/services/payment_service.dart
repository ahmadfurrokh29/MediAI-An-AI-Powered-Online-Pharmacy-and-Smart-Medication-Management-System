import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction_model.dart';

/// Result returned by [PaymentService.processPayment].
class PaymentResult {
  final bool success;
  final String transactionId;
  final String? errorMessage;

  const PaymentResult({
    required this.success,
    required this.transactionId,
    this.errorMessage,
  });
}

/// Mock payment engine.
///
/// Architecture note: This service is intentionally thin so that a real
/// gateway (e.g. PayFast) can replace only [processPayment] with minimal
/// changes to the surrounding codebase.  All callers depend on
/// [PaymentResult] and [TransactionModel] — neither of those needs to
/// change when wiring up a real provider.
class PaymentService {
  PaymentService._();
  static final PaymentService instance = PaymentService._();

  final _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // ── Public API ────────────────────────────────────────────────────────────

  /// Simulates a payment and writes the transaction to Firestore.
  ///
  /// Flow:
  ///   1. Generate a unique [transactionId].
  ///   2. Write a PROCESSING document to `Transactions/{transactionId}`.
  ///   3. Simulate a 2-second network delay.
  ///   4. Update the document status to SUCCESS.
  ///   5. Return [PaymentResult.success == true].
  ///
  /// [orderId] may be empty when called before the order document exists;
  /// call [updateTransactionOrderId] once the order is created.
  Future<PaymentResult> processPayment({
    required String userId,
    required double amount,
    required String paymentMethod,
    String orderId = '',
  }) async {
    // Generate a 20-character uppercase transaction ID.
    final txId = _uuid.v4().replaceAll('-', '').substring(0, 20).toUpperCase();
    final now = DateTime.now();

    try {
      final txRef = _db.collection('Transactions').doc(txId);

      // 1 — Write PROCESSING record
      await txRef.set(
        TransactionModel(
          transactionId: txId,
          orderId: orderId,
          userId: userId,
          paymentMethod: paymentMethod,
          amount: amount,
          status: TransactionStatus.processing,
          createdAt: now,
        ).toMap(),
      );

      // 2 — Simulate network/gateway delay
      await Future.delayed(const Duration(seconds: 2));

      // 3 — Mark SUCCESS  (replace this block with real gateway verification)
      await txRef.update({'status': 'SUCCESS'});

      return PaymentResult(success: true, transactionId: txId);
    } catch (e) {
      // Mark FAILED if something went wrong
      try {
        await _db.collection('Transactions').doc(txId).update({
          'status': 'FAILED',
        });
      } catch (_) {}
      return PaymentResult(
        success: false,
        transactionId: txId,
        errorMessage: e.toString(),
      );
    }
  }

  /// Back-fills the [orderId] on the transaction document once the order
  /// has been created in Firestore (orderId is only available after the write).
  Future<void> updateTransactionOrderId(
    String transactionId,
    String orderId,
  ) async {
    if (transactionId.isEmpty || orderId.isEmpty) return;
    try {
      await _db.collection('Transactions').doc(transactionId).update({
        'orderId': orderId,
      });
    } catch (_) {
      // Non-critical — the transaction still records the payment.
    }
  }
}
