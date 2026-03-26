import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:med/common/widgets/appbar/appbar.dart';
import 'package:med/features/personalization/controllers/address_controller.dart';
import 'package:med/utils/constants/sizes.dart';

class AddNewAddressScreen extends StatelessWidget {
  const AddNewAddressScreen({super.key, this.editIndex});

  /// When non-null, we are editing the address at this index rather than adding.
  final int? editIndex;

  bool get isEditing => editIndex != null;

  @override
  Widget build(BuildContext context) {
    // Re-use the existing controller if already registered, else create one.
    final controller = Get.isRegistered<AddressController>()
        ? AddressController.instance
        : Get.put(AddressController());

    return Scaffold(
      appBar: MAppBar(
        showBackArrow: true,
        title: Text(isEditing ? 'Edit Address' : 'Add New Address'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(MSizes.defaultSpace),
          child: Form(
            key: controller.formKey,
            child: Column(
              children: [
                /// Name
                TextFormField(
                  controller: controller.nameController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Iconsax.user),
                    labelText: 'Name',
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
                ),
                const SizedBox(height: MSizes.spaceBtwInputFields),

                /// Phone
                TextFormField(
                  controller: controller.phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Iconsax.mobile),
                    labelText: 'Phone Number',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Enter a phone number'
                      : null,
                ),
                const SizedBox(height: MSizes.spaceBtwInputFields),

                /// House No + Street
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: controller.houseNoController,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Iconsax.home),
                          labelText: 'House No.',
                        ),
                      ),
                    ),
                    const SizedBox(width: MSizes.spaceBtwInputFields),
                    Expanded(
                      child: TextFormField(
                        controller: controller.streetController,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Iconsax.building_31),
                          labelText: 'Street',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: MSizes.spaceBtwInputFields),

                /// Postal Code (full width)
                TextFormField(
                  controller: controller.postalCodeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Iconsax.code),
                    labelText: 'Postal Code',
                  ),
                ),
                const SizedBox(height: MSizes.spaceBtwInputFields),

                /// City + Sector/Town (state)
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: controller.cityController,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Iconsax.building),
                          labelText: 'City',
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Enter a city'
                            : null,
                      ),
                    ),
                    const SizedBox(width: MSizes.spaceBtwInputFields),
                    Expanded(
                      child: TextFormField(
                        controller: controller.stateController,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Iconsax.activity),
                          labelText: 'Sector/Town',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: MSizes.spaceBtwInputFields),

                /// Country (Complete Address maps to country in schema)
                TextFormField(
                  controller: controller.countryController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Iconsax.location),
                    labelText: 'Country',
                  ),
                ),
                const SizedBox(height: MSizes.defaultSpace),

                /// Save button
                Obx(
                  () => SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: controller.isSaving.value
                          ? null
                          : isEditing
                          ? () => controller.updateAddress(editIndex!)
                          : controller.saveNewAddress,
                      child: controller.isSaving.value
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(isEditing ? 'Update' : 'Save'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
