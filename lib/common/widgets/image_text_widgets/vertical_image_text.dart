import 'package:flutter/material.dart';
import 'package:med/utils/constants/colors.dart';
import 'package:med/utils/constants/sizes.dart';
import 'package:med/utils/helpers/helper_functions.dart';

class MVerticalImageText extends StatelessWidget {
  const MVerticalImageText({
    super.key, required this.image, required this.title,  this.textColor=MColors.white, this.backgroundColor=MColors.white, this.onTap,
  });

  final String image, title;
  final Color textColor;
  final Color? backgroundColor;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context)  {

    final dark = MHelperFunctions.isDarkMode(context);

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right:MSizes.spaceBtwItems),
        child: Column(
          children:[
            //circular icon
            Container(
              width:56,
              height:56,
              padding: const EdgeInsets.all(MSizes.sm),
              decoration: BoxDecoration(
                color:backgroundColor ?? (dark ? MColors.black : MColors.white),
                borderRadius: BorderRadius.circular(100),
              ),
              child:Center(
                
                child: Image(image:AssetImage(image), fit:BoxFit.cover,color: dark? MColors.white : MColors.black),
              ),
        
            ),
            const SizedBox(height: MSizes.spaceBtwItems / 2),
            //text under each caregory icon
            SizedBox(width:55,child: Text(title, style:Theme.of(context).textTheme.labelMedium!.apply(color:textColor),maxLines:1, overflow:TextOverflow.ellipsis,)
        )
          ]
        ),
      ),
    );
  }
}

