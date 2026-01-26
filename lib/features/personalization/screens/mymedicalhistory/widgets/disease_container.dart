import 'package:flutter/material.dart';
import 'package:med/common/widgets/custom_shapes/containers/rounded_container.dart';
import 'package:med/utils/constants/colors.dart';
import 'package:med/utils/constants/sizes.dart';
import 'package:med/utils/helpers/helper_functions.dart';

class MDiseaseContainer extends StatelessWidget {
  const MDiseaseContainer({super.key, required this.isChronic});

  final bool isChronic;

  @override
  Widget build(BuildContext context) {
    final dark = MHelperFunctions.isDarkMode(context);
    return MRoundedContainer(
      width: double.infinity,

      showBorder: true,
      padding: const EdgeInsets.all(MSizes.md),
      backgroundColor: isChronic
          ? MColors.primary.withValues(alpha: 0.2)
          : Colors.transparent,

      borderColor: dark ? MColors.darkGrey : MColors.grey,
      margin: EdgeInsets.only(bottom: MSizes.spaceBtwItems),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fever',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: MSizes.sm / 2),
          Text(
            'Diagnosed on: 12th Jan 2023',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: MSizes.sm / 2),
          Text('allergic to penicillin. ', softWrap: true),
          const SizedBox(height: MSizes.sm / 2),
          Text('Prescribed medication: Paracetamol', softWrap: true),
        ],
      ),
    );
  }
}
