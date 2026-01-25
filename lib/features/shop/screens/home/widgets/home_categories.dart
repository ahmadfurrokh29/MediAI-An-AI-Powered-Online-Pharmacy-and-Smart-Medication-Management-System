import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/get_core.dart';
import 'package:med/features/shop/screens/sub_category/sub_category.dart';
import 'package:med/utils/constants/image_strings.dart';
import 'package:med/common/widgets/image_text_widgets/vertical_image_text.dart';

class MHomeCategories extends StatelessWidget {
  const MHomeCategories({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        itemCount: 6,
        itemBuilder: (_, index) {
          //icons are not added in const folder
          return MVerticalImageText(
            image: MImages.medIcon,
            title: 'medicine',
            onTap: () => Get.to(() => const SubCategoriesScreen()),
          );
        },
      ),
    );
  }
}
