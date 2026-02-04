import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
// import 'package:get/get.dart';
// import 'package:get/get_core/src/get_main.dart';
import 'package:med/common/styles/spacing_styles.dart';
// import 'package:med/features/authentication/screens/login/login.dart';
// import '../../../utils/constants/image_strings.dart';
import '../../../utils/constants/sizes.dart';
import '../../../utils/constants/text_strings.dart';

class SuccessScreen extends StatelessWidget {
  const SuccessScreen({
    super.key,
    required this.image,
    required this.title,
    required this.subTitle,
    required this.onPressed,
  });

  final String image, title, subTitle;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: MSpacingStyles.paddingWithAppBarHeight * 2,
          child: Column(
            children: [
              /// Image or Lottie animation
              if (image.toLowerCase().endsWith('.json'))
                Lottie.asset(
                  image,
                  width: MediaQuery.of(context).size.width * 0.6,
                )
              else
                Image.asset(
                  image,
                  width: MediaQuery.of(context).size.width * 0.6,
                ),
              const SizedBox(height: MSizes.spaceBtwSections),

              /// Title & SubTitle
              Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: MSizes.spaceBtwItems),
              Text(
                subTitle,
                style: Theme.of(context).textTheme.labelMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: MSizes.spaceBtwSections),

              /// Buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onPressed,
                  child: const Text(MTexts.mcontinue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
