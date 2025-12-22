import 'package:flutter/material.dart';
import 'package:med/common/widgets/brands/brand_card.dart';
import 'package:med/common/widgets/custom_shapes/containers/rounded_container.dart';
import 'package:med/utils/constants/colors.dart';
import 'package:med/utils/constants/sizes.dart';
import 'package:med/utils/helpers/helper_functions.dart';

class MBrandShowcase extends StatelessWidget {
  const MBrandShowcase({super.key, required this.images});

  final List<String> images;

  @override
  Widget build(BuildContext context) {
    return MRoundedContainer(
      showBorder: true,
      borderColor: MColors.darkGrey,
      backgroundColor: Colors.transparent,
      padding: EdgeInsets.all(MSizes.md),
      margin: const EdgeInsets.only(bottom: MSizes.spaceBtwItems),
      child: Column(
        children: [
          //Brnads with product count
          const MBrandCard(showBorder: false),
          const SizedBox(height: MSizes.spaceBtwItems),
          //Brmads Top 3 Product Images
          Row(
            children: images
                .map((image) => brandTopProductImageWidget(image, context))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget brandTopProductImageWidget(String image, context) {
    return Expanded(
      child: MRoundedContainer(
        height: 100,
        padding: const EdgeInsets.all(MSizes.md),
        margin: const EdgeInsets.only(right: MSizes.sm),
        backgroundColor: MHelperFunctions.isDarkMode(context)
            ? MColors.darkerGrey
            : MColors.light,
        child: Image(
          fit: BoxFit.contain,
          image: AssetImage(image),
        ),
      ), // TRoundedContainer
    ); // Expanded
  }
}
