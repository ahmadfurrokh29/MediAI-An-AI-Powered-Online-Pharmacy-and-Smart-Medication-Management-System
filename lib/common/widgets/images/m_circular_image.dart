import 'package:flutter/material.dart';
import 'package:med/utils/constants/colors.dart';
import 'package:med/utils/constants/sizes.dart';
import 'package:med/utils/helpers/helper_functions.dart';

class MCircularImage extends StatelessWidget {
  const MCircularImage({
    super.key,
    this.width = 56,
    this.height = 56,
    this.overlayColor,
    this.backgroundColor, 
    required this.image,
    this.fit = BoxFit.cover,
    this.padding = MSizes.sm, // IMPORTANT
    this.isNetworkImage = false,
  });

  final BoxFit fit;
  final String image;
  final bool isNetworkImage;
  final Color? overlayColor;
  final Color? backgroundColor;
  final double width, height, padding;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Container(
        width: width,
        height: height,
        color: backgroundColor ??
            (MHelperFunctions.isDarkMode(context)
                ? MColors.black
                : MColors.white),
        child: Image(
          fit: fit,
          image: isNetworkImage
              ? NetworkImage(image)
              : AssetImage(image),
          color: overlayColor,
        ),
      ),
    );
  }
}
