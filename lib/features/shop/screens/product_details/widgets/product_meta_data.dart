

import 'package:flutter/material.dart';
import 'package:med/common/widgets/custom_shapes/containers/rounded_container.dart';
import 'package:med/common/widgets/texts/m_brand_title_text_with_verified_icon.dart';

import 'package:med/common/widgets/texts/product_price_text.dart';
import 'package:med/common/widgets/texts/product_title_text.dart';
import 'package:med/utils/constants/colors.dart';
import 'package:med/utils/constants/enums.dart';

import 'package:med/utils/constants/sizes.dart';
import 'package:med/utils/helpers/helper_functions.dart';

class MProductMetaData extends StatelessWidget {
  const MProductMetaData({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = MHelperFunctions.isDarkMode(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Price & Sale Price
        Row(
          children: [
            /// Sale Tag
            MRoundedContainer(
              radius: MSizes.sm,
              // ignore: deprecated_member_use
              backgroundColor: MColors.secondary.withOpacity(0.8),
              padding: const EdgeInsets.symmetric(horizontal: MSizes.sm, vertical: MSizes.xs),
              child: Text('25%', style: Theme.of(context).textTheme.labelLarge!.apply(color: MColors.black)),
            ),
            const SizedBox(width: MSizes.spaceBtwItems),

            /// Price
            Text('\$250', style: Theme.of(context).textTheme.titleSmall!.apply(decoration: TextDecoration.lineThrough)),
            const SizedBox(width: MSizes.spaceBtwItems),
            const MProductPriceText(price: '175', isLarge: true),
          ],
        ),
        const SizedBox(height: MSizes.spaceBtwItems / 1.5),

        /// Title
        const MProductTitleText(title:'Amoxicillin'),
        const SizedBox(height: MSizes.spaceBtwItems / 1.5),
        /// Stock Status
        Row(
          children: [
            const MProductTitleText(title:'Status'),
            const SizedBox(width: MSizes.spaceBtwItems),
            Text('In Stock', style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: MSizes.spaceBtwItems / 1.5),

        //Brand
        const MBrandTitleTextWithVerifiedIcon(title:'GlaxoSmithKline (GSK)',brandTextSize:TextSizes.medium)

        /// Brand
      ],
    );
  }
}