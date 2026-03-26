import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItemModel {
  final String productId;
  final String productName;
  final double price;
  final int quantity;

  const OrderItemModel({
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
  });

  factory OrderItemModel.fromMap(Map<String, dynamic> map) => OrderItemModel(
    productId: map['productId'] as String? ?? '',
    productName: map['productName'] as String? ?? '',
    price: (map['price'] as num? ?? 0).toDouble(),
    quantity: (map['quantity'] as num? ?? 1).toInt(),
  );

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
  final String orderStatus;
  final String paymentStatus;
  final double totalAmount;
  final double subtotal;
  final String couponCode;
  final double couponDiscount;
  final double shippingFee;
  final DateTime createdAt;
  final Map<String, dynamic> shippingAddress;
  final List<OrderItemModel> items;

  const OrderModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerEmail,
    required this.orderStatus,
    required this.paymentStatus,
    required this.totalAmount,
    required this.subtotal,
    required this.couponCode,
    required this.couponDiscount,
    required this.shippingFee,
    required this.createdAt,
    required this.shippingAddress,
    required this.items,
  });

  static OrderModel empty() => OrderModel(
    id: '',
    customerId: '',
    customerName: '',
    customerEmail: '',
    orderStatus: '',
    paymentStatus: '',
    totalAmount: 0,
    subtotal: 0,
    couponCode: '',
    couponDiscount: 0,
    shippingFee: 0,
    createdAt: DateTime.now(),
    shippingAddress: {},
    items: [],
  );

  factory OrderModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return OrderModel(
      id: doc.id,
      customerId: data['customerId'] as String? ?? '',
      customerName: data['customerName'] as String? ?? '',
      customerEmail: data['customerEmail'] as String? ?? '',
      orderStatus: data['orderStatus'] as String? ?? 'Pending',
      paymentStatus: data['paymentStatus'] as String? ?? 'Pending',
      totalAmount: (data['totalAmount'] as num? ?? 0).toDouble(),
      subtotal: (data['subtotal'] as num? ?? 0).toDouble(),
      couponCode: data['couponCode'] as String? ?? '',
      couponDiscount: (data['couponDiscount'] as num? ?? 0).toDouble(),
      shippingFee: (data['shippingFee'] as num? ?? 0).toDouble(),
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      shippingAddress: data['shippingAddress'] as Map<String, dynamic>? ?? {},
      items: (data['items'] as List<dynamic>? ?? [])
          .map((e) => OrderItemModel.fromMap(e as Map<String, dynamic>? ?? {}))
          .toList(),
    );
  }

  /// Formatted creation date, e.g. "12 Aug, 2025"
  String get formattedDate {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${createdAt.day} ${months[createdAt.month - 1]}, ${createdAt.year}';
  }

  /// Short order ID shown in the UI  e.g. "#A3F7"
  String get shortId =>
      '#${id.length > 6 ? id.substring(0, 6).toUpperCase() : id.toUpperCase()}';

  /// Convert model to a Firestore-writable map.
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
}
