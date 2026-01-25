import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:med/common/widgets/custom_shapes/containers/rounded_container.dart';
import 'package:med/utils/constants/colors.dart';
import 'package:med/utils/constants/sizes.dart';
import 'package:med/utils/helpers/helper_functions.dart';

class MSigleAddress extends StatelessWidget {
  const MSigleAddress({super.key, required this.selectedAdress});
  final bool selectedAdress;
  @override
  Widget build(BuildContext context) {
    final dark = MHelperFunctions.isDarkMode(context);
    return MRoundedContainer(
      width: double.infinity,
      showBorder: true,
      padding: const EdgeInsets.all(MSizes.md),
      backgroundColor: selectedAdress
          ? MColors.primary.withValues(alpha: 0.5)
          : Colors.transparent,
      borderColor: selectedAdress
          ? Colors.transparent
          : dark
          ? MColors.darkGrey
          : MColors.grey,
      margin: EdgeInsets.only(bottom: MSizes.spaceBtwItems),
      child: Stack(
        children: [
          Positioned(
            right: 5,
            top: 0,
            child: Icon(
              selectedAdress ? Iconsax.tick_circle5 : null,
              color: selectedAdress
                  ? dark
                        ? MColors.light
                        : MColors.dark
                  : null,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ibrahim Farooq',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: MSizes.sm / 2),
              Text(
                '(+92) 332-5807144',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: MSizes.sm / 2),
              Text(
                'House 280, Street 14, Phase 3, Bahria Town, Rawalpindi',
                softWrap: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
