import 'package:get/get.dart';

/// Supported payment methods.
enum PaymentMethod { cashOnDelivery, card }

class PaymentController extends GetxController {
  static PaymentController get instance => Get.find();

  final Rx<PaymentMethod> selectedMethod = PaymentMethod.cashOnDelivery.obs;

  /// Card details (simple — not production-grade tokenized payments).
  final RxString cardNumber = ''.obs;
  final RxString cardHolder = ''.obs;
  final RxString expiryDate = ''.obs;
  final RxString cvv = ''.obs;
  final RxBool hasCard = false.obs;

  /// Save card details locally.
  void saveCard({
    required String number,
    required String holder,
    required String expiry,
    required String cvvCode,
  }) {
    cardNumber.value = number;
    cardHolder.value = holder;
    expiryDate.value = expiry;
    cvv.value = cvvCode;
    hasCard.value = true;
  }

  void removeCard() {
    cardNumber.value = '';
    cardHolder.value = '';
    expiryDate.value = '';
    cvv.value = '';
    hasCard.value = false;
    if (selectedMethod.value == PaymentMethod.card) {
      selectedMethod.value = PaymentMethod.cashOnDelivery;
    }
  }

  /// Display string for current method.
  String get methodLabel {
    switch (selectedMethod.value) {
      case PaymentMethod.cashOnDelivery:
        return 'Cash on Delivery';
      case PaymentMethod.card:
        return 'Card Payment';
    }
  }

  /// Payment status based on method.
  String get paymentStatusForOrder {
    switch (selectedMethod.value) {
      case PaymentMethod.card:
        return 'Paid';
      case PaymentMethod.cashOnDelivery:
        return 'Unpaid';
    }
  }
}
