import 'dart:convert';
import 'package:http/http.dart' as http;

// ── Replace with your deployed FastAPI base URL ───────────────────────────────
const String _kApiBase = 'http://192.168.137.116:8800';

class CouponApiResult {
  final bool valid;
  final String message;
  final String? errorCode;
  final double discountAmount;
  final double finalTotal;
  final Map<String, dynamic> raw;

  const CouponApiResult({
    required this.valid,
    required this.message,
    this.errorCode,
    this.discountAmount = 0.0,
    this.finalTotal = 0.0,
    this.raw = const {},
  });
}

class CouponApiService {
  static CouponApiService get instance => CouponApiService._();
  CouponApiService._();

  // ── Shared coupon snapshot builder ───────────────────────────────────────

  Map<String, dynamic> _buildCouponSnapshot(Map<String, dynamic> couponData) {
    return {
      'id': couponData['id'] ?? '',
      'code': couponData['code'] ?? '',
      'DiscountValue': couponData['discountValue'] ?? 0,
      'Type': couponData['type'] ?? 'FLAT',
      'IsActive': couponData['isActive'] ?? true,
      'StartDate': couponData['startDate'],
      'EndDate': couponData['endDate'],
      'UsageLimit': couponData['usageLimit'] ?? 100,
      'UsageCount': couponData['usageCount'] ?? 0,
      'PerUserLimit': couponData['perUserLimit'] ?? 1,
      'MinOrderAmount': couponData['minOrderAmount'] ?? 0.0,
      'Stackable': couponData['stackable'] ?? false,
    };
  }

  // ── Validate ─────────────────────────────────────────────────────────────

  Future<CouponApiResult> validateCoupon({
    required String couponCode,
    required String userId,
    required double orderSubtotal,
    required int userRedemptionCount,
    required Map<String, dynamic> couponData,
  }) async {
    try {
      final body = {
        'coupon_code': couponCode,
        'user_id': userId,
        'order_subtotal': orderSubtotal,
        'user_redemption_count': userRedemptionCount,
        'coupon': _buildCouponSnapshot(couponData),
      };
      final response = await http
          .post(
            Uri.parse('$_kApiBase/coupon/validate'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return CouponApiResult(
        valid: data['valid'] ?? false,
        message: data['message'] ?? '',
        errorCode: data['error_code'],
        discountAmount: (data['discount_amount'] ?? 0.0).toDouble(),
        raw: data,
      );
    } catch (e) {
      return CouponApiResult(
        valid: false,
        message: 'Service unavailable. Please try again.',
        errorCode: 'SERVICE_UNAVAILABLE',
      );
    }
  }

  // ── Apply ─────────────────────────────────────────────────────────────────

  Future<CouponApiResult> applyCoupon({
    required String couponCode,
    required String userId,
    required double orderSubtotal,
    required double shippingFee,
    required double taxFee,
    required int userRedemptionCount,
    required Map<String, dynamic> couponData,
  }) async {
    try {
      final body = {
        'coupon_code': couponCode,
        'user_id': userId,
        'order_subtotal': orderSubtotal,
        'shipping_fee': shippingFee,
        'tax_fee': taxFee,
        'user_redemption_count': userRedemptionCount,
        'coupon': _buildCouponSnapshot(couponData),
      };
      final response = await http
          .post(
            Uri.parse('$_kApiBase/coupon/apply'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return CouponApiResult(
        valid: data['valid'] ?? false,
        message: data['message'] ?? '',
        errorCode: data['error_code'],
        discountAmount: (data['discount_amount'] ?? 0.0).toDouble(),
        finalTotal: (data['final_total'] ?? 0.0).toDouble(),
        raw: data,
      );
    } catch (e) {
      return CouponApiResult(
        valid: false,
        message: 'Service unavailable. Please try again.',
        errorCode: 'SERVICE_UNAVAILABLE',
      );
    }
  }

  // ── Redeem (final gate before order placement) ────────────────────────────

  Future<CouponApiResult> redeemCoupon({
    required String userId,
    required String couponId,
    required String orderId,
    required double orderSubtotal,
    required int userRedemptionCount,
    required Map<String, dynamic> couponData,
  }) async {
    try {
      final body = {
        'user_id': userId,
        'coupon_id': couponId,
        'order_id': orderId,
        'order_subtotal': orderSubtotal,
        'user_redemption_count': userRedemptionCount,
        'coupon': _buildCouponSnapshot(couponData),
      };
      final response = await http
          .post(
            Uri.parse('$_kApiBase/coupon/redeem'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 409) {
        return const CouponApiResult(
          valid: false,
          message: 'Coupon already redeemed for this order.',
          errorCode: 'ALREADY_REDEEMED',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return CouponApiResult(
        valid: data['valid'] ?? false,
        message: data['message'] ?? '',
        errorCode: data['error_code'],
        discountAmount: (data['discount_amount'] ?? 0.0).toDouble(),
        raw: data,
      );
    } catch (e) {
      return const CouponApiResult(
        valid: false,
        message: 'Redemption service unavailable.',
        errorCode: 'SERVICE_UNAVAILABLE',
      );
    }
  }
}
