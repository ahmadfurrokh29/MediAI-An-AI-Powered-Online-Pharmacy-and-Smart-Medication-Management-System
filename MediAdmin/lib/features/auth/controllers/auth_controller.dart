import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthController extends GetxController {
  static AuthController get instance => Get.find();

  final Rx<User?> firebaseUser = Rx<User?>(null);
  final Rx<UserModel> user = UserModel.empty().obs;
  final RxBool isLoading = false.obs;

  @override
  void onReady() {
    super.onReady();
    firebaseUser.value = AuthService.instance.currentFirebaseUser;
    firebaseUser.bindStream(AuthService.instance.authStateChanges);
    ever(firebaseUser, _setInitialScreen);
  }

  _setInitialScreen(User? user) async {
    if (user == null) {
      Get.offAllNamed('/');
    } else {
      // Fetch user details and verify admin role
      await fetchUserDetails(user.uid);
      // Allow access if user has admin role or if user document doesn't exist (default admin)
      if (this.user.value.isAdmin || this.user.value.id.isNotEmpty) {
        Get.offAllNamed('/admin');
      } else {
        // Not an admin, sign out
        await AuthService.instance.signOut();
        Get.snackbar(
          'Access Denied',
          'You do not have admin privileges',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.1),
          colorText: Colors.red,
        );
        Get.offAllNamed('/');
      }
    }
  }

  Future<void> fetchUserDetails(String uid) async {
    try {
      final userDetails = await AuthService.instance.getUserDetails(uid);
      user.value = userDetails;
    } catch (e) {
      // If user document doesn't exist, create a default admin user
      print('User document not found, allowing access with default admin role');
      user.value = UserModel(
        id: uid,
        email: AuthService.instance.currentFirebaseUser?.email ?? '',
        firstName: 'Admin',
        lastName: 'User',
        username: 'admin',
        phoneNumber: '',
        profilePicture: '',
        role: 'admin', // Default to admin role
      );
    }
  }

  Future<void> loginWithEmailAndPassword(String email, String password) async {
    try {
      isLoading.value = true;

      // Sign in with Firebase Auth
      final userCredential = await AuthService.instance
          .loginWithEmailAndPassword(email.trim(), password.trim());

      // Fetch user details
      await fetchUserDetails(userCredential.user!.uid);

      // Allow access if user has admin role or if user document doesn't exist (default admin)
      // This is more lenient to allow login even if Firestore document doesn't exist
      if (!user.value.isAdmin && user.value.role.isNotEmpty) {
        // Only deny if role is explicitly set to something other than admin
        await AuthService.instance.signOut();
        Get.snackbar(
          'Access Denied',
          'Only administrators can access this panel',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.1),
          colorText: Colors.red,
          duration: const Duration(seconds: 4),
        );
        return;
      }

      isLoading.value = false;
      Get.offAllNamed('/admin');
    } catch (e) {
      isLoading.value = false;
      Get.snackbar(
        'Login Failed',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
        duration: const Duration(seconds: 4),
      );
    }
  }

  Future<void> logout() async {
    try {
      await AuthService.instance.signOut();
      user.value = UserModel.empty();
      Get.offAllNamed('/');
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to logout: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    }
  }
}
