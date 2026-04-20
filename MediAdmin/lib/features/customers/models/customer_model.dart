import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final int points;
  final int orderCount;
  final Map<String, dynamic> shippingAddress;
  final List<Map<String, dynamic>> addresses;
  final int selectedAddressIndex;
  final DateTime createdAt;
  final bool isEmailVerified;

  CustomerModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.points,
    required this.orderCount,
    required this.shippingAddress,
    required this.createdAt,
    required this.isEmailVerified,
    this.addresses = const [],
    this.selectedAddressIndex = 0,
  });

  String get fullName {
    final n = '$firstName $lastName'.trim();
    return n.isEmpty ? email : n;
  }

  String get initials {
    final name = fullName;
    if (name.isEmpty) return '?';
    final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  /// Returns the currently selected address.
  /// Prefers the `addresses` list + `selectedAddressIndex`;
  /// falls back to the legacy `shippingAddress` map.
  Map<String, dynamic> get selectedShippingAddress {
    if (addresses.isNotEmpty) {
      final idx = selectedAddressIndex.clamp(0, addresses.length - 1);
      return addresses[idx];
    }
    return shippingAddress;
  }

  factory CustomerModel.fromSnapshot(DocumentSnapshot snap) {
    final data = snap.data() as Map<String, dynamic>;

    DateTime createdAt = DateTime.now();
    final ts =
        data['createdAt'] ??
        data['CreatedAt'] ??
        data['registeredAt'] ??
        data['RegisteredAt'];
    if (ts is Timestamp) {
      createdAt = ts.toDate();
    } else if (ts is String) {
      createdAt = DateTime.tryParse(ts) ?? DateTime.now();
    }

    return CustomerModel(
      id: snap.id,
      firstName:
          data['firstName'] as String? ??
          data['FirstName'] as String? ??
          data['name'] as String? ??
          '',
      lastName:
          data['lastName'] as String? ?? data['LastName'] as String? ?? '',
      email: data['email'] as String? ?? data['Email'] as String? ?? '',
      phoneNumber:
          data['phoneNumber'] as String? ??
          data['PhoneNumber'] as String? ??
          data['phone'] as String? ??
          '',
      points: (data['points'] as num? ?? data['Points'] as num? ?? 0).toInt(),
      orderCount:
          (data['orderCount'] as num? ??
                  data['OrderCount'] as num? ??
                  data['orders'] as num? ??
                  0)
              .toInt(),
      shippingAddress: _toMap(
        data['shippingAddress'] ?? data['ShippingAddress'],
      ),
      addresses: _toAddressList(data['addresses']),
      selectedAddressIndex:
          (data['selectedAddressIndex'] as num?)?.toInt() ?? 0,
      createdAt: createdAt,
      isEmailVerified:
          data['isEmailVerified'] as bool? ??
          data['emailVerified'] as bool? ??
          false,
    );
  }

  Map<String, dynamic> toMap() => {
    'firstName': firstName,
    'lastName': lastName,
    'email': email,
    'phoneNumber': phoneNumber,
    'points': points,
    'orderCount': orderCount,
    'shippingAddress': shippingAddress,
    'createdAt': Timestamp.fromDate(createdAt),
    'isEmailVerified': isEmailVerified,
  };

  /// Safely converts any Firestore value to Map<String, dynamic>.
  static Map<String, dynamic> _toMap(dynamic value) {
    if (value == null) return {};
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), v));
    }
    return {};
  }

  /// Safely converts a Firestore array field to List<Map<String, dynamic>>.
  static List<Map<String, dynamic>> _toAddressList(dynamic value) {
    if (value == null) return [];
    if (value is! List) return [];
    return value
        .where((e) => e != null)
        .map<Map<String, dynamic>>((e) => _toMap(e))
        .where((m) => m.isNotEmpty)
        .toList();
  }
}
