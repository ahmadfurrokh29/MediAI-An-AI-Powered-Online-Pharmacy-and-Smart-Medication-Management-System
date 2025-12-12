import 'package:flutter/material.dart';
import 'package:get/get.dart';
// import 'package:get/get_core/src/get_main.dart';
import 'package:iconsax/iconsax.dart';
import 'package:med/features/authentication/screens/passwor_configuration/forget_password.dart';
import 'package:med/features/authentication/screens/signup/signup.dart';
import 'package:med/navigation_menu.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/constants/text_strings.dart';

class MLoginForm extends StatelessWidget {
  const MLoginForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Form(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: MSizes.spaceBtwSections,
        ),
        child: Column(
          children: [
            TextFormField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Iconsax.direct_right),
                labelText: MTexts.email,
              ),
            ),
            const SizedBox(height: MSizes.spaceBtwInputFields),
            TextFormField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Iconsax.password_check),
                labelText: MTexts.password,
                suffixIcon: Icon(Iconsax.eye_slash),
              ),
            ),
            const SizedBox(height: MSizes.spaceBtwInputFields / 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Checkbox(value: true, onChanged: (value) {}),
                    const Text(MTexts.rememberMe),
                  ],
                ),
                TextButton(
                  onPressed: ()=> Get.to(()=>const ForgetPassword()),
                  child: const Text(MTexts.forgetPassword),
                ),
              ],
            ),
            const SizedBox(height: MSizes.spaceBtwSections),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Get.to(()=>const NavigationMenu()),
                child: Text(MTexts.signIn),
              ),
            ),
            const SizedBox(height: MSizes.spaceBtwItems),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Get.to( () => const SignupScreen()),
                child: Text(MTexts.createAccount),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
