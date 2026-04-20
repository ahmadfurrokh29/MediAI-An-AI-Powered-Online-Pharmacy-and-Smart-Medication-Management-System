import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import '../../../firebase_options.dart';
import '../models/admin_model.dart';

class AdminController extends GetxController {
  static AdminController get instance => Get.find();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final RxList<AdminModel> admins = <AdminModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isCreating = false.obs;
  final RxString searchQuery = ''.obs;
  final RxBool hasInitialized = false.obs;

  Future<void> initialize() async {
    if (!hasInitialized.value) {
      await fetchAdmins();
      hasInitialized.value = true;
    }
  }

  List<AdminModel> get filteredAdmins {
    final all = admins.toList();
    if (searchQuery.value.isEmpty) return all;
    final q = searchQuery.value.toLowerCase();
    return all.where((a) {
      return a.fullName.toLowerCase().contains(q) ||
          a.email.toLowerCase().contains(q) ||
          a.phoneNumber.toLowerCase().contains(q);
    }).toList();
  }

  //  Fetch all admins
  // Admins live ONLY in the Admins collection.
  // Users collection is exclusively for e-commerce customers.
  Future<void> fetchAdmins() async {
    try {
      isLoading.value = true;

      final snapshot = await _db
          .collection('Admins')
          .orderBy('CreatedAt', descending: true)
          .get();

      final fetched = snapshot.docs
          .map((doc) => AdminModel.fromSnapshot(doc))
          .toList();

      // Auto-register the current logged-in admin if not in Admins collection yet
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final existsInList = fetched.any((a) => a.id == currentUser.uid);
        if (!existsInList) {
          String firstName = 'Admin';
          String lastName = '';
          String phoneNumber = '';
          final email = currentUser.email ?? '';

          // Try to get display name from Firebase Auth
          final displayName = currentUser.displayName ?? '';
          final parts = displayName.trim().split(' ');
          if (parts.isNotEmpty && parts[0].isNotEmpty) {
            firstName = parts[0];
            lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
          }

          final selfAdmin = AdminModel(
            id: currentUser.uid,
            firstName: firstName,
            lastName: lastName,
            email: email,
            phoneNumber: phoneNumber,
            profilePicture: currentUser.photoURL ?? '',
            role: 'admin',
            isActive: true,
            createdAt: DateTime.now(),
          );

          // Write ONLY to Admins collection  NOT to Users (customers only)
          await _db
              .collection('Admins')
              .doc(currentUser.uid)
              .set(selfAdmin.toJson());

          fetched.insert(0, selfAdmin);
          print(' Auto-registered current admin in Admins collection');
        }
      }

      admins.value = fetched;
      print(' Successfully fetched ${admins.length} admins');
    } catch (e) {
      print(' Failed to fetch admins: $e');
      admins.value = [];
    } finally {
      isLoading.value = false;
    }
  }

  //  Create new admin
  // Uses a secondary FirebaseApp to create the Firebase Auth account without
  // signing out the current admin. Writes ONLY to the Admins collection.
  Future<bool> createAdmin({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String phoneNumber = '',
  }) async {
    FirebaseApp? secondaryApp;
    try {
      isCreating.value = true;

      // Step 1: Spin up a uniquely-named secondary Firebase app
      final appName = 'adminCreate_${DateTime.now().millisecondsSinceEpoch}';
      secondaryApp = await Firebase.initializeApp(
        name: appName,
        options: DefaultFirebaseOptions.currentPlatform,
      );

      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      // Step 2: Create the new Firebase Auth account
      final UserCredential newUserCred = await secondaryAuth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password.trim(),
          );
      final String newUid = newUserCred.user!.uid;

      try {
        await newUserCred.user!.updateDisplayName(
          '${firstName.trim()} ${lastName.trim()}',
        );
      } catch (_) {}

      // Step 3: Build the AdminModel
      final adminModel = AdminModel(
        id: newUid,
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        email: email.trim(),
        phoneNumber: phoneNumber.trim(),
        profilePicture: '',
        role: 'admin',
        isActive: true,
        createdAt: DateTime.now(),
      );

      // Step 4: Write ONLY to Admins collection  admins are NOT in Users
      await _db.collection('Admins').doc(newUid).set(adminModel.toJson());

      // Sign out of secondary  no longer needed
      await secondaryAuth.signOut();

      // Step 5: Update local reactive list
      admins.insert(0, adminModel);

      Get.snackbar(
        ' Success',
        'Admin "${adminModel.fullName}" created successfully.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );

      return true;
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'This email is already registered.';
          break;
        case 'weak-password':
          message = 'Password is too weak (minimum 6 characters).';
          break;
        case 'invalid-email':
          message = 'The email address is not valid.';
          break;
        default:
          message = e.message ?? 'Authentication error.';
      }
      Get.snackbar(
        ' Error',
        message,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
      return false;
    } catch (e) {
      Get.snackbar(
        ' Error',
        'Failed to create admin: $e',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
      return false;
    } finally {
      isCreating.value = false;
      try {
        await secondaryApp?.delete();
      } catch (_) {}
    }
  }

  //  Toggle active / inactive status
  Future<void> toggleStatus(String adminId, bool value) async {
    try {
      await _db.collection('Admins').doc(adminId).update({'IsActive': value});
      final idx = admins.indexWhere((a) => a.id == adminId);
      if (idx != -1) {
        admins[idx] = admins[idx].copyWith(isActive: value);
        admins.refresh();
      }
    } catch (e) {
      Get.snackbar(' Error', 'Failed to update status: $e');
    }
  }

  //  Update admin details
  Future<bool> updateAdmin({
    required String id,
    required String firstName,
    required String lastName,
    String phoneNumber = '',
    bool isActive = true,
  }) async {
    try {
      await _db.collection('Admins').doc(id).update({
        'FirstName': firstName.trim(),
        'LastName': lastName.trim(),
        'PhoneNumber': phoneNumber.trim(),
        'IsActive': isActive,
      });

      final idx = admins.indexWhere((a) => a.id == id);
      if (idx != -1) {
        admins[idx] = admins[idx].copyWith(
          firstName: firstName.trim(),
          lastName: lastName.trim(),
          phoneNumber: phoneNumber.trim(),
          isActive: isActive,
        );
        admins.refresh();
      }

      Get.snackbar(
        'Success',
        'Admin updated successfully.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
      return true;
    } catch (e) {
      Get.snackbar('Error', 'Failed to update admin: $e');
      return false;
    }
  }

  //  Delete admin
  // Deletes only from Admins collection  Users collection is untouched
  Future<void> deleteAdmin(String adminId) async {
    try {
      await _db.collection('Admins').doc(adminId).delete();
      admins.removeWhere((a) => a.id == adminId);

      Get.snackbar(
        ' Deleted',
        'Admin removed successfully.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(' Error', 'Failed to delete admin: $e');
    }
  }

  /// Change the password for an admin identified by [email].
  ///
  /// Re-authenticates using [currentPassword], then updates to [newPassword].
  /// Uses a secondary FirebaseApp so the currently logged-in session is not
  /// affected when the target admin is a *different* user.  If the target
  /// is the *current* user we re-authenticate on the primary instance instead.
  Future<bool> changeAdminPassword({
    required String adminId,
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {
    FirebaseApp? secondaryApp;
    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null && currentUser.uid == adminId) {
        // ── Changing the *current* user's own password ──
        final cred = EmailAuthProvider.credential(
          email: email,
          password: currentPassword,
        );
        await currentUser.reauthenticateWithCredential(cred);
        await currentUser.updatePassword(newPassword);
      } else {
        // ── Changing *another* admin's password ──
        final appName = 'pwdChange_${DateTime.now().millisecondsSinceEpoch}';
        secondaryApp = await Firebase.initializeApp(
          name: appName,
          options: DefaultFirebaseOptions.currentPlatform,
        );
        final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

        // Sign in as that admin to re-authenticate
        final userCred = await secondaryAuth.signInWithEmailAndPassword(
          email: email,
          password: currentPassword,
        );
        await userCred.user!.updatePassword(newPassword);
        await secondaryAuth.signOut();
      }

      Get.snackbar(
        'Success',
        'Password changed successfully.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
      return true;
    } on FirebaseAuthException catch (e) {
      String msg;
      switch (e.code) {
        case 'wrong-password':
          msg = 'The current password is incorrect.';
          break;
        case 'weak-password':
          msg = 'New password is too weak (minimum 6 characters).';
          break;
        case 'user-not-found':
          msg = 'No account found for this email.';
          break;
        case 'too-many-requests':
          msg = 'Too many attempts. Please try again later.';
          break;
        default:
          msg = e.message ?? 'Authentication error.';
      }
      Get.snackbar(
        'Error',
        msg,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
      return false;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to change password: $e',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
      return false;
    } finally {
      try {
        await secondaryApp?.delete();
      } catch (_) {}
    }
  }
}
