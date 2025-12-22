
import 'package:flutter/material.dart';
import 'package:med/common/widgets/custom_shapes/containers/rounded_container.dart';
import 'package:med/common/widgets/images/m_circular_image.dart';
import 'package:med/common/widgets/texts/m_brand_title_text_with_verified_icon.dart';
import 'package:med/utils/constants/colors.dart';
import 'package:med/utils/constants/enums.dart';
import 'package:med/utils/constants/image_strings.dart';
import 'package:med/utils/constants/sizes.dart';
import 'package:med/utils/helpers/helper_functions.dart';

class MBrandCard extends StatelessWidget {
  const MBrandCard({
    super.key,
    this.onTap,
    required this.showBorder,
  });

  final bool showBorder;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = MHelperFunctions.isDarkMode(context);
    return GestureDetector(//_____________________________make this brand card
      onTap: () {},
      child: MRoundedContainer(
        showBorder: showBorder,
        backgroundColor:Colors.transparent,
        padding: const EdgeInsets.all(MSizes.sm),
       
    
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ///icon
            Flexible(
              child: MCircularImage(
                
                image: MImages.medIcon,
                isNetworkImage: false,
                backgroundColor: Colors.transparent,
                overlayColor: isDark
                    ? MColors.white
                    : MColors.dark,
              ),
            ),
            const SizedBox(
              width: MSizes.spaceBtwItems / 2,
            ),
    
            ///text________________________________________correct
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment:CrossAxisAlignment.start,
                children: [
                  const MBrandTitleTextWithVerifiedIcon(
                    title: 'Medlife',
                    brandTextSize: TextSizes.large,
                  ),
                  Text(
                    '256 Products ...........09876654',
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.labelMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
