import 'package:flutter/material.dart';
import 'package:med/common/widgets/custom_shapes/containers/rounded_container.dart';
import 'package:med/common/widgets/texts/section_heading.dart';
import 'package:med/utils/constants/colors.dart';
import 'package:med/utils/constants/image_strings.dart';
import 'package:med/utils/constants/sizes.dart';
import 'package:med/utils/helpers/helper_functions.dart';

class MBillingPaymentSection extends StatelessWidget {
  const MBillingPaymentSection({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = MHelperFunctions.isDarkMode(context);
    return Column(
      children: [
        MSectionHeading(
          title: 'Payment Methods',
          buttontitle: 'Change',
          onPressed: () {},
        ),
        const SizedBox(height: MSizes.spaceBtwItems / 2),

        Row(
          children: [
            MRoundedContainer(
              width: 60,
              height: 35,
              backgroundColor: dark ? MColors.light : MColors.white,
              padding: EdgeInsets.all(MSizes.sm),
              child: Image(
                image: AssetImage(MImages.google),
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: MSizes.spaceBtwItems / 2),
            Text('Google Pay', style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ],
    );
  }
}
