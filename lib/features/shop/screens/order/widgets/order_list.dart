import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:med/common/widgets/custom_shapes/containers/rounded_container.dart';
import 'package:med/utils/constants/colors.dart';
import 'package:med/utils/constants/sizes.dart';
import 'package:med/utils/helpers/helper_functions.dart';

class MOrderListItems extends StatelessWidget {
  const MOrderListItems({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = MHelperFunctions.isDarkMode(context);
    // Placeholder for order list items
    return ListView.separated(
      shrinkWrap: true,
      itemCount: 5,
      separatorBuilder: (_, _) => const SizedBox(height: MSizes.spaceBtwItems),
      itemBuilder: (_, index) => MRoundedContainer(
        showBorder: true,
        padding: EdgeInsets.all(MSizes.md),
        backgroundColor: dark ? MColors.dark : MColors.light,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                /// Icon
                Icon(Iconsax.ship),
                SizedBox(width: MSizes.spaceBtwItems / 2),

                ///status and date
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Processing',
                        style: Theme.of(context).textTheme.bodyLarge!.apply(
                          color: MColors.primary,
                          fontWeightDelta: 1,
                        ),
                      ),
                      Text(
                        '12 Aug, 2025',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ],
                  ),
                ),

                /// Icon for details
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Iconsax.arrow_right, size: MSizes.iconSm),
                ),
              ],
            ),
            SizedBox(height: MSizes.spaceBtwItems),

            ///ROw 2 - Order ID and Amount
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      /// Icon
                      Icon(Iconsax.tag),
                      SizedBox(width: MSizes.spaceBtwItems / 2),

                      ///status and date
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Order ID',
                              style: Theme.of(context).textTheme.labelMedium,
                            ),

                            Text(
                              '[#256f2]',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      /// Icon
                      Icon(Iconsax.calendar),
                      SizedBox(width: MSizes.spaceBtwItems / 2),

                      ///status and date
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Shipping Date',
                              style: Theme.of(context).textTheme.labelMedium,
                            ),

                            Text(
                              '3 Feb, 2026',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
