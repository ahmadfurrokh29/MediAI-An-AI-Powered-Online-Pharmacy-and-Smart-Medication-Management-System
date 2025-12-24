import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:med/common/widgets/appbar/appbar.dart';
import 'package:med/common/widgets/images/m_circular_image.dart';
import 'package:med/common/widgets/texts/section_heading.dart';
import 'package:med/features/personalization/screens/profile/widgets/profile_menu.dart';
import 'package:med/utils/constants/image_strings.dart';
import 'package:med/utils/constants/sizes.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MAppBar(showBackArrow: true, title: Text('Profile')),

      /// -- Body
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(MSizes.defaultSpace),
          child: Column(
            children: [
              /// -- Profile Picture
              SizedBox(
                width: double.infinity,
                child: Column(
                  children: [
                    const MCircularImage(
                      image: MImages.user1,
                      width: 80,
                      height: 80,
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text('Change Profile Picture'),
                    ),
                  ],
                ), // Column
              ), // SizedBox
              //Details
              /// -- Details
              const SizedBox(height: MSizes.spaceBtwItems / 2),
              const Divider(),
              const SizedBox(height: MSizes.spaceBtwItems),
              const MSectionHeading(
                title: 'Profile Information',
                showActionButton: false,
              ),
              const SizedBox(height: MSizes.spaceBtwItems),

              MProfileMenu(title: 'Name', value: 'MediAI', onPressed: () {}),
              const SizedBox(height: MSizes.spaceBtwItems),

              MProfileMenu(
                title: 'Username',
                value: 'medi@AI2026',
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
                value: '45689',
                icon: Iconsax.copy,
                onPressed: () {},
              ),
              MProfileMenu(
                title: 'E-mail',
                value: 'medi@gmail.com',
                onPressed: () {},
              ),
              MProfileMenu(
                title: 'Phone Number',
                value: '+92-317-8059528',
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
              Center(
                child: const Text(
                  'Close Account',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ], //__________________
          ), // Column
        ), // Padding
      ), // SingleChildScrollView
    ); // Scaffold
  }
}
