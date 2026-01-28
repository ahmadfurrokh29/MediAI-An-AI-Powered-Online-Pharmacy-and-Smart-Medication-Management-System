import 'package:flutter/material.dart';
import 'package:med/common/widgets/custom_shapes/containers/rounded_container.dart';
import 'package:med/common/widgets/products/rating/rating_indicator.dart';
import 'package:med/utils/constants/colors.dart';

import 'package:med/utils/constants/sizes.dart';
import 'package:med/utils/helpers/helper_functions.dart';
import 'package:readmore/readmore.dart';

class UserReviewCard extends StatelessWidget {
  const UserReviewCard({
    super.key,
    required this.name,
    required this.rating,
    required this.image,
  });
  final String name;
  final double rating;
  final String image;
  @override
  Widget build(BuildContext context) {
    final dark = MHelperFunctions.isDarkMode(context);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                CircleAvatar(backgroundImage: AssetImage(image)),
                const SizedBox(width: MSizes.spaceBtwItems),
                Text(name, style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert)),
          ],
        ),
        const SizedBox(height: MSizes.spaceBtwItems),

        ///Review
        Row(
          children: [
            MRatingBarIndicator(rating: rating),
            const SizedBox(width: MSizes.spaceBtwItems),
            Text('23 Jan, 2026', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
        const SizedBox(height: MSizes.spaceBtwItems),
        ReadMoreText(
          'MediAI is an intelligent healthcare support system designed to assist users by leveraging artificial intelligence for accurate and efficient medical analysis. The project demonstrates strong integration of AI concepts with real-world healthcare requirements, offering reliable results, scalability, and ease of use. MediAI highlights the potential of AI-driven solutions in modern medical systems.',
          trimLines: 1,
          trimMode: TrimMode.Line,
          trimExpandedText: 'show less',
          trimCollapsedText: 'show more',
          moreStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: MColors.primary,
          ),
          lessStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: MColors.primary,
          ),
        ),
        const SizedBox(height: MSizes.spaceBtwItems),
        MRoundedContainer(
          backgroundColor: dark ? MColors.darkerGrey : MColors.grey,
          child: Padding(
            padding: EdgeInsets.all(MSizes.md),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Medi-AI Support',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '23 Jan,2026',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: MSizes.spaceBtwItems),
                ReadMoreText(
                  'MediAI is an intelligent healthcare support system designed to assist users by leveraging artificial intelligence for accurate and efficient medical analysis. The project demonstrates strong integration of AI concepts with real-world healthcare requirements, offering reliable results, scalability, and ease of use. MediAI highlights the potential of AI-driven solutions in modern medical systems.',
                  trimLines: 1,
                  trimMode: TrimMode.Line,
                  trimExpandedText: 'show less',
                  trimCollapsedText: 'show more',
                  moreStyle: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: MColors.primary,
                  ),
                  lessStyle: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: MColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: MSizes.spaceBtwSections),
      ],
    );
  }
}
