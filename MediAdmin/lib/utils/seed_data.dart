import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Seeds dummy customers (in Users collection) and orders (in Orders collection)
/// into Firestore. Runs only once — checks if data already exists before inserting.
class SeedData {
  static final _db = FirebaseFirestore.instance;

  static Future<void> run() async {
    try {
      await _cleanAdminDocsFromUsers(); // Remove any admin docs that leaked into Users
      await _seedCustomers();
      // NOTE: _seedOrders() removed — it was re-seeding dummy orders every time
      // the Orders collection was empty (e.g. after manual deletion).
    } catch (e) {
      if (kDebugMode) print('[SeedData] Error: $e');
    }
  }

  // ─── Remove admin docs from Users collection ──────────────────────────────
  // Admins should only exist in Admins collection, not in Users.
  // This cleans up any previously leaked admin docs.
  static Future<void> _cleanAdminDocsFromUsers() async {
    try {
      // Find any Users docs with role = 'admin' or 'Admin'
      final lowerSnap = await _db
          .collection('Users')
          .where('role', isEqualTo: 'admin')
          .get();
      final upperSnap = await _db
          .collection('Users')
          .where('role', isEqualTo: 'Admin')
          .get();

      final allDocs = [...lowerSnap.docs, ...upperSnap.docs];
      if (allDocs.isEmpty) return;

      final batch = _db.batch();
      for (final doc in allDocs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      if (kDebugMode) {
        print(
          '[SeedData] Removed ${allDocs.length} admin doc(s) from Users collection.',
        );
      }
    } catch (e) {
      if (kDebugMode) print('[SeedData] Cleanup error (non-fatal): $e');
    }
  }

  // ─── Customers ────────────────────────────────────────────────────────────

  static Future<void> _seedCustomers() async {
    // Check if already seeded
    final existing = await _db
        .collection('Users')
        .where('role', isEqualTo: 'Customer')
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) {
      if (kDebugMode) print('[SeedData] Customers already seeded, skipping.');
      return;
    }

    final customers = [
      {
        'id': 'cust_001',
        'firstName': 'Sarah',
        'lastName': 'Johnson',
        'email': 'sarah.johnson@email.com',
        'phoneNumber': '+1 (555) 234-5678',
        'role': 'Customer',
        'points': 350,
        'orderCount': 4,
        'isEmailVerified': true,
        'createdAt': Timestamp.fromDate(DateTime(2025, 6, 15, 10, 30)),
        'shippingAddress': {
          'name': 'Sarah Johnson',
          'city': 'New York',
          'phoneNumber': '+1 (555) 234-5678',
          'address': '124 West 5th Street, Apt 3B',
        },
      },
      {
        'id': 'cust_002',
        'firstName': 'Michael',
        'lastName': 'Chen',
        'email': 'michael.chen@email.com',
        'phoneNumber': '+1 (555) 876-5432',
        'role': 'Customer',
        'points': 120,
        'orderCount': 2,
        'isEmailVerified': true,
        'createdAt': Timestamp.fromDate(DateTime(2025, 8, 3, 14, 15)),
        'shippingAddress': {
          'name': 'Michael Chen',
          'city': 'San Francisco',
          'phoneNumber': '+1 (555) 876-5432',
          'address': '45 Market Street, Suite 200',
        },
      },
      {
        'id': 'cust_003',
        'firstName': 'Emily',
        'lastName': 'Rodriguez',
        'email': 'emily.rodriguez@email.com',
        'phoneNumber': '+1 (555) 345-6789',
        'role': 'Customer',
        'points': 780,
        'orderCount': 7,
        'isEmailVerified': false,
        'createdAt': Timestamp.fromDate(DateTime(2025, 3, 22, 9, 0)),
        'shippingAddress': {
          'name': 'Emily Rodriguez',
          'city': 'Chicago',
          'phoneNumber': '+1 (555) 345-6789',
          'address': '800 N Michigan Ave, Apt 12',
        },
      },
      {
        'id': 'cust_004',
        'firstName': 'James',
        'lastName': 'Patel',
        'email': 'james.patel@email.com',
        'phoneNumber': '+1 (555) 987-1234',
        'role': 'Customer',
        'points': 50,
        'orderCount': 1,
        'isEmailVerified': true,
        'createdAt': Timestamp.fromDate(DateTime(2025, 11, 1, 16, 45)),
        'shippingAddress': {
          'name': 'James Patel',
          'city': 'Houston',
          'phoneNumber': '+1 (555) 987-1234',
          'address': '310 Texas Ave, Unit 5',
        },
      },
      {
        'id': 'cust_005',
        'firstName': 'Olivia',
        'lastName': 'Kim',
        'email': 'olivia.kim@email.com',
        'phoneNumber': '+1 (555) 654-3210',
        'role': 'Customer',
        'points': 410,
        'orderCount': 5,
        'isEmailVerified': true,
        'createdAt': Timestamp.fromDate(DateTime(2025, 5, 10, 11, 0)),
        'shippingAddress': {
          'name': 'Olivia Kim',
          'city': 'Los Angeles',
          'phoneNumber': '+1 (555) 654-3210',
          'address': '1200 Sunset Blvd, Apt 7C',
        },
      },
    ];

    final batch = _db.batch();
    for (final c in customers) {
      final id = c['id'] as String;
      final data = Map<String, dynamic>.from(c)..remove('id');
      batch.set(_db.collection('Users').doc(id), data);
    }
    await batch.commit();
    if (kDebugMode) print('[SeedData] Seeded ${customers.length} customers.');
  }

  // ─── Orders ───────────────────────────────────────────────────────────────

  static Future<void> _seedOrders() async {
    final existing = await _db.collection('Orders').limit(1).get();
    if (existing.docs.isNotEmpty) {
      if (kDebugMode) print('[SeedData] Orders already seeded, skipping.');
      return;
    }

    final now = DateTime.now();

    final orders = [
      // Sarah Johnson — cust_001
      {
        'id': 'ord_001',
        'customerId': 'cust_001',
        'customerName': 'Sarah Johnson',
        'customerEmail': 'sarah.johnson@email.com',
        'orderStatus': 'Delivered',
        'paymentStatus': 'Paid',
        'totalAmount': 148.50,
        'subtotal': 133.50,
        'couponCode': 'SAVE10',
        'couponDiscount': 13.35,
        'shippingFee': 15.00,
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 2))),
        'shippingAddress': {
          'name': 'Sarah Johnson',
          'city': 'New York',
          'phoneNumber': '+1 (555) 234-5678',
          'address': '124 West 5th Street, Apt 3B',
        },
        'items': [
          {
            'productId': 'prod_101',
            'productName': 'Vitamin C 1000mg',
            'price': 24.99,
            'quantity': 2,
          },
          {
            'productId': 'prod_102',
            'productName': 'Omega-3 Fish Oil',
            'price': 34.99,
            'quantity': 1,
          },
          {
            'productId': 'prod_103',
            'productName': 'Zinc + Selenium Capsules',
            'price': 18.99,
            'quantity': 2,
          },
        ],
      },
      {
        'id': 'ord_002',
        'customerId': 'cust_001',
        'customerName': 'Sarah Johnson',
        'customerEmail': 'sarah.johnson@email.com',
        'orderStatus': 'Shipped',
        'paymentStatus': 'Paid',
        'totalAmount': 89.97,
        'subtotal': 74.97,
        'couponCode': '',
        'couponDiscount': 0.0,
        'shippingFee': 15.00,
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 1))),
        'shippingAddress': {
          'name': 'Sarah Johnson',
          'city': 'New York',
          'phoneNumber': '+1 (555) 234-5678',
          'address': '124 West 5th Street, Apt 3B',
        },
        'items': [
          {
            'productId': 'prod_104',
            'productName': 'Magnesium Glycinate',
            'price': 29.99,
            'quantity': 1,
          },
          {
            'productId': 'prod_105',
            'productName': 'Probiotic 50 Billion CFU',
            'price': 44.98,
            'quantity': 1,
          },
        ],
      },
      // Today's order for Sarah
      {
        'id': 'ord_003',
        'customerId': 'cust_001',
        'customerName': 'Sarah Johnson',
        'customerEmail': 'sarah.johnson@email.com',
        'orderStatus': 'Pending',
        'paymentStatus': 'Paid',
        'totalAmount': 62.98,
        'subtotal': 47.98,
        'couponCode': '',
        'couponDiscount': 0.0,
        'shippingFee': 15.00,
        'createdAt': Timestamp.fromDate(
          DateTime(now.year, now.month, now.day, 9, 15),
        ),
        'shippingAddress': {
          'name': 'Sarah Johnson',
          'city': 'New York',
          'phoneNumber': '+1 (555) 234-5678',
          'address': '124 West 5th Street, Apt 3B',
        },
        'items': [
          {
            'productId': 'prod_106',
            'productName': 'Collagen Peptides Powder',
            'price': 47.98,
            'quantity': 1,
          },
        ],
      },

      // Michael Chen — cust_002
      {
        'id': 'ord_004',
        'customerId': 'cust_002',
        'customerName': 'Michael Chen',
        'customerEmail': 'michael.chen@email.com',
        'orderStatus': 'Processing',
        'paymentStatus': 'Paid',
        'totalAmount': 115.95,
        'subtotal': 100.95,
        'couponCode': 'MEDI15',
        'couponDiscount': 15.14,
        'shippingFee': 15.00,
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 3))),
        'shippingAddress': {
          'name': 'Michael Chen',
          'city': 'San Francisco',
          'phoneNumber': '+1 (555) 876-5432',
          'address': '45 Market Street, Suite 200',
        },
        'items': [
          {
            'productId': 'prod_107',
            'productName': 'Melatonin 5mg',
            'price': 19.99,
            'quantity': 1,
          },
          {
            'productId': 'prod_108',
            'productName': 'Vitamin D3 5000 IU',
            'price': 22.99,
            'quantity': 2,
          },
          {
            'productId': 'prod_109',
            'productName': 'B-Complex Vitamins',
            'price': 26.99,
            'quantity': 1,
          },
        ],
      },
      // Today's order for Michael
      {
        'id': 'ord_005',
        'customerId': 'cust_002',
        'customerName': 'Michael Chen',
        'customerEmail': 'michael.chen@email.com',
        'orderStatus': 'Pending',
        'paymentStatus': 'Unpaid',
        'totalAmount': 54.98,
        'subtotal': 39.98,
        'couponCode': '',
        'couponDiscount': 0.0,
        'shippingFee': 15.00,
        'createdAt': Timestamp.fromDate(
          DateTime(now.year, now.month, now.day, 11, 30),
        ),
        'shippingAddress': {
          'name': 'Michael Chen',
          'city': 'San Francisco',
          'phoneNumber': '+1 (555) 876-5432',
          'address': '45 Market Street, Suite 200',
        },
        'items': [
          {
            'productId': 'prod_110',
            'productName': 'Ashwagandha Extract 600mg',
            'price': 39.98,
            'quantity': 1,
          },
        ],
      },

      // Emily Rodriguez — cust_003
      {
        'id': 'ord_006',
        'customerId': 'cust_003',
        'customerName': 'Emily Rodriguez',
        'customerEmail': 'emily.rodriguez@email.com',
        'orderStatus': 'Delivered',
        'paymentStatus': 'Paid',
        'totalAmount': 213.93,
        'subtotal': 193.93,
        'couponCode': 'BULK20',
        'couponDiscount': 38.79,
        'shippingFee': 20.00,
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 5))),
        'shippingAddress': {
          'name': 'Emily Rodriguez',
          'city': 'Chicago',
          'phoneNumber': '+1 (555) 345-6789',
          'address': '800 N Michigan Ave, Apt 12',
        },
        'items': [
          {
            'productId': 'prod_111',
            'productName': 'Iron Bisglycinate 25mg',
            'price': 22.99,
            'quantity': 3,
          },
          {
            'productId': 'prod_112',
            'productName': 'Turmeric Curcumin 1000mg',
            'price': 32.99,
            'quantity': 2,
          },
          {
            'productId': 'prod_113',
            'productName': 'CoQ10 200mg Softgels',
            'price': 44.99,
            'quantity': 1,
          },
        ],
      },
      // Today's order for Emily
      {
        'id': 'ord_007',
        'customerId': 'cust_003',
        'customerName': 'Emily Rodriguez',
        'customerEmail': 'emily.rodriguez@email.com',
        'orderStatus': 'Processing',
        'paymentStatus': 'Paid',
        'totalAmount': 79.98,
        'subtotal': 64.98,
        'couponCode': '',
        'couponDiscount': 0.0,
        'shippingFee': 15.00,
        'createdAt': Timestamp.fromDate(
          DateTime(now.year, now.month, now.day, 14, 0),
        ),
        'shippingAddress': {
          'name': 'Emily Rodriguez',
          'city': 'Chicago',
          'phoneNumber': '+1 (555) 345-6789',
          'address': '800 N Michigan Ave, Apt 12',
        },
        'items': [
          {
            'productId': 'prod_114',
            'productName': 'Biotin 10000mcg',
            'price': 32.49,
            'quantity': 2,
          },
        ],
      },

      // James Patel — cust_004
      {
        'id': 'ord_008',
        'customerId': 'cust_004',
        'customerName': 'James Patel',
        'customerEmail': 'james.patel@email.com',
        'orderStatus': 'Pending',
        'paymentStatus': 'Unpaid',
        'totalAmount': 99.97,
        'subtotal': 84.97,
        'couponCode': '',
        'couponDiscount': 0.0,
        'shippingFee': 15.00,
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 1))),
        'shippingAddress': {
          'name': 'James Patel',
          'city': 'Houston',
          'phoneNumber': '+1 (555) 987-1234',
          'address': '310 Texas Ave, Unit 5',
        },
        'items': [
          {
            'productId': 'prod_115',
            'productName': 'Multivitamin Complete',
            'price': 42.99,
            'quantity': 1,
          },
          {
            'productId': 'prod_116',
            'productName': 'Electrolyte Powder Packets',
            'price': 41.98,
            'quantity': 1,
          },
        ],
      },

      // Olivia Kim — cust_005
      {
        'id': 'ord_009',
        'customerId': 'cust_005',
        'customerName': 'Olivia Kim',
        'customerEmail': 'olivia.kim@email.com',
        'orderStatus': 'Shipped',
        'paymentStatus': 'Paid',
        'totalAmount': 167.95,
        'subtotal': 152.95,
        'couponCode': 'FIRST5',
        'couponDiscount': 7.65,
        'shippingFee': 15.00,
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 4))),
        'shippingAddress': {
          'name': 'Olivia Kim',
          'city': 'Los Angeles',
          'phoneNumber': '+1 (555) 654-3210',
          'address': '1200 Sunset Blvd, Apt 7C',
        },
        'items': [
          {
            'productId': 'prod_117',
            'productName': 'Collagen + Hyaluronic Acid',
            'price': 54.99,
            'quantity': 1,
          },
          {
            'productId': 'prod_118',
            'productName': 'Glutathione 500mg',
            'price': 48.99,
            'quantity': 1,
          },
          {
            'productId': 'prod_119',
            'productName': 'NAC N-Acetyl Cysteine',
            'price': 24.99,
            'quantity': 2,
          },
        ],
      },
      // Today's order for Olivia
      {
        'id': 'ord_010',
        'customerId': 'cust_005',
        'customerName': 'Olivia Kim',
        'customerEmail': 'olivia.kim@email.com',
        'orderStatus': 'Delivered',
        'paymentStatus': 'Paid',
        'totalAmount': 108.97,
        'subtotal': 93.97,
        'couponCode': '',
        'couponDiscount': 0.0,
        'shippingFee': 15.00,
        'createdAt': Timestamp.fromDate(
          DateTime(now.year, now.month, now.day, 8, 45),
        ),
        'shippingAddress': {
          'name': 'Olivia Kim',
          'city': 'Los Angeles',
          'phoneNumber': '+1 (555) 654-3210',
          'address': '1200 Sunset Blvd, Apt 7C',
        },
        'items': [
          {
            'productId': 'prod_120',
            'productName': 'Spirulina Powder 500g',
            'price': 34.99,
            'quantity': 1,
          },
          {
            'productId': 'prod_121',
            'productName': 'Chlorella Tablets 500mg',
            'price': 28.99,
            'quantity': 2,
          },
        ],
      },
    ];

    final batch = _db.batch();
    for (final o in orders) {
      final id = o['id'] as String;
      final data = Map<String, dynamic>.from(o)..remove('id');
      batch.set(_db.collection('Orders').doc(id), data);
    }
    await batch.commit();
    if (kDebugMode) print('[SeedData] Seeded ${orders.length} orders.');
  }
}
