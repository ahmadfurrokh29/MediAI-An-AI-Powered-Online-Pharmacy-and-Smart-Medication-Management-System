import 'package:flutter/material.dart';
import 'package:med/utils/constants/colors.dart';
import 'package:med/utils/constants/sizes.dart';
import 'package:med/utils/helpers/helper_functions.dart';

class MCircularIcon extends StatelessWidget {
  //A custom Circular Icon widget with a background color
  //Properties are:
  //Container -> width, height, background
  //Icons-> size, color, onpressed()
  const MCircularIcon({
    super.key,
    required this.icon, this.color, this.width, this.height, this.size=MSizes.lg, this.backgroundColor,this.onPressed,
  });

  
  final IconData icon;
  final Color? color;
  final double? width, height, size;
  final Color? backgroundColor;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      
      decoration: BoxDecoration(
        color:backgroundColor != null? backgroundColor! : MHelperFunctions.isDarkMode(context) ?MColors.black.withValues(alpha: 230) : MColors.white.withValues(alpha: 230),
        borderRadius: BorderRadius.circular(100)
      ),
      child:IconButton(onPressed:onPressed, icon: Icon(icon,color: color,size: size,))
    );
  }
}