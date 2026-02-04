import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:med/features/authentication/screens/login/login.dart';
import 'package:med/features/authentication/screens/onboarding/onboarding.dart';
import 'package:med/features/authentication/screens/signup/verify_email.dart';
import 'package:med/navigation_menu.dart';
import 'package:med/utils/exceptions/firebase_auth_exceptions.dart';
import 'package:med/utils/exceptions/firebase_exceptions.dart';
import 'package:med/utils/exceptions/format_exceptions.dart';
import 'package:med/utils/exceptions/platform_exceptions.dart';

class AuthenticationRepository extends GetxController {
  static AuthenticationRepository get instance => Get.find();

  /// Variables
  final deviceStorage = GetStorage();
  final _auth = FirebaseAuth.instance;

  /// Called from main.dart on app launch
  @override
  void onReady() {
    FlutterNativeSplash.remove();
    screenRedirect();
  }

  /// Function to Show Relevant Screen
  screenRedirect() async {
    final user = _auth.currentUser;
    if (user != null) {
      if (user.emailVerified) {
        Get.offAll(() => const NavigationMenu());
      } else {
        Get.offAll(() => VerifyEmailScreen(email: _auth.currentUser?.email));
      }
    } else {
      // local storage
      deviceStorage.writeIfNull('isFirstTime', true);
      deviceStorage.read('isFirstTime') != true
          ? Get.offAll(() => const LoginScreen())
          : Get.offAll(() => const OnBoardingScreen());
    }
  }

  /* --------------------------- Email & Password sign-in --------------------------- */

  /// [EmailAuthentication] - SignIn

  /// [EmailAuthentication] - REGISTER
  Future<UserCredential> registerWithEmailAndPassword(
    String email,
    String password,
  ) async {
    print("i am herr");
    try {
      // Debug: log attempted registration (do not log raw password in production)
      print('[Auth] registerWithEmailAndPassword called with email: $email');
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      print(
        '[Auth] createUserWithEmailAndPassword succeeded: uid=${credential.user?.uid}',
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      print('[Auth][FirebaseAuthException] ${e.code} ${e.message}');
      throw MFirebaseAuthException(e.code);
    } on FirebaseException catch (e) {
      print('[Auth][FirebaseException] ${e.code} ${e.message}');
      throw MFirebaseException(e.code);
    } on FormatException {
      print('[Auth][FormatException]');
      throw const MFormatException();
    } on PlatformException catch (e) {
      print('[Auth][PlatformException] ${e.code} ${e.message}');
      throw MPlatformException(e.code);
    } catch (e) {
      print('[Auth][UnknownError] $e');
      throw Exception('Something went wrong. Please try again');
    }
  }

  /// [ReAuthenticate] - ReAuthenticate User

  /// [EmailVerification] - MAIL VERIFICATION
  Future<void> sendEmailVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw MFirebaseAuthException(e.code);
    } on FirebaseException catch (e) {
      throw MFirebaseException(e.code);
    } on FormatException catch (_) {
      throw const MFormatException();
    } on PlatformException catch (e) {
      throw MPlatformException(e.code);
    } catch (e) {
      throw Exception('Something went wrong. Please try again');
    }
  }

  /// [EmailAuthentication] - FORGET PASSWORD
  /* --------------------------- Federated identity & Social Sign-in --------------------------- */

  /// [google authentication]- GOOGLE
  /// [Facebook authentication]- FACEBOOK
  /* --------------------------- Federated identity & Social Sign-in --------------------------- */
  /// [LogoutUser]- valid for any authentication.
  Future<void> logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      Get.offAll(() => const LoginScreen());
    } on FirebaseAuthException catch (e) {
      throw MFirebaseAuthException(e.code);
    } on FirebaseException catch (e) {
      throw MFirebaseException(e.code);
    } on FormatException catch (_) {
      throw const MFormatException();
    } on PlatformException catch (e) {
      throw MPlatformException(e.code);
    } catch (e) {
      throw Exception('Something went wrong. Please try again');
    }
  }

  /// Delete User - Remove User Auth and Firebase Account
}
