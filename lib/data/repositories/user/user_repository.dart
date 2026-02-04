import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:med/features/personalization/models/user_model.dart';
import 'package:med/utils/exceptions/firebase_exceptions.dart';
import 'package:med/utils/exceptions/format_exceptions.dart';
import 'package:med/utils/exceptions/platform_exceptions.dart';

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

  /// Function to fetch user details based on user ID.

  /// Function to update user data in Firestore.

  /// Update any field in specific Users Collection
}
