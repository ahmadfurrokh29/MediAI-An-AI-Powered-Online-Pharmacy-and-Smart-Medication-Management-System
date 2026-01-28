import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:med/common/widgets/appbar/appbar.dart';
import 'package:med/common/widgets/custom_shapes/containers/primary_header_container.dart';
import 'package:med/common/widgets/list_tiles/settings_menu_tile.dart';
import 'package:med/common/widgets/list_tiles/user_profile_tile.dart';
import 'package:med/common/widgets/texts/section_heading.dart';
import 'package:med/features/personalization/screens/address/address.dart';
import 'package:med/features/personalization/screens/mymedicalhistory/mymedicalhistory.dart';
import 'package:med/features/personalization/screens/mymedication/my_medication.dart';
import 'package:med/features/personalization/screens/profile/profile.dart';
import 'package:med/features/shop/screens/cart/cart.dart';
import 'package:med/features/shop/screens/order/order.dart';
import 'package:med/utils/constants/colors.dart';
import 'package:med/utils/constants/sizes.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            /// -- Header
            MPrimaryHeaderContainer(
              child: Column(
                children: [
                  //Appbar
                  MAppBar(
                    title: Text(
                      'Account',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineMedium!.apply(color: MColors.white),
                    ),
                  ),
                  //Profile Card
                  MUserProfileTile(
                    onPressed: () => Get.to(() => const ProfileScreen()),
                  ),
                  const SizedBox(height: MSizes.spaceBtwSections),
                ],
              ),
            ),
            //body
            Padding(
              padding: const EdgeInsets.all(MSizes.defaultSpace),
              child: Column(
                children: [
                  /// -- Account Settings
                  const MSectionHeading(
                    title: 'Account Settings',
                    showActionButton: false,
                  ),
                  const SizedBox(height: MSizes.spaceBtwItems),
                  MSettingsMenuTile(
                    icon: Iconsax.archive,
                    title: 'My Medical History',
                    subTitle: 'Help us to know better',
                    onTap: () => Get.to(() => MMyMedicalHistoryScreen()),
                  ),
                  MSettingsMenuTile(
                    icon: Iconsax.hospital,
                    title: 'My Medication',
                    subTitle: 'Mention your medication details',
                    onTap: () => Get.to(() => MMyMedicationScreen()),
                  ),

                  MSettingsMenuTile(
                    icon: Iconsax.safe_home,
                    title: 'My Addresses',
                    subTitle: 'Set shopping delivery address',
                    onTap: () => Get.to(() => UserAddressScreen()),
                  ),
                  MSettingsMenuTile(
                    icon: Iconsax.shopping_cart,
                    title: 'My Cart',
                    subTitle: 'Add, remove products and move to checkout',
                    onTap: () => Get.to(() => const CartScreen()),
                  ),
                  MSettingsMenuTile(
                    icon: Iconsax.bag_tick,
                    title: 'My Orders',
                    subTitle: 'In-progress and Completed Orders',
                    onTap: () => Get.to(() => const OrderScreen()),
                  ),
                  MSettingsMenuTile(
                    icon: Iconsax.bank,
                    title: 'Bank Account',
                    subTitle: 'Withdraw balance to registered bank account',
                    onTap: () {},
                  ),
                  MSettingsMenuTile(
                    icon: Iconsax.discount_shape,
                    title: 'My Coupons',
                    subTitle: 'List of all the discounted coupons',
                    onTap: () {},
                  ),
                  MSettingsMenuTile(
                    icon: Iconsax.notification,
                    title: 'Notifications',
                    subTitle: 'Set any kind of notification message',
                    onTap: () {},
                  ),
                  MSettingsMenuTile(
                    icon: Iconsax.security_card,
                    title: 'Account Privacy',
                    subTitle: 'Manage data usage and connected accounts',
                    onTap: () {},
                  ),

                  /// -- App Settings
                  const SizedBox(height: MSizes.spaceBtwSections),
                  const MSectionHeading(
                    title: 'App Settings',
                    showActionButton: false,
                  ),
                  const SizedBox(height: MSizes.spaceBtwItems),

                  // const MSettingsMenuTile(
                  //   icon: Iconsax.document_upload,
                  //   title: 'Load Data',
                  //   subTitle: 'Upload Data to your Cloud Firebase',
                  // ),

                  MSettingsMenuTile(
                    icon: Iconsax.location,
                    title: 'Geolocation',
                    subTitle: 'Set recommendation based on location',
                    trailing: Switch(
                      value: true,
                      onChanged: (value) {},
                      activeTrackColor: MColors.primary,
                      activeThumbColor: MColors.white,
                    ),
                  ),

                  MSettingsMenuTile(
                    icon: Iconsax.security_user,
                    title: 'Safe Mode',
                    subTitle: 'Search result is safe for all ages',
                    trailing: Switch(
                      value: false,
                      onChanged: (value) {},
                      activeTrackColor: MColors.primary,
                      activeThumbColor: MColors.white,
                    ),
                  ),

                  // MSettingsMenuTile(
                  //   icon: Iconsax.image,
                  //   title: 'HD Image Quality',
                  //   subTitle: 'Set image quality to be seen',
                  //   trailing: Switch(
                  //     value: true,
                  //     activeTrackColor: MColors.primary,
                  //     activeThumbColor: MColors.white,
                  //     onChanged: (value) {},
                  //   ),
                  // ),

                  /// -- Logout Button
                  const SizedBox(height: MSizes.spaceBtwSections),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {},
                      child: const Text('Logout'),
                    ),
                  ), // SizedBox
                  const SizedBox(height: MSizes.spaceBtwSections ),
                ],
              ), // Column
            ), // Padding
          ],
        ),
      ),
    );
  }
}
