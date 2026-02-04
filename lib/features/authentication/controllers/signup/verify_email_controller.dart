import 'dart:async' as async;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:med/common/widgets/success_screen/success_screen.dart';
import 'package:med/data/repositories/authentication/authentication_repository.dart';
import 'package:med/utils/constants/image_strings.dart';
import 'package:med/utils/constants/text_strings.dart';
import 'package:med/utils/popups/loaders.dart';

class VerifyEmailController extends GetxController {
  static VerifyEmailController get instance => Get.find();

  /// Send Email Whenever Verify Screen appears & Set Timer for auto redirect.
  @override
  void onInit() {
    // Do not automatically send verification or start reload timer on init.
    // This avoids triggering native network/plugin behavior unexpectedly
    // (for example, when the user follows an email link that opens the app).
    super.onInit();
  }

  /// Send Email Verification link
  sendEmailVerification() async {
    try {
      await AuthenticationRepository.instance.sendEmailVerification();
      MLoaders.successSnackBar(
        title: 'Email Sent',
        message: 'Please check your mail and verify email.',
      );
    } catch (e) {
      MLoaders.errorSnackBar(title: 'Oh Snap!', message: e.toString());
    }
  }

  /// Timer to automatically redirect on Email Verification
  void setTimerForAutoRedirect() {
    async.Timer.periodic(const Duration(seconds: 1), (timer) async {
      try {
        await FirebaseAuth.instance.currentUser?.reload();
      } catch (e) {
        // Log and show a friendly message, but don't crash the app if native reload fails
        print('[VerifyEmail] Error reloading user: $e');
        MLoaders.errorSnackBar(
          title: 'Network Error',
          message: 'Could not verify email status right now. Please try again.',
        );
        return;
      }

      final user = FirebaseAuth.instance.currentUser;

      if (user?.emailVerified ?? false) {
        timer.cancel();

        Get.off(
          () => SuccessScreen(
            image: MImages.staticSuccessIllustration,
            title: MTexts.yourAccountCreatedTitle,
            subTitle: MTexts.yourAccountCreatedSubTitle,
            onPressed: () => AuthenticationRepository.instance.screenRedirect(),
          ),
        );
      }
    });
  }

  /// Manually Check if Email Verified
  checkEmailVerificationStatus() async {
    print(FirebaseAuth.instance.currentUser);
    try {
      await FirebaseAuth.instance.currentUser?.reload();
    } catch (e) {
      print('[VerifyEmail] Error reloading user (manual check): $e');
      MLoaders.errorSnackBar(
        title: 'Network Error',
        message: 'Could not verify email status right now. Please try again.',
      );
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null && currentUser.emailVerified) {
      Get.off(
        () => SuccessScreen(
          image: MImages.staticSuccessIllustration,
          title: MTexts.yourAccountCreatedTitle,
          subTitle: MTexts.yourAccountCreatedSubTitle,
          onPressed: () => AuthenticationRepository.instance.screenRedirect(),
        ),
      );
    }
  }
}
