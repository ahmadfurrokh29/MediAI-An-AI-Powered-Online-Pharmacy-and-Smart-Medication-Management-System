import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
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
      // Reload to get the latest emailVerified status from Firebase.
      // Wrapped in try/catch so an offline reload doesn't block navigation.
      try {
        await user.reload();
      } catch (_) {}
      final refreshedUser = _auth.currentUser;
      if (refreshedUser == null) {
        deviceStorage.writeIfNull('isFirstTime', true);
        deviceStorage.read('isFirstTime') != true
            ? Get.offAll(() => const LoginScreen())
            : Get.offAll(() => const OnBoardingScreen());
        return;
      }
      if (refreshedUser.emailVerified) {
        Get.offAll(() => const NavigationMenu());
      } else {
        Get.offAll(() => VerifyEmailScreen(email: refreshedUser.email));
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
      throw MFirebaseAuthException(e.code);
    } on FirebaseException catch (e) {
      throw MFirebaseException(e.code);
    } on FormatException {
      throw const MFormatException();
    } on PlatformException catch (e) {
      throw MPlatformException(e.code);
    } catch (e) {
      throw Exception('Something went wrong. Please try again');
    }
  }

  /// [EmailAuthentication] - REGISTER
  Future<UserCredential> registerWithEmailAndPassword(
    String email,
    String password,
  ) async {
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

  /// [google authentication] - GOOGLE
  Future<UserCredential> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // ── Web: use Firebase popup flow (no clientId config needed) ──
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        return await _auth.signInWithPopup(googleProvider);
      } else {
        // ── Mobile: use google_sign_in package ────────────────────────
        final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
        if (googleUser == null)
          throw Exception('Google sign-in aborted by user.');

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        return await _auth.signInWithCredential(credential);
      }
    } on FirebaseAuthException catch (e) {
      throw MFirebaseAuthException(e.code);
    } on FirebaseException catch (e) {
      throw MFirebaseException(e.code);
    } on PlatformException catch (e) {
      throw MPlatformException(e.code);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// [facebook authentication] - FACEBOOK
  Future<UserCredential> signInWithFacebook() async {
    try {
      if (kIsWeb) {
        // ── Web: use Firebase popup flow ──────────────────────────────
        final FacebookAuthProvider facebookProvider = FacebookAuthProvider();
        facebookProvider.addScope('email');
        facebookProvider.addScope('public_profile');
        return await _auth.signInWithPopup(facebookProvider);
      } else {
        // ── Mobile: use flutter_facebook_auth package ─────────────────
        final LoginResult loginResult = await FacebookAuth.instance.login();
        if (loginResult.status == LoginStatus.cancelled) {
          throw Exception('Facebook sign-in cancelled by user.');
        }
        if (loginResult.status != LoginStatus.success ||
            loginResult.accessToken == null) {
          throw Exception('Facebook sign-in failed: ${loginResult.message}');
        }

        final OAuthCredential credential = FacebookAuthProvider.credential(
          loginResult.accessToken!.tokenString,
        );

        return await _auth.signInWithCredential(credential);
      }
    } on FirebaseAuthException catch (e) {
      throw MFirebaseAuthException(e.code);
    } on FirebaseException catch (e) {
      throw MFirebaseException(e.code);
    } on PlatformException catch (e) {
      throw MPlatformException(e.code);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /* --------------------------- Sign-out --------------------------- */
  /// [LogoutUser] - valid for any authentication.
  Future<void> logout() async {
    try {
      if (!kIsWeb) {
        // Silently sign out of social providers – these are no-ops if not used
        try {
          await GoogleSignIn().signOut();
        } catch (_) {}
        try {
          await FacebookAuth.instance.logOut();
        } catch (_) {}
      }
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
