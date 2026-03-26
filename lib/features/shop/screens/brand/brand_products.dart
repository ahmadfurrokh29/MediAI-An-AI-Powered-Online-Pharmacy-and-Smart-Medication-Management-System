import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:med/common/widgets/appbar/appbar.dart';
import 'package:med/common/widgets/custom_shapes/containers/rounded_container.dart';
import 'package:med/common/widgets/images/m_circular_image.dart';
import 'package:med/common/widgets/products/sortable/sortable_products.dart';
import 'package:med/common/widgets/texts/m_brand_title_text_with_verified_icon.dart';
import 'package:med/features/shop/controllers/store_controller.dart';
import 'package:med/utils/constants/colors.dart';
import 'package:med/utils/constants/enums.dart';
import 'package:med/utils/constants/image_strings.dart';
import 'package:med/utils/constants/sizes.dart';
import 'package:med/utils/helpers/helper_functions.dart';

class BrandProducts extends StatelessWidget {
  const BrandProducts({
    super.key,
    required this.brandName,
    this.brandImage = '',
    this.brandProductCount = 0,
    this.categoryName,
  });

  final String brandName;
  final String brandImage;
  final int brandProductCount;

  /// Optional: if set, only show products in this category for this brand.
  final String? categoryName;

  @override
  Widget build(BuildContext context) {
    final dark = MHelperFunctions.isDarkMode(context);
    final controller = Get.find<StoreController>();
    final products = controller.allProductsForBrand(
      brandName,
      categoryName: categoryName,
    );

    final isNetwork =
        brandImage.startsWith('http://') || brandImage.startsWith('https://');

    return Scaffold(
      appBar: MAppBar(title: Text(brandName), showBackArrow: true),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(MSizes.defaultSpace),
          child: Column(
            children: [
              /// Brand Details Card
              MRoundedContainer(
                showBorder: true,
                backgroundColor: dark ? Colors.transparent : MColors.lightGrey,
                padding: const EdgeInsets.all(MSizes.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: MCircularImage(
                        image: isNetwork ? brandImage : MImages.medIcon,
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
                            title: brandName,
                            brandTextSize: TextSizes.large,
                          ),
                          Text(
                            '$brandProductCount Products',
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MSizes.spaceBtwSections),

              MSortableProducts(products: products),
            ],
          ),
        ),
      ),
    );
  }
}
