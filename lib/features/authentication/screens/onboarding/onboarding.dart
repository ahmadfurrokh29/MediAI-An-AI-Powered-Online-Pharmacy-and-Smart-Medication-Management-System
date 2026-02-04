import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:med/features/authentication/controllers/onboarding/onboarding_controller.dart';
import 'package:med/features/authentication/screens/onboarding/widgets/onboarding_dot_navigation.dart';
import 'package:med/features/authentication/screens/onboarding/widgets/onboarding_page.dart';
import 'package:med/features/authentication/screens/onboarding/widgets/onboarding_skip.dart';
import 'package:med/utils/constants/colors.dart';
import 'package:med/utils/constants/image_strings.dart';
import 'package:med/utils/constants/text_strings.dart';
import 'package:med/utils/device/device_utility.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../utils/constants/sizes.dart';

class OnBoardingScreen extends StatelessWidget {
  const OnBoardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(OnBoardingController());
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: controller.pageController,
            onPageChanged: controller.updatePageIndicator,
            children: const [
              OnBoardingPage(
                image: MImages.onBoardingImage1,
                title: MTexts.onBoardingTitle1,
                subTitle: MTexts.onBoardingSubTitle1,
              ),
              OnBoardingPage(
                image: MImages.onBoardingImage2,
                title: MTexts.onBoardingTitle2,
                subTitle: MTexts.onBoardingSubTitle2,
              ),
              OnBoardingPage(
                image: MImages.onBoardingImage3,
                title: MTexts.onBoardingTitle3,
                subTitle: MTexts.onBoardingSubTitle3,
              ),
            ],
          ),
          const OnBoardingSkip(),
          const OnBoardingDotNavigation(),
          OnBoardingNextButton(),
        ],
      ),
    );
  }
}

class OnBoardingNextButton extends StatelessWidget {
  const OnBoardingNextButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: MSizes.defaultSpace,
      bottom: MDeviceUtils.getBottomNavigationBarHeight(),
      child: ElevatedButton(
        onPressed: () => OnBoardingController.instance.nextPage(),
        style:
            ElevatedButton.styleFrom(
              shape: const CircleBorder(),
              backgroundColor: MColors.primary,
              elevation: 0,
              shadowColor: Colors.transparent,
              overlayColor: Colors.transparent,
            ).copyWith(
              overlayColor: WidgetStateProperty.all(Colors.transparent),
              side: WidgetStateProperty.all(BorderSide.none),
            ),
        child: Icon(Iconsax.arrow_right_3),
      ),
    );
  }
}
