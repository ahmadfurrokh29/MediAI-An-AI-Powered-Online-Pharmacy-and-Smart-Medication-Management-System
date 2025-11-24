import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:med/common/styles/spacing_styles.dart';
import 'package:med/common/widgets/login_signup/form_divider.dart';
import 'package:med/common/widgets/login_signup/social_buttons.dart';
import 'package:med/features/authentication/screens/login/widgets/login_form.dart';
import 'package:med/features/authentication/screens/login/widgets/login_header.dart';
import 'package:med/utils/constants/sizes.dart';
import 'package:med/utils/constants/text_strings.dart';


class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: MSpacingStyles.paddingWithAppBarHeight,
          child: Column(
            children: [
             const MLoginHeader(),
              const MLoginForm(),

              MFormDivider(dividerText: MTexts.orSignInWith.capitalize!),
              const SizedBox(height: MSizes.spaceBtwSections,),
              const MSocialButtons(),
            ],
          ),
        ),
      ),
    );
  }
}
