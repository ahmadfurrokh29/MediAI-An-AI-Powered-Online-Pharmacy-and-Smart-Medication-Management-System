
import 'package:flutter/material.dart';
import 'package:med/utils/constants/colors.dart';
import 'package:med/utils/device/device_utility.dart';
import 'package:med/utils/helpers/helper_functions.dart';

class MTabBar extends StatelessWidget implements PreferredSizeWidget {
  /// If you want to add the background color to tabs you have to wrap them in Material widget.
  /// To do that we need [PreferredSize] Widget and that's why created custom class. [PreferredSizeWidget]
  const MTabBar({super.key, required this.tabs});

  final List<Widget> tabs;

  @override
  Widget build(BuildContext context) {
    final dark = MHelperFunctions.isDarkMode(context);
    return Material(
      color: dark ? MColors.black : MColors.white,
      child: TabBar(
        tabs: tabs,
        isScrollable: true,
        indicatorColor: MColors.primary,
        labelColor: dark ? MColors.white : MColors.primary,
        unselectedLabelColor: MColors.darkGrey,
      ), // TabBar
    ); // Material
  }

  @override
  Size get preferredSize => Size.fromHeight(MDeviceUtils.getAppBarHeight());
}