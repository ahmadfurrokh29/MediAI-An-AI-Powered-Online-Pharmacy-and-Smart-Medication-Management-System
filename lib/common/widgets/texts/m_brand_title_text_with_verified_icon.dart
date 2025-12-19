import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:iconsax/iconsax.dart';
import 'package:med/common/widgets/texts/m_brand_title_text.dart';
import 'package:med/utils/constants/colors.dart';
import 'package:med/utils/constants/enums.dart';
import 'package:med/utils/constants/sizes.dart';

class MBrandTitleTextWithVerifiedIcon extends StatelessWidget {
  const MBrandTitleTextWithVerifiedIcon({
    super.key,
    this.textColor,
    this.maxlines = 1,
    required this.title,
    this.iconColor = MColors.primary,
    this.textAlign = TextAlign.start,
    this.brandTextSize = TextSizes.small,
  });
  final Color? textColor, iconColor;
  final int maxlines;
  final String title;
  final TextAlign textAlign;
  final TextSizes brandTextSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: MBrandTitleText(
            title: title,
            color: textColor,
            maxlines: maxlines,
            textAlign: textAlign,
            brandTextSize: brandTextSize,
          ),
        ),
        const SizedBox(width: MSizes.xs),
        Icon(Iconsax.verify5, color: iconColor, size: MSizes.iconXs),
      ],
    );
  }
}
