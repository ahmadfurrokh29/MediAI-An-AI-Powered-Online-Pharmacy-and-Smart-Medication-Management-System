import 'package:cloud_firestore/cloud_firestore.dart';

/// Types of payment methods supported by the app.
enum PaymentMethodType { card, easypaisa, jazzcash }

/// A saved payment method stored in Firestore under
/// Users/{uid}/PaymentMethods/{docId}.
///
/// SECURITY: Full card/account numbers are NEVER stored.
/// Only masked values (e.g. "**** **** **** 1234") are persisted.
class PaymentMethodModel {
  final String id; // Firestore document ID
  final PaymentMethodType type;
  final String displayLabel; // e.g. "**** **** **** 1234" or "0300 **** 6789"
  final String accountTitle; // Card holder name or account name
  final String expiryDate; // "MM/YY" – cards only
  final DateTime createdAt;

  const PaymentMethodModel({
    required this.id,
    required this.type,
    required this.displayLabel,
    required this.accountTitle,
    this.expiryDate = '',
    required this.createdAt,
  });

  // ── Helpers ──────────────────────────────────────────────────────────────

  /// Human-readable type label.
  String get typeLabel {
    switch (type) {
      case PaymentMethodType.card:
        return 'Card Payment';
      case PaymentMethodType.easypaisa:
        return 'Easypaisa';
      case PaymentMethodType.jazzcash:
        return 'JazzCash';
    }
  }

  /// Used when writing to Firestore or order documents.
  String get typeString {
    switch (type) {
      case PaymentMethodType.card:
        return 'card';
      case PaymentMethodType.easypaisa:
        return 'easypaisa';
      case PaymentMethodType.jazzcash:
        return 'jazzcash';
    }
  }

  static PaymentMethodType typeFromString(String s) {
    switch (s.toLowerCase()) {
      case 'easypaisa':
        return PaymentMethodType.easypaisa;
      case 'jazzcash':
        return PaymentMethodType.jazzcash;
      default:
        return PaymentMethodType.card;
    }
  }

  // ── Masked-number helpers ─────────────────────────────────────────────────

  /// Produces "**** **** **** 1234" from a raw 16-digit card number.
  static String maskCardNumber(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 4) return '**** **** **** $digits';
    final last4 = digits.substring(digits.length - 4);
    return '**** **** **** $last4';
  }

  /// Produces "0300 **** 6789" from a raw 11-digit mobile number.
  static String maskAccountNumber(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 7) return digits;
    final prefix = digits.substring(0, 4);
    final suffix = digits.substring(digits.length - 4);
    return '$prefix **** $suffix';
  }

  // ── Serialisation ─────────────────────────────────────────────────────────

  factory PaymentMethodModel.fromMap(String id, Map<String, dynamic> map) {
    return PaymentMethodModel(
      id: id,
      type: typeFromString(map['type'] as String? ?? 'card'),
      displayLabel: map['displayLabel'] as String? ?? '',
      accountTitle: map['accountTitle'] as String? ?? '',
      expiryDate: map['expiryDate'] as String? ?? '',
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'type': typeString,
    'displayLabel': displayLabel,
    'accountTitle': accountTitle,
    'expiryDate': expiryDate,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}
