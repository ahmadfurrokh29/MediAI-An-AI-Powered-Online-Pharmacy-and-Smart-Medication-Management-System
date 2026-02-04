 import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:med/common/widgets/custom_shapes/containers/circular_container.dart';
import 'package:med/common/widgets/images/m_rounded_image.dart';
import 'package:med/utils/constants/colors.dart';
import 'package:med/utils/constants/sizes.dart';
import 'package:med/features/shop/controllers/home_controller.dart';
import 'package:get/get.dart';


class MPromoSlider extends StatelessWidget {
  const MPromoSlider({super.key, required this.banners});

  final List<String> banners;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HomeController());
    return Column(
      children: [
        CarouselSlider(
          options: CarouselOptions(viewportFraction: 1,enlargeCenterPage: true,enlargeFactor: 0.5, onPageChanged: (index, _) => controller.updatePageIndicator(index), ),
          items: banners.map((url) =>MRoundedImage(imageUrl:url)).toList(),
        ),
        const SizedBox(height: MSizes.spaceBtwItems),
        Obx(
          ()=> Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int i = 0; i < banners.length; i++)
                 MCircularContainer(
                  width: 20,
                  height: 4,
                  margin: EdgeInsets.only(right: 10),
                  backgroundColor: controller.carouselCurrentIndex.value == i
                      ? MColors.primary
                      : MColors.grey,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
