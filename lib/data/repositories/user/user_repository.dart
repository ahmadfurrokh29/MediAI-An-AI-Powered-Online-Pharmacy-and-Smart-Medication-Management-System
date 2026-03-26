import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:med/features/personalization/models/user_model.dart';

/// Repository class for user-related operations.
class UserRepository extends GetxController {
  static UserRepository get instance => Get.find();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Function to save user data to Firestore.
  Future<void> saveUserRecord(UserModel user) async {
    try {
      // Debug: print the payload being sent to Firestore
      print(user);
      print(user.toJson());
      final payload = user.toJson();
      print(
        '[UserRepo] Saving user record for uid=${user.id} payload=${payload}',
      );
      await _db.collection("Users").doc(user.id).set(payload);
    } on FirebaseException catch (e) {
      print('[UserRepo][FirebaseException] ${e.code} ${e.message}');
      rethrow;
    } on FormatException catch (_) {
      print('[UserRepo][FormatException]');
      rethrow;
    } on PlatformException catch (e) {
      print('[UserRepo][PlatformException] ${e.code} ${e.message}');
      rethrow;
    } catch (e) {
      print('[UserRepo][UnknownError] $e');
      rethrow;
    }
  }

  /// Ensures the user document has every customer field required by the Admin
  /// panel and backfills them on existing / pre-field-introduction accounts.
  ///
  /// Safe to call on every login — only writes fields that are actually missing
  /// so it never clobbers data the user already has.
  Future<void> ensureCustomerRole(String uid, {String? email}) async {
    try {
      final ref = _db.collection('Users').doc(uid);
      final snap = await ref.get();

      if (!snap.exists) {
        // Document was never created (edge-case: social sign-in on old account)
        await ref.set({
          'role': 'Customer',
          'createdAt': FieldValue.serverTimestamp(),
          'isEmailVerified': true,
          'points': 0,
          'orderCount': 0,
          'addresses': <Map<String, dynamic>>[],
          'selectedAddressIndex': 0,
          'shippingAddress': <String, dynamic>{},
          if (email != null) ...{'Email': email, 'email': email},
        });
        print('[UserRepo] Created missing Users doc for uid=$uid');
        return;
      }

      final data = snap.data() ?? {};
      final Map<String, dynamic> patch = {};

      // Backfill role
      if (data['role'] == null) patch['role'] = 'Customer';
      // Backfill createdAt
      if (data['createdAt'] == null && data['CreatedAt'] == null) {
        patch['createdAt'] = FieldValue.serverTimestamp();
      }
      // Backfill customer counters / address
      if (data['points'] == null) patch['points'] = 0;
      if (data['orderCount'] == null && data['OrderCount'] == null) {
        patch['orderCount'] = 0;
      }
      // Backfill new addresses list schema
      if (data['addresses'] == null) {
        // Migrate legacy shippingAddress into the list if it has content
        final legacy =
            data['shippingAddress'] as Map<String, dynamic>? ??
            data['ShippingAddress'] as Map<String, dynamic>? ??
            {};
        final hasContent =
            (legacy['name'] as String? ?? '').isNotEmpty ||
            (legacy['street'] as String? ?? '').isNotEmpty ||
            (legacy['city'] as String? ?? '').isNotEmpty;
        patch['addresses'] = hasContent
            ? [Map<String, dynamic>.from(legacy)]
            : <Map<String, dynamic>>[];
        patch['selectedAddressIndex'] = 0;
        // Keep shippingAddress in sync with the selected address
        patch['shippingAddress'] = hasContent ? legacy : <String, dynamic>{};
      }
      if (data['shippingAddress'] == null && data['ShippingAddress'] == null) {
        patch['shippingAddress'] = <String, dynamic>{};
      }
      // Backfill camelCase email mirror (admin CustomerModel reads 'email')
      if (data['email'] == null) {
        final existingEmail = data['Email'] as String? ?? email ?? '';
        if (existingEmail.isNotEmpty) patch['email'] = existingEmail;
      }

      if (patch.isNotEmpty) {
        await ref.update(patch);
        print(
          '[UserRepo] Patched Users doc uid=$uid with keys: ${patch.keys.toList()}',
        );
      }
    } catch (e) {
      // Non-fatal – don't block navigation
      print('[UserRepo][ensureCustomerRole] $e');
    }
  }

  /// Syncs Firebase Auth's emailVerified flag into the Firestore document.
  Future<void> updateEmailVerifiedStatus(String uid, bool verified) async {
    try {
      await _db.collection('Users').doc(uid).update({
        'isEmailVerified': verified,
      });
    } catch (_) {}
  }

  /// Function to fetch user details based on user ID.
  Future<UserModel> fetchUserDetails() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return UserModel.empty();
    final doc = await _db.collection('Users').doc(uid).get();
    return UserModel.fromSnapshot(doc);
  }

  /// Save / overwrite the shippingAddress sub-document for the current user.
  /// Also keeps the legacy shippingAddress field in sync for admin panel reads.
  Future<void> saveAddress(String uid, Map<String, dynamic> address) async {
    await _db.collection('Users').doc(uid).update({'shippingAddress': address});
  }

  /// Update a single field in the Users document.
  Future<void> updateSingleField(String uid, Map<String, dynamic> json) async {
    await _db.collection('Users').doc(uid).update(json);
  }

  /// Function to update user data in Firestore.

  /// Update any field in specific Users Collection
}
