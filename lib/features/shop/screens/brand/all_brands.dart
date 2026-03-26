import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:med/common/widgets/appbar/appbar.dart';
import 'package:med/common/widgets/custom_shapes/containers/rounded_container.dart';
import 'package:med/common/widgets/images/m_circular_image.dart';
import 'package:med/common/widgets/layouts/grid_layout.dart';
import 'package:med/common/widgets/texts/m_brand_title_text_with_verified_icon.dart';
import 'package:med/common/widgets/texts/section_heading.dart';
import 'package:med/features/shop/controllers/store_controller.dart';
import 'package:med/features/shop/screens/brand/brand_products.dart';
import 'package:med/utils/constants/colors.dart';
import 'package:med/utils/constants/enums.dart';
import 'package:med/utils/constants/image_strings.dart';
import 'package:med/utils/constants/sizes.dart';
import 'package:med/utils/helpers/helper_functions.dart';

class AllBrandsScreen extends StatelessWidget {
  const AllBrandsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = MHelperFunctions.isDarkMode(context);
    final controller = Get.find<StoreController>();

    return Scaffold(
      appBar: const MAppBar(title: Text('Brands'), showBackArrow: true),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(MSizes.defaultSpace),
          child: Column(
            children: [
              const MSectionHeading(
                title: 'All Brands',
                showActionButton: false,
              ),
              const SizedBox(height: MSizes.spaceBtwItems),

              Obx(() {
                final brands = controller.allBrands;
                if (brands.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: Text('No brands found.')),
                  );
                }
                return MGridLayout(
                  mainAxisExtent: 80,
                  itemCount: brands.length,
                  itemBuilder: (context, index) {
                    final brand = brands[index];
                    final name = (brand['name'] ?? '').toString();
                    final imageUrl = (brand['image'] ?? '').toString().trim();
                    final isNetwork = imageUrl.startsWith('http');
                    final count = brand['productCount'] ?? 0;

                    return GestureDetector(
                      onTap: () => Get.to(
                        () => BrandProducts(
                          brandName: name,
                          brandImage: imageUrl,
                          brandProductCount: count,
                        ),
                      ),
                      child: MRoundedContainer(
                        showBorder: true,
                        backgroundColor: dark
                            ? Colors.transparent
                            : MColors.lightGrey,
                        padding: const EdgeInsets.all(MSizes.sm),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Flexible(
                              child: MCircularImage(
                                image: isNetwork ? imageUrl : MImages.medIcon,
                                isNetworkImage: isNetwork,
                                backgroundColor: Colors.transparent,
                                height: 40,
                                width: 40,
                              ),
                            ),
                            const SizedBox(width: MSizes.spaceBtwItems / 2),
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  MBrandTitleTextWithVerifiedIcon(
                                    title: name,
                                    brandTextSize: TextSizes.large,
                                  ),
                                  Text(
                                    '$count Products',
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
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
