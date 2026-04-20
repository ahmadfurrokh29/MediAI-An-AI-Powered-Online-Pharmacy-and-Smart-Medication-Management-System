import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../models/user_model.dart';

class AuthService extends GetxService {
  static AuthService get instance => Get.find();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Get current user
  User? get currentFirebaseUser => _auth.currentUser;

  // Get user data stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Email & Password Sign In
  Future<UserCredential> loginWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Something went wrong. Please try again.';
    }
  }

  // Get User Data — checks Admins collection first, then Users
  Future<UserModel> getUserDetails(String uid) async {
    try {
      // Try Admins collection first (admin panel users)
      final adminSnap = await _db.collection('Admins').doc(uid).get();
      if (adminSnap.exists) {
        final data = adminSnap.data()!;
        return UserModel(
          id: adminSnap.id,
          email: data['Email'] ?? '',
          firstName: data['FirstName'] ?? '',
          lastName: data['LastName'] ?? '',
          username:
              '${(data['FirstName'] ?? '').toString().toLowerCase()}.${(data['LastName'] ?? '').toString().toLowerCase()}',
          phoneNumber: data['PhoneNumber'] ?? '',
          profilePicture: data['ProfilePicture'] ?? '',
          role: data['role'] ?? 'admin',
        );
      }

      // Fallback to Users collection
      final documentSnapshot = await _db.collection('Users').doc(uid).get();
      if (documentSnapshot.exists) {
        return UserModel.fromSnapshot(documentSnapshot);
      } else {
        throw 'User data not found';
      }
    } catch (e) {
      throw 'Failed to fetch user details: $e';
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw 'Failed to sign out: $e';
    }
  }

  // Handle Auth Exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many login attempts. Please try again later.';
      case 'invalid-credential':
        return 'Invalid credentials. Please check your email and password.';
      default:
        return 'Authentication failed: ${e.message}';
    }
  }

  // Verify if user is admin
  Future<bool> isUserAdmin(String uid) async {
    try {
      final user = await getUserDetails(uid);
      return user.isAdmin;
    } catch (e) {
      return false;
    }
  }
}
