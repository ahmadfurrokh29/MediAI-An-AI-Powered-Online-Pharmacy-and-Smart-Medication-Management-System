


import 'package:flutter/material.dart';
import 'package:med/utils/constants/colors.dart';

class MShadowStyle {
  static final verticalProductShadow=BoxShadow(
    // ignore: deprecated_member_use
    color: MColors.darkGrey.withOpacity(0.1),
    blurRadius: 50,
    spreadRadius: 7,
    offset: const Offset(0,2),
  );

  static final horizontalProductShadow=BoxShadow(
    // ignore: deprecated_member_use
    color: MColors.darkGrey.withOpacity(0.1),
    blurRadius: 50,
    spreadRadius: 7,
    offset: const Offset(0,2),
  );
}