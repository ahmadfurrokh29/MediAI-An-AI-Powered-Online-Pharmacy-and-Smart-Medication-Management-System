import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:med/data/repositories/authentication/authentication_repository.dart';
import 'package:med/data/repositories/user/user_repository.dart';
import 'package:med/data/services/cloudinary_service.dart';
import 'package:med/features/personalization/models/user_model.dart';
import 'package:med/utils/constants/image_strings.dart';
import 'package:med/utils/helpers/network_manager.dart';
import 'package:med/utils/popups/full_screen_loader.dart';
import 'package:med/utils/popups/loaders.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserController extends GetxController {
  static UserController get instance => Get.find();

  final Rx<UserModel> user = UserModel.empty().obs;
  final RxBool isLoading = false.obs;
  final RxBool imageUploading = false.obs;
  final userRepository = Get.put(UserRepository());

  // Profile form controllers
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final usernameController = TextEditingController();
  final phoneNumberController = TextEditingController();
  final genderController = TextEditingController();
  final dateOfBirthController = TextEditingController();
  final profileFormKey = GlobalKey<FormState>();

  @override
  void onInit() {
    super.onInit();
    fetchUserRecord();
  }

  Future<void> fetchUserRecord() async {
    try {
      isLoading.value = true;
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (uid.isEmpty) return;
      final fetched = await UserRepository.instance.fetchUserDetails();
      user.value = fetched;
      _populateFormControllers();

      // One-time cleanup: remove duplicate camelCase fields from Firestore
      userRepository.cleanupDuplicateFields(uid);
    } catch (e) {
      user.value = UserModel.empty();
    } finally {
      isLoading.value = false;
    }
  }

  /// Populate form controllers with current user data.
  void _populateFormControllers() {
    firstNameController.text = user.value.firstName;
    lastNameController.text = user.value.lastName;
    usernameController.text = user.value.username;
    phoneNumberController.text = user.value.phoneNumber;
    genderController.text = user.value.gender;
    dateOfBirthController.text = user.value.dateOfBirth;
  }

  /// Upload profile image from gallery via Cloudinary.
  /// Deletes the previous Cloudinary image (if any) before uploading the new one.
  Future<void> uploadUserProfilePicture() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxHeight: 512,
        maxWidth: 512,
      );
      if (picked == null) return;

      imageUploading.value = true;

      final bytes = await picked.readAsBytes();
      final fileName = picked.name;

      // Delete old Cloudinary image if one exists
      final oldPublicId = user.value.profilePicturePublicId;
      if (oldPublicId.isNotEmpty) {
        await CloudinaryService.deleteImage(oldPublicId);
      }

      // Upload new image to Cloudinary
      final result = await CloudinaryService.uploadImage(
        bytes: bytes,
        fileName: fileName,
        folder: 'MediAI/Users/ProfilePictures',
      );

      // Save new URL + publicId to Firestore
      await userRepository.updateUserDetails({
        'ProfilePicture': result.url,
        'ProfilePicturePublicId': result.publicId,
      });

      user.value.profilePicture = result.url;
      user.value.profilePicturePublicId = result.publicId;
      user.refresh();

      MLoaders.successSnackBar(
        title: 'Success',
        message: 'Your profile image has been updated!',
      );
    } catch (e) {
      MLoaders.errorSnackBar(
        title: 'Error',
        message: 'Something went wrong: $e',
      );
    } finally {
      imageUploading.value = false;
    }
  }

  /// Save / update profile information.
  Future<void> saveProfile() async {
    try {
      // Close any open dialog first (edit name / phone / gender picker)
      if (Get.isDialogOpen == true) {
        Get.back();
      }

      MFullScreenLoader.openLoadingDialog(
        'Updating your profile...',
        MImages.deliveredEmailIllustration,
      );

      // Check internet
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        MFullScreenLoader.stopLoading();
        return;
      }

      // Only update the canonical PascalCase keys that already exist in Firestore
      final values = <String, dynamic>{
        'FirstName': firstNameController.text.trim(),
        'LastName': lastNameController.text.trim(),
        'PhoneNumber': phoneNumberController.text.trim(),
        'Gender': genderController.text.trim(),
        'DateOfBirth': dateOfBirthController.text.trim(),
      };

      await userRepository.updateUserDetails(values);

      // Update local user model
      user.value.firstName = firstNameController.text.trim();
      user.value.lastName = lastNameController.text.trim();
      user.value.phoneNumber = phoneNumberController.text.trim();
      user.value.gender = genderController.text.trim();
      user.value.dateOfBirth = dateOfBirthController.text.trim();
      user.refresh();

      MFullScreenLoader.stopLoading();

      MLoaders.successSnackBar(
        title: 'Success',
        message: 'Your profile has been updated.',
      );
    } catch (e) {
      // Safely try to close the loader
      try {
        MFullScreenLoader.stopLoading();
      } catch (_) {}
      MLoaders.errorSnackBar(
        title: 'Error',
        message: 'Something went wrong: $e',
      );
    }
  }

  /// Delete / close user account.
  Future<void> deleteUserAccount() async {
    try {
      MFullScreenLoader.openLoadingDialog(
        'Closing your account...',
        MImages.deliveredEmailIllustration,
      );

      final auth = FirebaseAuth.instance;
      final currentUser = auth.currentUser;
      if (currentUser == null) {
        MFullScreenLoader.stopLoading();
        return;
      }

      // Delete user data from Firestore
      await userRepository.removeUserRecord(currentUser.uid);

      // Delete user from Firebase Auth
      await currentUser.delete();

      MFullScreenLoader.stopLoading();

      MLoaders.successSnackBar(
        title: 'Account Deleted',
        message: 'Your account has been permanently closed.',
      );

      // Redirect to login
      AuthenticationRepository.instance.screenRedirect();
    } catch (e) {
      MFullScreenLoader.stopLoading();
      MLoaders.errorSnackBar(
        title: 'Error',
        message: 'Something went wrong: $e',
      );
    }
  }

  /// Change user password with re-authentication.
  Future<void> changePassword(String oldPassword, String newPassword) async {
    try {
      // Close any open dialog first
      if (Get.isDialogOpen == true) {
        Get.back();
      }

      MFullScreenLoader.openLoadingDialog(
        'Updating your password...',
        MImages.deliveredEmailIllustration,
      );

      // Check internet
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        MFullScreenLoader.stopLoading();
        return;
      }

      final authRepo = AuthenticationRepository.instance;
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null || currentUser.email == null) {
        MFullScreenLoader.stopLoading();
        MLoaders.errorSnackBar(
          title: 'Error',
          message: 'No authenticated user found.',
        );
        return;
      }

      // Re-authenticate with old password
      await authRepo.reAuthenticateWithEmailAndPassword(
        currentUser.email!,
        oldPassword,
      );

      // Update to new password
      await currentUser.updatePassword(newPassword);

      // Log the password change to Firestore
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUser.uid)
          .collection('PasswordChangeLogs')
          .add({
            'ChangedAt': FieldValue.serverTimestamp(),
            'Email': currentUser.email,
            'Platform': GetPlatform.isAndroid
                ? 'Android'
                : GetPlatform.isIOS
                ? 'iOS'
                : 'Web',
          });

      MFullScreenLoader.stopLoading();

      MLoaders.successSnackBar(
        title: 'Success',
        message: 'Your password has been updated successfully.',
      );
    } on FirebaseAuthException catch (e) {
      MFullScreenLoader.stopLoading();
      final msg = e.code == 'wrong-password' || e.code == 'invalid-credential'
          ? 'Current password is incorrect.'
          : e.message ?? 'Authentication failed.';
      MLoaders.errorSnackBar(title: 'Error', message: msg);
    } catch (e) {
      try {
        MFullScreenLoader.stopLoading();
      } catch (_) {}
      MLoaders.errorSnackBar(
        title: 'Error',
        message: 'Something went wrong: $e',
      );
    }
  }

  String get uid => FirebaseAuth.instance.currentUser?.uid ?? '';
}
