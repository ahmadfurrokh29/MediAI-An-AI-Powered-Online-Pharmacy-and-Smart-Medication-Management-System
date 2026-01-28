import 'package:flutter/material.dart';
import 'package:med/common/widgets/images/m_rounded_image.dart';
import 'package:med/common/widgets/texts/m_brand_title_text_with_verified_icon.dart';
import 'package:med/common/widgets/texts/product_title_text.dart';
import 'package:med/utils/constants/colors.dart';
import 'package:med/utils/constants/image_strings.dart';
import 'package:med/utils/constants/sizes.dart';
import 'package:med/utils/helpers/helper_functions.dart';

class MCartItem extends StatelessWidget {
  const MCartItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        MRoundedImage(
          imageUrl: MImages.product1,
          width: 60,
          height: 60,
          padding: const EdgeInsets.all(MSizes.sm),
          backgroundColor: MHelperFunctions.isDarkMode(context)
              ? MColors.darkerGrey
              : MColors.light,
        ),
        const SizedBox(width: MSizes.defaultSpace),

        /// title 
        Expanded(
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MBrandTitleTextWithVerifiedIcon(title: 'Medlife'),
              Flexible(
                child: MProductTitleText(
                  title: 'Medicine For Your Use',
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
