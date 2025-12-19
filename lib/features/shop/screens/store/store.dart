import 'package:flutter/material.dart';
import 'package:med/common/widgets/appbar/appbar.dart';
import 'package:med/common/widgets/custom_shapes/containers/rounded_container.dart';
import 'package:med/common/widgets/custom_shapes/containers/search_container.dart';
import 'package:med/common/widgets/images/m_circular_image.dart';
import 'package:med/common/widgets/layouts/grid_layout.dart';
import 'package:med/common/widgets/products/cart/cart_menu_icon.dart';
import 'package:med/common/widgets/texts/m_brand_title_text_with_verified_icon.dart';
import 'package:med/common/widgets/texts/section_heading.dart';
import 'package:med/utils/constants/colors.dart';
import 'package:med/utils/constants/enums.dart';
import 'package:med/utils/constants/image_strings.dart';
import 'package:med/utils/constants/sizes.dart';
import 'package:med/utils/helpers/helper_functions.dart';

class Store extends StatelessWidget {
  const Store({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = MHelperFunctions.isDarkMode(context);
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              automaticallyImplyLeading: false,
              pinned: true,
              floating: true,
              backgroundColor: dark ? Colors.black : Colors.white,
              expandedHeight: 440,

              flexibleSpace: Padding(
                padding: EdgeInsets.all(MSizes.defaultSpace),
                child: ListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    SizedBox(height: MSizes.spaceBtwItems),
                    MSearchContainer(
                      text: 'search in store',
                      showBorder: true,
                      showBackground: false,
                      padding: EdgeInsets.zero,
                    ),
                    SizedBox(height: MSizes.spaceBtwSections),

                    MSectionHeading(title: 'Featured Brands', onPressed: () {}),
                    const SizedBox(height: MSizes.spaceBtwItems / 1.5),
                    MGridLayout(
                      itemCount: 4,
                      mainAxisExtent: 80,
                      itemBuilder: (_, index) {
                        return GestureDetector(
                          onTap: () {},
                          child: MRoundedContainer(
                            padding: EdgeInsets.all(MSizes.sm),
                            showBorder: true,
                            backgroundColor: Colors.transparent,
                            child: Row(
                              children: [
                                ///icon
                                Flexible(
                                  child: MCircularImage(
                                    dark: dark,
                                    image: MImages.medIcon,
                                    isNetworkImage: false,
                                    backgroundColor: Colors.transparent,
                                    overlayColor: dark
                                        ? MColors.white
                                        : MColors.dark,
                                  ),
                                ),
                                const SizedBox(width: MSizes.spaceBtwItems / 2),

                                ///text
                                Expanded(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                      },
                    ),
                  ],
                ),
              ),
            ),
          ];
        },
        body: Container(),
      ),
    );
  }
}
