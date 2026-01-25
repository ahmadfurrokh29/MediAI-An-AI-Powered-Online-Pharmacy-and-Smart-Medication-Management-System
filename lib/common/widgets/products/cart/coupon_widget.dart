import 'package:flutter/material.dart';
import 'package:med/common/widgets/custom_shapes/containers/rounded_container.dart';
import 'package:med/utils/constants/colors.dart';
import 'package:med/utils/constants/sizes.dart';
import 'package:med/utils/helpers/helper_functions.dart';

class MCouponCode extends StatelessWidget {
  const MCouponCode({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = MHelperFunctions.isDarkMode(context);
    return MRoundedContainer(
      showBorder: true,
      backgroundColor: dark ? MColors.dark : MColors.white,
      padding: EdgeInsets.only(
        top: MSizes.sm,
        bottom: MSizes.sm,
        left: MSizes.md,
        right: MSizes.sm,
      ),
      child: Row(
        children: [
          ///TextField to enter Promo Code
          Flexible(
            child: TextFormField(
              decoration: InputDecoration(
                hintText: 'Enter Promo Code To Get Discount',
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
              ),
            ),
          ),

          /// Apply Button
          SizedBox(
            width: 80,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: dark
                    ? MColors.white.withValues(alpha: 0.5)
                    : MColors.dark.withValues(alpha: 0.5),
                backgroundColor: Colors.grey.withValues(alpha: 0.2),
                side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
              ),
              onPressed: () {},
              child: Text('Apply'),
            ),
          ),
        ],
      ),
    );
  }
}
