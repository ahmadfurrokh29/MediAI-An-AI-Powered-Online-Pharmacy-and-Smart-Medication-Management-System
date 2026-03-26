import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:med/utils/constants/sizes.dart';
import 'package:share_plus/share_plus.dart';

class MRatingAndShare extends StatelessWidget {
  const MRatingAndShare({
    super.key,
    this.avgRating = 0.0,
    this.reviewCount = 0,
    this.productName = '',
    this.productDescription = '',
  });

  final double avgRating;
  final int reviewCount;
  final String productName;
  final String productDescription;

  @override
  Widget build(BuildContext context) {
    final displayRating = avgRating > 0 ? avgRating.toStringAsFixed(1) : '—';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        /// Rating
        Row(
          children: [
            const Icon(Iconsax.star5, color: Colors.amber, size: 24),
            const SizedBox(width: MSizes.spaceBtwItems / 2),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$displayRating ',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  TextSpan(text: '($reviewCount)'),
                ],
              ),
            ),
          ],
        ),

        /// Share Button
        IconButton(
          onPressed: () {
            final desc = productDescription.length > 120
                ? '${productDescription.substring(0, 120)}...'
                : productDescription;
            final text = productName.isNotEmpty
                ? 'Check out "$productName" on MediAI!\n\n$desc\n\nRating: $displayRating ★ ($reviewCount reviews)'
                : 'Check out this product on MediAI!';
            SharePlus.instance.share(ShareParams(text: text));
          },
          icon: const Icon(Icons.share, size: MSizes.iconMd),
        ),
      ],
    );
  }
}
