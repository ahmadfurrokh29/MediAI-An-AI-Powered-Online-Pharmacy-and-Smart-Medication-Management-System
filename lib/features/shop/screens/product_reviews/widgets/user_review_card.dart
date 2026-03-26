import 'package:flutter/material.dart';
import 'package:med/common/widgets/custom_shapes/containers/rounded_container.dart';
import 'package:med/common/widgets/products/rating/rating_indicator.dart';
import 'package:med/features/shop/models/review_model.dart';
import 'package:med/utils/constants/colors.dart';
import 'package:med/utils/constants/sizes.dart';
import 'package:med/utils/helpers/helper_functions.dart';
import 'package:readmore/readmore.dart';

class UserReviewCard extends StatelessWidget {
  const UserReviewCard({super.key, required this.review});

  final ReviewModel review;

  @override
  Widget build(BuildContext context) {
    final dark = MHelperFunctions.isDarkMode(context);

    final String date =
        '${review.createdAt.day} ${_monthName(review.createdAt.month)}, ${review.createdAt.year}';

    // Avatar: network photo or initial fallback
    final ImageProvider avatarImage =
        (review.userImage != null && review.userImage!.startsWith('http'))
        ? NetworkImage(review.userImage!)
        : const AssetImage('assets/images/user/user.png') as ImageProvider;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Header row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                CircleAvatar(backgroundImage: avatarImage),
                const SizedBox(width: MSizes.spaceBtwItems),
                Text(
                  review.userName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert)),
          ],
        ),
        const SizedBox(height: MSizes.spaceBtwItems),

        /// Star rating + date
        Row(
          children: [
            MRatingBarIndicator(rating: review.rating),
            const SizedBox(width: MSizes.spaceBtwItems),
            Text(date, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
        const SizedBox(height: MSizes.spaceBtwItems),

        /// User comment
        ReadMoreText(
          review.comment,
          trimLines: 2,
          trimMode: TrimMode.Line,
          trimExpandedText: ' show less',
          trimCollapsedText: ' show more',
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

        /// Admin reply (only if present)
        if (review.adminReply != null && review.adminReply!.isNotEmpty)
          MRoundedContainer(
            backgroundColor: dark ? MColors.darkerGrey : MColors.grey,
            child: Padding(
              padding: const EdgeInsets.all(MSizes.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Medi-AI Support',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (review.adminReplyDate != null)
                        Text(
                          '${review.adminReplyDate!.day} ${_monthName(review.adminReplyDate!.month)}, ${review.adminReplyDate!.year}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                    ],
                  ),
                  const SizedBox(height: MSizes.spaceBtwItems),
                  ReadMoreText(
                    review.adminReply!,
                    trimLines: 2,
                    trimMode: TrimMode.Line,
                    trimExpandedText: ' show less',
                    trimCollapsedText: ' show more',
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

  String _monthName(int m) => const [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][m];
}
