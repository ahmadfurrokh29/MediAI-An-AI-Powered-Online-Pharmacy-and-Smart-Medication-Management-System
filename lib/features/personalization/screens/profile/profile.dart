import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:med/common/widgets/appbar/appbar.dart';
import 'package:med/common/widgets/images/m_circular_image.dart';
import 'package:med/common/widgets/texts/section_heading.dart';
import 'package:med/features/personalization/controllers/user_controller.dart';
import 'package:med/features/personalization/screens/profile/widgets/profile_menu.dart';
import 'package:med/utils/constants/image_strings.dart';
import 'package:med/utils/constants/sizes.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<UserController>()
        ? UserController.instance
        : Get.put(UserController());

    return Scaffold(
      appBar: const MAppBar(showBackArrow: true, title: Text('Profile')),

      /// -- Body
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(MSizes.defaultSpace),
          child: Obx(() {
            final user = controller.user.value;
            return Column(
              children: [
                /// -- Profile Picture
                SizedBox(
                  width: double.infinity,
                  child: Column(
                    children: [
                      MCircularImage(
                        image: user.profilePicture.isNotEmpty
                            ? user.profilePicture
                            : MImages.user1,
                        width: 80,
                        height: 80,
                        isNetworkImage: user.profilePicture.isNotEmpty,
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text('Change Profile Picture'),
                      ),
                    ],
                  ),
                ),

                /// -- Details
                const SizedBox(height: MSizes.spaceBtwItems / 2),
                const Divider(),
                const SizedBox(height: MSizes.spaceBtwItems),
                const MSectionHeading(
                  title: 'Profile Information',
                  showActionButton: false,
                ),
                const SizedBox(height: MSizes.spaceBtwItems),

                MProfileMenu(
                  title: 'Name',
                  value: '${user.firstName} ${user.lastName}'.trim(),
                  onPressed: () {},
                ),
                const SizedBox(height: MSizes.spaceBtwItems),

                MProfileMenu(
                  title: 'Username',
                  value: user.username.isNotEmpty ? user.username : '—',
                  onPressed: () {},
                ),

                const SizedBox(height: MSizes.spaceBtwItems),
                const Divider(),
                const SizedBox(height: MSizes.spaceBtwItems),

                /// Heading Personal Info
                const MSectionHeading(
                  title: 'Personal Information',
                  showActionButton: false,
                ),
                const SizedBox(height: MSizes.spaceBtwItems),

                MProfileMenu(
                  title: 'User ID',
                  value: user.id.isNotEmpty ? user.id : '—',
                  icon: Iconsax.copy,
                  onPressed: () {},
                ),
                MProfileMenu(
                  title: 'E-mail',
                  value: user.email.isNotEmpty ? user.email : '—',
                  onPressed: () {},
                ),
                MProfileMenu(
                  title: 'Phone Number',
                  value: user.phoneNumber.isNotEmpty ? user.phoneNumber : '—',
                  onPressed: () {},
                ),
                MProfileMenu(title: 'Gender', value: 'Male', onPressed: () {}),
                MProfileMenu(
                  title: 'Date of Birth',
                  value: '10 Oct, 1994',
                  onPressed: () {},
                ),
                const Divider(),
                const SizedBox(height: MSizes.spaceBtwItems),
                const Center(
                  child: Text(
                    'Close Account',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
