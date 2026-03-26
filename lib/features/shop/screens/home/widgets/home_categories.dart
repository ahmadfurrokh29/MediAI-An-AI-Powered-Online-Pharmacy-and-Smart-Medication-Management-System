import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:med/common/widgets/image_text_widgets/vertical_image_text.dart';
import 'package:med/features/shop/controllers/home_controller.dart';
import 'package:med/features/shop/screens/sub_category/sub_category.dart';
import 'package:med/utils/constants/image_strings.dart';

class MHomeCategories extends StatelessWidget {
  const MHomeCategories({super.key});

  @override
  Widget build(BuildContext context) {
    // Req #3: featured + active categories from Firestore via HomeController
    final controller = Get.find<HomeController>();

    return SizedBox(
      height: 80,
      child: Obx(() {
        final categories = controller.featuredCategories;

        if (controller.isLoading.value && categories.isEmpty) {
          return const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
          );
        }

        if (categories.isEmpty) {
          return const Center(
            child: Text(
              'No featured categories',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          scrollDirection: Axis.horizontal,
          itemCount: categories.length,
          itemBuilder: (_, index) {
            final cat = categories[index];
            final imageUrl = (cat['image'] as String).trim();
            final bool isNetwork =
                imageUrl.startsWith('http://') ||
                imageUrl.startsWith('https://');

            return MVerticalImageText(
              image: isNetwork ? imageUrl : MImages.medIcon,
              isNetworkImage: isNetwork,
              title: (cat['name'] as String).isEmpty
                  ? 'Category'
                  : cat['name'] as String,
              onTap: () => Get.to(
                () => SubCategoriesScreen(
                  categoryId: cat['id'] as String,
                  categoryName: (cat['name'] as String).isEmpty
                      ? 'Category'
                      : cat['name'] as String,
                  categoryBannerUrl: cat['image'] as String?,
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
