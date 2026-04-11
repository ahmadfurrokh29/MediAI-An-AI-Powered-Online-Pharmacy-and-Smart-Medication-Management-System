import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:iconsax/iconsax.dart';
import 'package:med/features/authentication/screens/passwor_configuration/forget_password.dart';
import 'package:med/features/authentication/screens/signup/signup.dart';
import 'package:med/navigation_menu.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/constants/text_strings.dart';

class MLoginForm extends StatefulWidget {
  const MLoginForm({super.key});

  @override
  State<MLoginForm> createState() => _MLoginFormState();
}

class _MLoginFormState extends State<MLoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _storage = GetStorage();
  bool _isLoading = false;
  bool _obscure = true;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    // Restore saved credentials if Remember Me was checked
    _rememberMe = _storage.read('REMEMBER_ME_STATUS') ?? false;
    if (_rememberMe) {
      _emailCtrl.text = _storage.read('REMEMBER_ME_EMAIL') ?? '';
      _passwordCtrl.text = _storage.read('REMEMBER_ME_PASSWORD') ?? '';
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );

      // Save or clear credentials based on Remember Me
      if (_rememberMe) {
        _storage.write('REMEMBER_ME_STATUS', true);
        _storage.write('REMEMBER_ME_EMAIL', _emailCtrl.text.trim());
        _storage.write('REMEMBER_ME_PASSWORD', _passwordCtrl.text.trim());
      } else {
        _storage.remove('REMEMBER_ME_STATUS');
        _storage.remove('REMEMBER_ME_EMAIL');
        _storage.remove('REMEMBER_ME_PASSWORD');
      }

      Get.offAll(() => const NavigationMenu());
    } on FirebaseAuthException catch (e) {
      final msg = e.code == 'user-not-found'
          ? 'No account found for this email.'
          : e.code == 'wrong-password' || e.code == 'invalid-credential'
          ? 'Incorrect password. Please try again.'
          : e.message ?? 'Login failed.';
      Get.snackbar(
        'Login Failed',
        msg,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
      );
    } catch (e) {
      Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: MSizes.spaceBtwSections),
        child: Column(
          children: [
            // Email
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter your email' : null,
              decoration: const InputDecoration(
                prefixIcon: Icon(Iconsax.direct_right),
                labelText: MTexts.email,
              ),
            ),
            const SizedBox(height: MSizes.spaceBtwInputFields),

            // Password
            TextFormField(
              controller: _passwordCtrl,
              obscureText: _obscure,
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Enter your password' : null,
              decoration: InputDecoration(
                prefixIcon: const Icon(Iconsax.password_check),
                labelText: MTexts.password,
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Iconsax.eye_slash : Iconsax.eye),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            const SizedBox(height: MSizes.spaceBtwInputFields / 2),

            // Remember me + Forget password
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      onChanged: (v) =>
                          setState(() => _rememberMe = v ?? false),
                    ),
                    const Text(MTexts.rememberMe),
                  ],
                ),
                TextButton(
                  onPressed: () => Get.to(() => const ForgetPassword()),
                  child: const Text(MTexts.forgetPassword),
                ),
              ],
            ),
            const SizedBox(height: MSizes.spaceBtwSections),

            // Sign In button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _login,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(MTexts.signIn),
              ),
            ),
            const SizedBox(height: MSizes.spaceBtwItems),

            // Create account button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Get.to(() => const SignupScreen()),
                child: Text(MTexts.createAccount),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
