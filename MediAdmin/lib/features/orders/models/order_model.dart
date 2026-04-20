import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItemModel {
  final String productId;
  final String productName;
  final double price;
  final int quantity;

  OrderItemModel({
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
  });

  double get subtotal => price * quantity;

  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    return OrderItemModel(
      productId: map['productId'] as String? ?? '',
      productName:
          map['productName'] as String? ??
          map['name'] as String? ??
          'Unknown Product',
      price: (map['price'] as num? ?? 0).toDouble(),
      quantity: (map['quantity'] as num? ?? 1).toInt(),
    );
  }

  Map<String, dynamic> toMap() => {
    'productId': productId,
    'productName': productName,
    'price': price,
    'quantity': quantity,
  };
}

class OrderModel {
  final String id;
  final String customerId;
  final String customerName;
  final String customerEmail;
  final List<OrderItemModel> items;
  final String orderStatus;
  final String paymentStatus;
  final double totalAmount;
  final double subtotal;
  final String couponCode;
  final double couponDiscount;
  final double shippingFee;
  final Map<String, dynamic> shippingAddress;
  final DateTime createdAt;

  OrderModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerEmail,
    required this.items,
    required this.orderStatus,
    required this.paymentStatus,
    required this.totalAmount,
    required this.subtotal,
    required this.couponCode,
    required this.couponDiscount,
    required this.shippingFee,
    required this.shippingAddress,
    required this.createdAt,
  });

  int get itemCount => items.length;

  factory OrderModel.fromSnapshot(DocumentSnapshot snap) {
    final data = snap.data() as Map<String, dynamic>;

    List<OrderItemModel> parsedItems = [];
    final rawItems = data['items'] ?? data['Items'] ?? data['orderItems'];
    if (rawItems is List) {
      parsedItems = rawItems
          .map((e) => OrderItemModel.fromMap(e as Map<String, dynamic>))
          .toList();
    }

    double computedSubtotal = parsedItems.fold(
      0.0,
      (sum, i) => sum + i.subtotal,
    );
    final couponDiscount =
        (data['couponDiscount'] as num? ?? data['CouponDiscount'] as num? ?? 0)
            .toDouble();
    final shippingFee =
        (data['shippingFee'] as num? ?? data['ShippingFee'] as num? ?? 0)
            .toDouble();

    DateTime createdAt = DateTime.now();
    final ts =
        data['createdAt'] ?? data['CreatedAt'] ?? data['date'] ?? data['Date'];
    if (ts is Timestamp) {
      createdAt = ts.toDate();
    } else if (ts is String) {
      createdAt = DateTime.tryParse(ts) ?? DateTime.now();
    }

    return OrderModel(
      id: snap.id,
      customerId:
          data['customerId'] as String? ??
          data['UserId'] as String? ??
          data['userId'] as String? ??
          '',
      customerName:
          data['customerName'] as String? ??
          data['CustomerName'] as String? ??
          '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim(),
      customerEmail:
          data['customerEmail'] as String? ??
          data['CustomerEmail'] as String? ??
          data['email'] as String? ??
          '',
      items: parsedItems,
      orderStatus:
          data['orderStatus'] as String? ??
          data['OrderStatus'] as String? ??
          data['status'] as String? ??
          'Pending',
      paymentStatus: _resolvePaymentStatus(data),
      totalAmount:
          (data['totalAmount'] as num? ??
                  data['TotalAmount'] as num? ??
                  data['total'] as num? ??
                  0)
              .toDouble(),
      subtotal: (data['subtotal'] as num? ?? computedSubtotal).toDouble(),
      couponCode:
          data['couponCode'] as String? ?? data['CouponCode'] as String? ?? '',
      couponDiscount: couponDiscount,
      shippingFee: shippingFee,
      shippingAddress:
          (data['shippingAddress'] as Map<String, dynamic>? ??
          data['ShippingAddress'] as Map<String, dynamic>? ??
          {}),
      createdAt: createdAt,
    );
  }

  /// If payment method is card/credit/debit, status is always Paid.
  static String _resolvePaymentStatus(Map<String, dynamic> data) {
    final method =
        (data['paymentMethod'] as String? ??
                data['PaymentMethod'] as String? ??
                '')
            .toLowerCase();
    final isCard =
        method.contains('card') ||
        method.contains('credit') ||
        method.contains('debit') ||
        method.contains('stripe') ||
        method.contains('online');
    if (isCard) return 'Paid';
    return data['paymentStatus'] as String? ??
        data['PaymentStatus'] as String? ??
        'Unpaid';
  }

  Map<String, dynamic> toMap() => {
    'customerId': customerId,
    'customerName': customerName,
    'customerEmail': customerEmail,
    'items': items.map((e) => e.toMap()).toList(),
    'orderStatus': orderStatus,
    'paymentStatus': paymentStatus,
    'totalAmount': totalAmount,
    'subtotal': subtotal,
    'couponCode': couponCode,
    'couponDiscount': couponDiscount,
    'shippingFee': shippingFee,
    'shippingAddress': shippingAddress,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  OrderModel copyWith({String? orderStatus, String? paymentStatus}) {
    return OrderModel(
      id: id,
      customerId: customerId,
      customerName: customerName,
      customerEmail: customerEmail,
      items: items,
      orderStatus: orderStatus ?? this.orderStatus,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      totalAmount: totalAmount,
      subtotal: subtotal,
      couponCode: couponCode,
      couponDiscount: couponDiscount,
      shippingFee: shippingFee,
      shippingAddress: shippingAddress,
      createdAt: createdAt,
    );
  }
}
