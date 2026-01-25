import 'package:flutter/material.dart';
import 'package:med/utils/constants/sizes.dart';

class MBillingAmountSection extends StatelessWidget {
  const MBillingAmountSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ///subtotal
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Subtotal', style: Theme.of(context).textTheme.bodyMedium),
            Text('Rs 256', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
        const SizedBox(height: MSizes.spaceBtwItems / 2),

        ///shipping fee
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Shipping Fee', style: Theme.of(context).textTheme.bodyMedium),
            Text('Rs 120', style: Theme.of(context).textTheme.labelLarge),
          ],
        ),
        const SizedBox(height: MSizes.spaceBtwItems / 2),

        ///taxes
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Tax Fee', style: Theme.of(context).textTheme.bodyMedium),
            Text('Rs 15', style: Theme.of(context).textTheme.labelLarge),
          ],
        ),
        const SizedBox(height: MSizes.spaceBtwItems / 2),

        ///total
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Order Total', style: Theme.of(context).textTheme.bodyMedium),
            Text('Rs 391', style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ],
    );
  }
}
