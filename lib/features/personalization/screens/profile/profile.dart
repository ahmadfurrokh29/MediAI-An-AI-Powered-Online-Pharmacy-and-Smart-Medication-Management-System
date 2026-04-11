import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
                      Obx(() {
                        final networkImage =
                            controller.user.value.profilePicture;
                        final image = networkImage.isNotEmpty
                            ? networkImage
                            : MImages.user1;
                        return MCircularImage(
                          image: image,
                          width: 80,
                          height: 80,
                          isNetworkImage: networkImage.isNotEmpty,
                        );
                      }),
                      TextButton(
                        onPressed: () => controller.uploadUserProfilePicture(),
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
                  value: '${user.firstName} ${user.lastName}'.trim().isNotEmpty
                      ? '${user.firstName} ${user.lastName}'.trim()
                      : '—',
                  onPressed: () => _showEditNameDialog(context, controller),
                ),
                const SizedBox(height: MSizes.spaceBtwItems),

                MProfileMenu(
                  title: 'Username',
                  value: user.username.isNotEmpty ? user.username : '—',
                  showIcon: false,
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
                  onPressed: () {
                    if (user.id.isNotEmpty) {
                      Clipboard.setData(ClipboardData(text: user.id));
                      Get.snackbar(
                        'Copied',
                        'User ID copied to clipboard',
                        snackPosition: SnackPosition.BOTTOM,
                        duration: const Duration(seconds: 2),
                      );
                    }
                  },
                ),
                MProfileMenu(
                  title: 'E-mail',
                  value: user.email.isNotEmpty ? user.email : '—',
                  showIcon: false,
                  onPressed: () {},
                ),
                MProfileMenu(
                  title: 'Phone Number',
                  value: user.phoneNumber.isNotEmpty ? user.phoneNumber : '—',
                  onPressed: () => _showEditPhoneDialog(context, controller),
                ),
                MProfileMenu(
                  title: 'Gender',
                  value: user.gender.isNotEmpty ? user.gender : '—',
                  onPressed: () => _showGenderPicker(context, controller),
                ),
                MProfileMenu(
                  title: 'Date of Birth',
                  value: user.dateOfBirth.isNotEmpty ? user.dateOfBirth : '—',
                  onPressed: () => _showDatePicker(context, controller),
                ),
                const Divider(),
                const SizedBox(height: MSizes.spaceBtwItems),

                /// Heading Manage Password
                const MSectionHeading(
                  title: 'Manage Password',
                  showActionButton: false,
                ),
                const SizedBox(height: MSizes.spaceBtwItems),

                MProfileMenu(
                  title: 'Change Password',
                  value: '••••••••',
                  icon: Iconsax.lock,
                  onPressed: () =>
                      _showChangePasswordDialog(context, controller),
                ),

                const Divider(),
                const SizedBox(height: MSizes.spaceBtwItems),
                Center(
                  child: TextButton(
                    onPressed: () =>
                        _showCloseAccountDialog(context, controller),
                    child: const Text(
                      'Close Account',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  // ── Change Password dialog ──
  void _showChangePasswordDialog(
    BuildContext context,
    UserController controller,
  ) {
    final oldPasswordCtrl = TextEditingController();
    final newPasswordCtrl = TextEditingController();
    final confirmPasswordCtrl = TextEditingController();
    final obscureOld = true.obs;
    final obscureNew = true.obs;
    final obscureConfirm = true.obs;

    Get.defaultDialog(
      contentPadding: const EdgeInsets.all(MSizes.md),
      title: 'Change Password',
      content: Column(
        children: [
          Obx(
            () => TextField(
              controller: oldPasswordCtrl,
              obscureText: obscureOld.value,
              decoration: InputDecoration(
                labelText: 'Current Password',
                prefixIcon: const Icon(Iconsax.password_check),
                suffixIcon: IconButton(
                  icon: Icon(
                    obscureOld.value ? Iconsax.eye_slash : Iconsax.eye,
                  ),
                  onPressed: () => obscureOld.value = !obscureOld.value,
                ),
              ),
            ),
          ),
          const SizedBox(height: MSizes.spaceBtwItems),
          Obx(
            () => TextField(
              controller: newPasswordCtrl,
              obscureText: obscureNew.value,
              decoration: InputDecoration(
                labelText: 'New Password',
                prefixIcon: const Icon(Iconsax.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    obscureNew.value ? Iconsax.eye_slash : Iconsax.eye,
                  ),
                  onPressed: () => obscureNew.value = !obscureNew.value,
                ),
              ),
            ),
          ),
          const SizedBox(height: MSizes.spaceBtwItems),
          Obx(
            () => TextField(
              controller: confirmPasswordCtrl,
              obscureText: obscureConfirm.value,
              decoration: InputDecoration(
                labelText: 'Confirm New Password',
                prefixIcon: const Icon(Iconsax.lock_1),
                suffixIcon: IconButton(
                  icon: Icon(
                    obscureConfirm.value ? Iconsax.eye_slash : Iconsax.eye,
                  ),
                  onPressed: () => obscureConfirm.value = !obscureConfirm.value,
                ),
              ),
            ),
          ),
        ],
      ),
      confirm: ElevatedButton(
        onPressed: () {
          if (oldPasswordCtrl.text.isEmpty ||
              newPasswordCtrl.text.isEmpty ||
              confirmPasswordCtrl.text.isEmpty) {
            Get.snackbar(
              'Error',
              'All fields are required',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.red.shade100,
            );
            return;
          }
          if (newPasswordCtrl.text.length < 6) {
            Get.snackbar(
              'Error',
              'New password must be at least 6 characters',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.red.shade100,
            );
            return;
          }
          if (newPasswordCtrl.text != confirmPasswordCtrl.text) {
            Get.snackbar(
              'Error',
              'New passwords do not match',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.red.shade100,
            );
            return;
          }
          controller.changePassword(
            oldPasswordCtrl.text.trim(),
            newPasswordCtrl.text.trim(),
          );
        },
        child: const Text('Update Password'),
      ),
      cancel: OutlinedButton(
        onPressed: () => Navigator.of(Get.overlayContext!).pop(),
        child: const Text('Cancel'),
      ),
    );
  }

  // ── Edit Name dialog ──
  void _showEditNameDialog(BuildContext context, UserController controller) {
    final firstCtrl = TextEditingController(
      text: controller.user.value.firstName,
    );
    final lastCtrl = TextEditingController(
      text: controller.user.value.lastName,
    );
    Get.defaultDialog(
      contentPadding: const EdgeInsets.all(MSizes.md),
      title: 'Update Name',
      content: Column(
        children: [
          TextField(
            controller: firstCtrl,
            decoration: const InputDecoration(
              labelText: 'First Name',
              prefixIcon: Icon(Iconsax.user),
            ),
          ),
          const SizedBox(height: MSizes.spaceBtwItems),
          TextField(
            controller: lastCtrl,
            decoration: const InputDecoration(
              labelText: 'Last Name',
              prefixIcon: Icon(Iconsax.user),
            ),
          ),
        ],
      ),
      confirm: ElevatedButton(
        onPressed: () {
          controller.firstNameController.text = firstCtrl.text;
          controller.lastNameController.text = lastCtrl.text;
          controller.saveProfile();
        },
        child: const Text('Save'),
      ),
      cancel: OutlinedButton(
        onPressed: () => Navigator.of(Get.overlayContext!).pop(),
        child: const Text('Cancel'),
      ),
    );
  }

  // ── Edit Phone Number dialog ──
  void _showEditPhoneDialog(BuildContext context, UserController controller) {
    final textCtrl = TextEditingController(
      text: controller.user.value.phoneNumber,
    );
    Get.defaultDialog(
      contentPadding: const EdgeInsets.all(MSizes.md),
      title: 'Update Phone Number',
      content: TextField(
        controller: textCtrl,
        decoration: const InputDecoration(
          labelText: 'Phone Number',
          prefixIcon: Icon(Iconsax.call),
        ),
      ),
      confirm: ElevatedButton(
        onPressed: () {
          controller.phoneNumberController.text = textCtrl.text;
          controller.saveProfile();
        },
        child: const Text('Save'),
      ),
      cancel: OutlinedButton(
        onPressed: () => Navigator.of(Get.overlayContext!).pop(),
        child: const Text('Cancel'),
      ),
    );
  }

  // ── Gender picker ──
  void _showGenderPicker(BuildContext context, UserController controller) {
    Get.defaultDialog(
      contentPadding: const EdgeInsets.all(MSizes.md),
      title: 'Select Gender',
      content: Column(
        children: ['Male', 'Female', 'Other'].map((g) {
          return ListTile(
            title: Text(g),
            trailing: controller.user.value.gender == g
                ? const Icon(Icons.check, color: Colors.green)
                : null,
            onTap: () {
              controller.genderController.text = g;
              controller.saveProfile();
            },
          );
        }).toList(),
      ),
    );
  }

  // ── Date of Birth picker ──
  void _showDatePicker(BuildContext context, UserController controller) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      final formatted =
          '${picked.day.toString().padLeft(2, '0')} ${_monthName(picked.month)}, ${picked.year}';
      controller.dateOfBirthController.text = formatted;
      controller.saveProfile();
    }
  }

  /// Show a re-confirmation dialog before closing the account.
  void _showCloseAccountDialog(
    BuildContext context,
    UserController controller,
  ) {
    Get.defaultDialog(
      contentPadding: const EdgeInsets.all(MSizes.md),
      title: 'Close Account',
      middleText:
          'Are you sure you want to permanently delete your account? This action is irreversible and all of your data will be removed.',
      confirm: ElevatedButton(
        onPressed: () {
          Navigator.of(Get.overlayContext!).pop();
          _showFinalConfirmation(context, controller);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          side: const BorderSide(color: Colors.red),
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: MSizes.lg),
          child: Text('Continue', style: TextStyle(color: Colors.white)),
        ),
      ),
      cancel: OutlinedButton(
        onPressed: () => Navigator.of(Get.overlayContext!).pop(),
        child: const Text('Cancel'),
      ),
    );
  }

  /// Final confirmation step — ask user to type "DELETE" to confirm.
  void _showFinalConfirmation(BuildContext context, UserController controller) {
    final confirmController = TextEditingController();
    Get.defaultDialog(
      contentPadding: const EdgeInsets.all(MSizes.md),
      title: 'Final Confirmation',
      content: Column(
        children: [
          const Text(
            'Type DELETE below to permanently close your account.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: MSizes.spaceBtwItems),
          TextField(
            controller: confirmController,
            decoration: const InputDecoration(
              hintText: 'Type DELETE here',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      confirm: ElevatedButton(
        onPressed: () {
          if (confirmController.text.trim().toUpperCase() == 'DELETE') {
            Navigator.of(Get.overlayContext!).pop();
            controller.deleteUserAccount();
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          side: const BorderSide(color: Colors.red),
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: MSizes.lg),
          child: Text('Delete Account', style: TextStyle(color: Colors.white)),
        ),
      ),
      cancel: OutlinedButton(
        onPressed: () => Navigator.of(Get.overlayContext!).pop(),
        child: const Text('Cancel'),
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
}
