import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:med/data/repositories/authentication/authentication_repository.dart';
import 'package:med/data/repositories/user/user_repository.dart';
import 'package:med/features/personalization/models/user_model.dart';
import 'package:med/utils/popups/full_screen_loader.dart';
import 'package:med/utils/popups/loaders.dart';
import 'package:med/utils/constants/image_strings.dart';
import 'package:med/utils/exceptions/firebase_auth_exceptions.dart';
import 'package:med/utils/exceptions/firebase_exceptions.dart';
import 'package:med/utils/exceptions/platform_exceptions.dart';

class SocialAuthController extends GetxController {
  static SocialAuthController get instance => Get.find();

  // ─── Google Sign-In ───────────────────────────────────────────────────────

  Future<void> googleSignIn() async {
    try {
      MFullScreenLoader.openLoadingDialog(
        'Signing in with Google...',
        MImages.deliveredEmailIllustration,
      );

      final userCredential =
          await AuthenticationRepository.instance.signInWithGoogle();

      await _saveUserToFirestoreIfNew(userCredential);

      MFullScreenLoader.stopLoading();
      AuthenticationRepository.instance.screenRedirect();
    } on MFirebaseAuthException catch (e) {
      MFullScreenLoader.stopLoading();
      MLoaders.errorSnackBar(title: 'Google Sign-In Failed', message: e.message);
    } on MFirebaseException catch (e) {
      MFullScreenLoader.stopLoading();
      MLoaders.errorSnackBar(title: 'Google Sign-In Failed', message: e.message);
    } on MPlatformException catch (e) {
      MFullScreenLoader.stopLoading();
      MLoaders.errorSnackBar(title: 'Google Sign-In Failed', message: e.message);
    } catch (e) {
      MFullScreenLoader.stopLoading();
      MLoaders.errorSnackBar(
        title: 'Oh Snap!',
        message: e.toString(),
      );
    }
  }

  // ─── Facebook Sign-In ─────────────────────────────────────────────────────

  Future<void> facebookSignIn() async {
    try {
      MFullScreenLoader.openLoadingDialog(
        'Signing in with Facebook...',
        MImages.deliveredEmailIllustration,
      );

      final userCredential =
          await AuthenticationRepository.instance.signInWithFacebook();

      await _saveUserToFirestoreIfNew(userCredential);

      MFullScreenLoader.stopLoading();
      AuthenticationRepository.instance.screenRedirect();
    } on MFirebaseAuthException catch (e) {
      MFullScreenLoader.stopLoading();
      MLoaders.errorSnackBar(title: 'Facebook Sign-In Failed', message: e.message);
    } on MFirebaseException catch (e) {
      MFullScreenLoader.stopLoading();
      MLoaders.errorSnackBar(title: 'Facebook Sign-In Failed', message: e.message);
    } on MPlatformException catch (e) {
      MFullScreenLoader.stopLoading();
      MLoaders.errorSnackBar(title: 'Facebook Sign-In Failed', message: e.message);
    } catch (e) {
      MFullScreenLoader.stopLoading();
      MLoaders.errorSnackBar(
        title: 'Oh Snap!',
        message: e.toString(),
      );
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  /// Create a Firestore user document only on first sign-in.
  Future<void> _saveUserToFirestoreIfNew(UserCredential userCredential) async {
    if (userCredential.user == null) return;
    final isNew = userCredential.additionalUserInfo?.isNewUser ?? false;
    if (!isNew) return; // existing user – no need to create document again

    final firebaseUser = userCredential.user!;
    final nameParts = UserModel.nameParts(firebaseUser.displayName ?? '');
    final username = UserModel.generateUsername(firebaseUser.displayName ?? '');

    final newUser = UserModel(
      id: firebaseUser.uid,
      firstName: nameParts.isNotEmpty ? nameParts[0] : '',
      lastName: nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '',
      username: username,
      email: firebaseUser.email ?? '',
      phoneNumber: firebaseUser.phoneNumber ?? '',
      profilePicture: firebaseUser.photoURL ?? '',
    );

    await Get.put(UserRepository()).saveUserRecord(newUser);
  }
}
