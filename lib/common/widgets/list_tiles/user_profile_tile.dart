import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:med/common/widgets/images/m_circular_image.dart';
import 'package:med/features/personalization/controllers/user_controller.dart';
import 'package:med/utils/constants/colors.dart';
import 'package:med/utils/constants/image_strings.dart';

class MUserProfileTile extends StatelessWidget {
  const MUserProfileTile({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<UserController>()
        ? UserController.instance
        : Get.put(UserController());

    return Obx(() {
      final user = controller.user.value;
      final fullName = '${user.firstName} ${user.lastName}'.trim();
      final displayName = fullName.isNotEmpty ? fullName : 'MediAI User';
      final displayEmail = user.email.isNotEmpty ? user.email : '';

      return ListTile(
        onTap: onPressed,
        leading: MCircularImage(
          image: user.profilePicture.isNotEmpty
              ? user.profilePicture
              : MImages.user1,
          width: 50,
          height: 50,
          padding: 0,
          isNetworkImage: user.profilePicture.isNotEmpty,
        ),
        title: Text(
          displayName,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall!.apply(color: MColors.white),
        ),
        subtitle: Text(
          displayEmail,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium!.apply(color: MColors.white),
        ),
        trailing: IconButton(
          onPressed: onPressed,
          icon: const Icon(Iconsax.edit, color: MColors.white),
        ),
      );
    });
  }
}
