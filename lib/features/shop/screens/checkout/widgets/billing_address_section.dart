import 'package:flutter/material.dart';
import 'package:med/common/widgets/texts/section_heading.dart';
import 'package:med/utils/constants/sizes.dart';

class MBillingAddressSection extends StatelessWidget {
  const MBillingAddressSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MSectionHeading(
          title: 'Shipping Address',
          buttontitle: 'Change',
          onPressed: () {},
        ),
        const SizedBox(height: MSizes.spaceBtwItems / 2),
        Text('IBRAHIM FAROOQ', style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: MSizes.spaceBtwItems / 2),
        Row(
          children: [
            const Icon(Icons.phone, color: Colors.grey, size: 16),
            const SizedBox(width: MSizes.spaceBtwItems),
            Text(
              '+92-332-5807144',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        const SizedBox(height: MSizes.spaceBtwItems / 2),
        Row(
          children: [
            const Icon(Icons.location_city, color: Colors.grey, size: 16),
            const SizedBox(width: MSizes.spaceBtwItems),
            Expanded(
              child: Text(
                'House #123, Street #4, ABC Town, City',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: MSizes.spaceBtwItems / 2),
      ],
    );
  }
}
