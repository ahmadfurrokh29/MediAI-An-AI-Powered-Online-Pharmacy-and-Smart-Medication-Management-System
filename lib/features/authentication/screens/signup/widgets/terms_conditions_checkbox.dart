import 'package:flutter/material.dart';

import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/constants/text_strings.dart';
import '../../../../../utils/helpers/helper_functions.dart';

class MTermAndConditionsCheckbox extends StatelessWidget {
  const MTermAndConditionsCheckbox({
    super.key,

  });



  @override
  Widget build(BuildContext context) {
    final dark = MHelperFunctions.isDarkMode(context);
    return Row(
      children: [
        SizedBox(width: 24,
            height: 24,
            child: Checkbox(value: true, onChanged: (
                value) {})),
        const SizedBox(width: MSizes.spaceBtwItems,),
        Expanded(
          child: Text.rich(TextSpan(
            children: [
              TextSpan(
                  text: MTexts.iAgreeTo, style:Theme.of(context).textTheme.bodySmall),
              TextSpan(
                  text: '${MTexts.privacyPolicy} ', style:Theme.of(context).textTheme.bodyMedium!.apply(
                color: dark ? MColors.white : MColors.primary,
                decoration: TextDecoration.underline,
                decorationColor: dark ? MColors.white : MColors.primary,
              )),
              TextSpan(
                  text: '${MTexts.and} ', style:Theme.of(context).textTheme.bodySmall),
              TextSpan(
                  text: MTexts.termsOfUse, style:Theme.of(context).textTheme.bodyMedium!.apply(
                color: dark ? MColors.white : MColors.primary,
                decoration: TextDecoration.underline,
                decorationColor: dark ? MColors.white : MColors.primary,
              )),
            ],

          ),
          ),
        ),
      ],
    );
  }
}