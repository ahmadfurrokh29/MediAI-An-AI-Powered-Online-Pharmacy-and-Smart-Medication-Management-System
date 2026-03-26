import 'package:flutter/material.dart';
import 'package:med/features/shop/screens/product_reviews/widgets/progress_indicator_and_rating.dart';

class MOverallProductRating extends StatelessWidget {
  const MOverallProductRating({
    super.key,
    required this.avgRating,
    required this.reviewCount,
    required this.ratingCounts,
  });

  final double avgRating;
  final int reviewCount;

  /// Map of star value (1–5) → count
  final Map<int, int> ratingCounts;

  @override
  Widget build(BuildContext context) {
    double _barValue(int star) {
      if (reviewCount == 0) return 0;
      return (ratingCounts[star] ?? 0) / reviewCount;
    }

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            avgRating > 0 ? avgRating.toStringAsFixed(1) : '—',
            style: Theme.of(context).textTheme.displayLarge,
          ),
        ),
        Expanded(
          flex: 7,
          child: Column(
            children: [
              MRatingProgressIndicator(text: '5', value: _barValue(5)),
              MRatingProgressIndicator(text: '4', value: _barValue(4)),
              MRatingProgressIndicator(text: '3', value: _barValue(3)),
              MRatingProgressIndicator(text: '2', value: _barValue(2)),
              MRatingProgressIndicator(text: '1', value: _barValue(1)),
            ],
          ),
        ),
      ],
    );
  }
}
