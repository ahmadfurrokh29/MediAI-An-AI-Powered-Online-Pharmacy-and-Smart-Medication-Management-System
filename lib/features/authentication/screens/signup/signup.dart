import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:med/common/widgets/login_signup/form_divider.dart';
import 'package:med/common/widgets/login_signup/social_buttons.dart';
import 'package:med/features/authentication/screens/signup/widgets/signup_form.dart';
import 'package:med/utils/constants/sizes.dart';
import 'package:med/utils/constants/text_strings.dart';


class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(MSizes.defaultSpace),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                MTexts.signupTitle,
                style: Theme
                    .of(context)
                    .textTheme
                    .headlineMedium,
              ),
              const SizedBox(height: MSizes.spaceBtwSections),
              MSignupForm(),
              SizedBox(height: 20,),
              MFormDivider(dividerText: MTexts.orSignUPWith.capitalize!),
              SizedBox(height: 20,),
              const MSocialButtons(),
            ],
          ),
        ),
      ),
    );
  }
}


