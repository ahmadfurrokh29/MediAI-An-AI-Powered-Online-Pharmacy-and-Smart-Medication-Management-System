import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:med/common/widgets/custom_shapes/containers/circular_container.dart';
import 'package:med/common/widgets/images/m_rounded_image.dart';
import 'package:med/features/shop/controllers/home_controller.dart';
import 'package:med/utils/constants/colors.dart';
import 'package:med/utils/constants/image_strings.dart';
import 'package:med/utils/constants/sizes.dart';

// Fallback local banners shown when no active banners exist in Firestore yet
const _kLocalBanners = [
  MImages.promoBanner1,
  MImages.promoBanner2,
  MImages.promoBanner3,
];

// Req #4: Displays only active banners fetched from Firestore 'Banners' collection.
// Falls back to local asset banners when none are configured in the admin yet.
class MPromoSlider extends StatelessWidget {
  const MPromoSlider({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();

    return Obx(() {
      // While loading, show a shimmer-style placeholder
      if (controller.isLoading.value && controller.activeBanners.isEmpty) {
        return Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.grey.shade200,
          ),
          child: const Center(child: CircularProgressIndicator()),
        );
      }

      // Use Firestore banners if available, else fall back to local assets
      final bool usingFirestore = controller.activeBanners.isNotEmpty;
      final int itemCount = usingFirestore
          ? controller.activeBanners.length
          : _kLocalBanners.length;

      return Column(
        children: [
          CarouselSlider(
            options: CarouselOptions(
              viewportFraction: 1,
              enlargeCenterPage: true,
              enlargeFactor: 0.5,
              autoPlay: true,
              autoPlayInterval: const Duration(seconds: 4),
              onPageChanged: (index, _) =>
                  controller.updatePageIndicator(index),
            ),
            items: List.generate(itemCount, (index) {
              if (usingFirestore) {
                final banner = controller.activeBanners[index];
                final imageUrl = (banner['image'] ?? '').toString().trim();
                // If admin created banner without uploading an image, use a local asset
                if (imageUrl.startsWith('http')) {
                  return MRoundedImage(
                    imageUrl: imageUrl,
                    isNetworkImage: true,
                  );
                } else {
                  // fallback to a local asset for this slot
                  return MRoundedImage(
                    imageUrl: _kLocalBanners[index % _kLocalBanners.length],
                    isNetworkImage: false,
                  );
                }
              } else {
                return MRoundedImage(
                  imageUrl: _kLocalBanners[index],
                  isNetworkImage: false,
                );
              }
            }),
          ),
          const SizedBox(height: MSizes.spaceBtwItems),
          Obx(
            () => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 0; i < itemCount; i++)
                  MCircularContainer(
                    width: 20,
                    height: 4,
                    margin: const EdgeInsets.only(right: 10),
                    backgroundColor: controller.carouselCurrentIndex.value == i
                        ? MColors.primary
                        : MColors.grey,
                  ),
              ],
            ),
          ),
        ],
      );
    });
  }
}
