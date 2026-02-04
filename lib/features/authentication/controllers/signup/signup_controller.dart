import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:med/data/repositories/authentication/authentication_repository.dart';
import 'package:med/utils/exceptions/firebase_auth_exceptions.dart';
import 'package:med/utils/exceptions/firebase_exceptions.dart';
import 'package:med/utils/exceptions/platform_exceptions.dart';
import 'package:med/utils/validators/validation.dart';
import 'package:med/data/repositories/user/user_repository.dart';
import 'package:med/features/authentication/screens/signup/verify_email.dart';
import 'package:med/features/personalization/models/user_model.dart';
import 'package:med/utils/helpers/network_manager.dart';
import 'package:med/utils/constants/image_strings.dart';
import 'package:med/utils/popups/full_screen_loader.dart';
import 'package:med/utils/popups/loaders.dart';

class SignupController extends GetxController {
  static SignupController get instance => Get.find();

  /// Variables
  final hidePassword = true.obs;
  final privacyPolicy = true.obs;
  final email = TextEditingController(); // Controller for email input
  final lastName = TextEditingController(); // Controller for last name input
  final username = TextEditingController(); // Controller for username input
  final password = TextEditingController(); // Controller for password input
  final firstName = TextEditingController(); // Controller for first name input
  final phoneNumber =
      TextEditingController(); // Controller for phone number input

  GlobalKey<FormState> signupFormKey =
      GlobalKey<FormState>(); // Form key for form validation

  /// - Signup
  void signup() async {
    try {
      // start loading
      MFullScreenLoader.openLoadingDialog(
        'We are processing your information',
        MImages.deliveredEmailIllustration,
      );
      // check internet connectivity
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        print("rola 1");
        return;
      }

      // Print all input values for debugging
      print(
        '[Signup] Inputs -> firstName:${firstName.text}, lastName:${lastName.text}, username:${username.text}, email:${email.text}, phone:${phoneNumber.text}, password:${password.text}',
      );

      // Print individual validator results to see which field fails
      print(
        '[Signup][validate] firstName: ${MValidator.validateEmptyText('First Name', firstName.text)}',
      );
      print(
        '[Signup][validate] lastName: ${MValidator.validateEmptyText('Last Name', lastName.text)}',
      );
      print(
        '[Signup][validate] username: ${MValidator.validateEmptyText('Username', username.text)}',
      );
      print(
        '[Signup][validate] email: ${MValidator.validateEmail(email.text)}',
      );
      print(
        '[Signup][validate] phone: ${MValidator.validatePhoneNumber(phoneNumber.text)}',
      );
      print(
        '[Signup][validate] password: ${MValidator.validatePassword(password.text)}',
      );

      // Form Validation
      if (!signupFormKey.currentState!.validate()) {
        print("rola 2");
        return;
      }

      // Check Pricacy Policy
      if (!privacyPolicy.value) {
        MLoaders.warningSnackBar(
          title: 'Accept Privacy Policy',
          message:
              'In order to create account, you must have to read and accept the Privacy Policy & Terms of Use.',
        );
        print("THis is the issue i think sso");
        return;
      }
      print("all clear");
      // Register user in the Firebase Authentication & save user data in the firebase
      final userCredential = await AuthenticationRepository.instance
          .registerWithEmailAndPassword(
            email.text.trim(),
            password.text.trim(),
          );
      // Save Authenticated user in the firebase.
      final newUser = UserModel(
        id: userCredential.user!.uid,
        firstName: firstName.text.trim(),
        lastName: lastName.text.trim(),
        username: username.text.trim(),
        email: email.text.trim(),
        phoneNumber: phoneNumber.text.trim(),
        profilePicture: '',
      );

      final userRepository = Get.put(UserRepository());
      await userRepository.saveUserRecord(newUser);

      // show success message
      MLoaders.successSnackBar(
        title: 'Congratulations',
        message: 'Your account has been created! Verify email to continue.',
      );
      // Move to verify Email screen
      Get.to(() => VerifyEmailScreen(email: email.text.trim()));
    } catch (e) {
      // Remove loader
      MFullScreenLoader.stopLoading();
      // Map known exceptions to friendly messages
      String message;
      if (e is MFirebaseAuthException) {
        message = e.message;
      } else if (e is MFirebaseException) {
        message = e.message;
      } else if (e is MPlatformException) {
        message = e.message;
      } else {
        message = e.toString();
      }

      MLoaders.errorSnackBar(title: 'Oh Snap!', message: message);
    }
  }
}
