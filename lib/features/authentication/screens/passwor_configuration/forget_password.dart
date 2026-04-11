import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:med/data/repositories/authentication/authentication_repository.dart';
import 'package:med/features/authentication/screens/passwor_configuration/reset_password.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/constants/text_strings.dart';

class ForgetPassword extends StatelessWidget {
  const ForgetPassword({super.key});

  @override
  Widget build(BuildContext context) {
    final emailController = TextEditingController();

    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(MSizes.defaultSpace),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              MTexts.forgetPasswordTitle,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: MSizes.spaceBtwItems),
            Text(
              MTexts.forgetPasswordSubTitle,
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: MSizes.spaceBtwSections * 2),
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: MTexts.email,
                prefixIcon: Icon(Iconsax.direct_right),
              ),
            ),
            const SizedBox(height: MSizes.spaceBtwSections),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final email = emailController.text.trim();
                  if (email.isEmpty) {
                    Get.snackbar(
                      'Error',
                      'Please enter your email address',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.red.shade100,
                    );
                    return;
                  }
                  try {
                    await AuthenticationRepository.instance
                        .sendPasswordResetEmail(email);
                    Get.off(() => ResetPassword(email: email));
                  } catch (e) {
                    Get.snackbar(
                      'Error',
                      e.toString(),
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.red.shade100,
                    );
                  }
                },
                child: Text(MTexts.submit),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
