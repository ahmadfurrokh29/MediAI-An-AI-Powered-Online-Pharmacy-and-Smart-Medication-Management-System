import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:med/common/widgets/images/m_circular_image.dart';
import 'package:med/utils/constants/colors.dart';
import 'package:med/utils/constants/image_strings.dart';

class MUserProfileTile extends StatelessWidget {
  const MUserProfileTile({super.key, required this.onPressed});

  final VoidCallback onPressed; 
  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onPressed, // ✅ THIS WAS MISSING

      leading: const MCircularImage(
        image: MImages.user1,
        width: 50,
        height: 50,
        padding: 0,
      ),
      title: Text(
        'Ahmad Furrokh',
        style: Theme.of(
          context,
        ).textTheme.headlineSmall!.apply(color: MColors.white),
      ),
      subtitle: Text(
        'ahmadfurrokh@gmail.com',
        style: Theme.of(
          context,
        ).textTheme.bodyMedium!.apply(color: MColors.white),
      ),
      trailing: IconButton(
        onPressed: onPressed,
        icon: const Icon(Iconsax.edit, color: MColors.white),
      ),
    ); // ListTile
  }
}
