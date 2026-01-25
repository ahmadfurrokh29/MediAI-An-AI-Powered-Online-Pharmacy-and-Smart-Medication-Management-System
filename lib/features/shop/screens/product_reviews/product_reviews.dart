import 'package:flutter/material.dart';
import 'package:med/common/widgets/appbar/appbar.dart';
import 'package:med/common/widgets/products/rating/rating_indicator.dart';
import 'package:med/features/shop/screens/product_reviews/widgets/rating_progress_indicator.dart';
import 'package:med/features/shop/screens/product_reviews/widgets/user_review_card.dart';
import 'package:med/utils/constants/image_strings.dart';
import 'package:med/utils/constants/sizes.dart';

class ProductReviewsScreen extends StatelessWidget {
  const ProductReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MAppBar(title: Text('Reviews and Ratings'), showBackArrow: true),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(MSizes.defaultSpace),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ratings and reviews are all verified and are from people who use the same type of medicine that you use',
              ),
              SizedBox(height: MSizes.spaceBtwItems),

              /// Overall Product Ratings
              MOverallProductRating(),
              MRatingBarIndicator(rating: 4.5),
              Text('12,611', style: Theme.of(context).textTheme.bodySmall),
              SizedBox(height: MSizes.spaceBtwSections),

              /// Reviews List
              UserReviewCard(
                name: 'Ibrahim Farooq',
                rating: 5,
                image: MImages.user2,
              ),
              UserReviewCard(
                name: 'Ahmad Farrukh',
                rating: 2.5,
                image: MImages.user1,
              ),
              UserReviewCard(
                name: 'Abdullah Tariq',
                rating: 3.5,
                image: MImages.user1,
              ),
              UserReviewCard(
                name: 'Umair Jamil',
                rating: 3.6,
                image: MImages.user2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
