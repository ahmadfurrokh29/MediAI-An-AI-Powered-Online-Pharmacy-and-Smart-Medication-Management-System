import 'package:flutter/material.dart';
import 'package:med/common/widgets/custom_shapes/containers/rounded_container.dart';
import 'package:med/common/widgets/texts/m_brand_title_text_with_verified_icon.dart';
import 'package:med/common/widgets/texts/product_price_text.dart';
import 'package:med/common/widgets/texts/product_title_text.dart';
import 'package:med/utils/constants/colors.dart';
import 'package:med/utils/constants/enums.dart';
import 'package:med/utils/constants/sizes.dart';

class MProductMetaData extends StatelessWidget {
  const MProductMetaData({super.key, required this.productData});

  final Map<String, dynamic> productData;

  @override
  Widget build(BuildContext context) {
    final double price = (productData['price'] ?? 0).toDouble();
    final double salePrice = (productData['salePrice'] ?? 0).toDouble();
    final String title = (productData['name'] ?? '').toString();
    final String formulaName = (productData['formulaName'] ?? '').toString();
    final String brand = (productData['brandName'] ?? '').toString();
    final int stock = ((productData['stock'] ?? 0) as num).toInt();
    final bool inStock = stock > 0;

    // Effective display price and discount %
    final double effectivePrice = (salePrice > 0 && salePrice < price)
        ? salePrice
        : price;
    final int discountPercent =
        (salePrice > 0 && price > 0 && salePrice < price)
        ? (((price - salePrice) / price) * 100).round()
        : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Price row
        Row(
          children: [
            if (discountPercent > 0) ...[
              MRoundedContainer(
                radius: MSizes.sm,
                // ignore: deprecated_member_use
                backgroundColor: MColors.secondary.withOpacity(0.8),
                padding: const EdgeInsets.symmetric(
                  horizontal: MSizes.sm,
                  vertical: MSizes.xs,
                ),
                child: Text(
                  '$discountPercent%',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge!.apply(color: MColors.black),
                ),
              ),
              const SizedBox(width: MSizes.spaceBtwItems),
              Text(
                'Rs ${price.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.titleSmall!.apply(
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              const SizedBox(width: MSizes.spaceBtwItems),
            ],
            MProductPriceText(
              price: effectivePrice.toStringAsFixed(0),
              isLarge: true,
            ),
          ],
        ),
        const SizedBox(height: MSizes.spaceBtwItems / 1.5),

        /// Title
        MProductTitleText(title: title),
        const SizedBox(height: MSizes.spaceBtwItems / 1.5),

        /// Formula name (generic/formula name for medicines)
        if (formulaName.isNotEmpty) ...[
          Text(
            '($formulaName)',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: MSizes.spaceBtwItems / 1.5),
        ],

        /// Stock
        Row(
          children: [
            const MProductTitleText(title: 'Status'),
            const SizedBox(width: MSizes.spaceBtwItems),
            Text(
              inStock ? 'In Stock ($stock)' : 'Out of Stock',
              style: Theme.of(context).textTheme.titleMedium!.apply(
                color: inStock ? MColors.primary : Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: MSizes.spaceBtwItems / 1.5),

        /// Brand
        if (brand.isNotEmpty)
          MBrandTitleTextWithVerifiedIcon(
            title: brand,
            brandTextSize: TextSizes.medium,
          ),
      ],
    );
  }
}
