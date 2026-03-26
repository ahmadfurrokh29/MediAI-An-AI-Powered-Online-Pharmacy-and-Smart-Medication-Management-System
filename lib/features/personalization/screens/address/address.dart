import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:med/common/widgets/appbar/appbar.dart';
import 'package:med/features/personalization/controllers/address_controller.dart';
import 'package:med/features/personalization/screens/address/add_new_address.dart';
import 'package:med/features/personalization/screens/address/widgets/single_address.dart';
import 'package:med/utils/constants/colors.dart';
import 'package:med/utils/constants/sizes.dart';

class UserAddressScreen extends StatelessWidget {
  const UserAddressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AddressController());

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: MColors.primary,
        onPressed: () {
          controller.clearForm();
          Get.to(() => const AddNewAddressScreen());
        },
        shape: const CircleBorder(),
        child: const Icon(Iconsax.add, color: MColors.white),
      ),
      appBar: MAppBar(
        showBackArrow: true,
        title: Text(
          'Addresses',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!controller.hasAddresses) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Iconsax.location, size: 60, color: MColors.grey),
                const SizedBox(height: MSizes.spaceBtwItems),
                Text(
                  'No address saved',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: MSizes.sm),
                Text(
                  'Tap + to add your delivery address',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(MSizes.defaultSpace),
          itemCount: controller.addresses.length,
          itemBuilder: (_, index) {
            final addr = controller.addresses[index];
            final isSelected = controller.selectedIndex.value == index;
            return MSigleAddress(
              address: addr,
              selectedAdress: isSelected,
              onTap: () => controller.selectAddress(index),
              onEdit: () {
                controller.populateForm(addr);
                Get.to(() => AddNewAddressScreen(editIndex: index));
              },
              onDelete: () => _confirmDelete(context, controller, index),
            );
          },
        );
      }),
    );
  }

  void _confirmDelete(
    BuildContext context,
    AddressController controller,
    int index,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Address'),
        content: const Text('Remove this address from your list?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Get.back();
              controller.deleteAddress(index);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
