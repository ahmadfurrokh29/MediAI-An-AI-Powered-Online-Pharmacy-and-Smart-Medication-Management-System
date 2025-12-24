import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:med/common/widgets/appbar/appbar.dart';
import 'package:med/common/widgets/custom_shapes/curved_edges/curved_edges_widget.dart';
import 'package:med/common/widgets/icons/circular_icon.dart';
import 'package:med/common/widgets/images/m_rounded_image.dart';
import 'package:med/utils/constants/colors.dart';
import 'package:med/utils/constants/image_strings.dart';
import 'package:med/utils/constants/sizes.dart';
import 'package:med/utils/helpers/helper_functions.dart';

class MProductImageSlider extends StatelessWidget {
  const MProductImageSlider({
    super.key,
    
  });

  

  @override
  Widget build(BuildContext context) {

    
    final dark = MHelperFunctions.isDarkMode(context);
    return MCurvedEdgeWidget(
      child: Container(
        color: dark ? MColors.darkerGrey : MColors.light,
        child: Stack(
          children: [
            /// Main Medical Product Image
            SizedBox(
              height: 400,
              child: Padding(
                padding: EdgeInsets.all(MSizes.defaultSpace * 2),
                child: const Center(
                  child: Image(image: AssetImage(MImages.product10)),
                ),
              ),
            ),
    
            /// App Bar (Back Arrow & Wishlist)
            MAppBar(
              showBackArrow: true,
              actions:  [
                MCircularIcon(icon: Iconsax.heart5, color: Colors.red),
              ],
            ),
    
            /// Image Slider (Thumbnails)
            Positioned(
              right: 0,
              bottom: 30,
              left: MSizes.defaultSpace,
              child: SizedBox(
                height: 80,
                child: ListView.separated(
                  itemCount: 6,
                  shrinkWrap: true,
                  scrollDirection: Axis.horizontal,
                  physics: const AlwaysScrollableScrollPhysics(),
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: MSizes.spaceBtwItems),
                  itemBuilder: (_, index) => MRoundedImage(
                    width: 80,
                    backgroundColor: dark
                        ? MColors.dark
                        : MColors.white,
                    border: Border.all(color: MColors.primary),
                    padding: const EdgeInsets.all(MSizes.sm),
                    imageUrl: MImages.product9,
                  ), // MRoundedImage
                ), // ListView.separated
              ), // SizedBox
            ), // Positioned
          ],
        ), // Stack
      ), // Container
    );
  }
}
