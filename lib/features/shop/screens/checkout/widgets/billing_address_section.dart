import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:med/common/widgets/texts/section_heading.dart';
import 'package:med/features/personalization/controllers/address_controller.dart';
import 'package:med/features/personalization/screens/address/address.dart';
import 'package:med/utils/constants/sizes.dart';

class MBillingAddressSection extends StatelessWidget {
  const MBillingAddressSection({super.key});

  @override
  Widget build(BuildContext context) {
    final addrCtrl = Get.put(AddressController());
    return Obx(() {
      final addr = addrCtrl.selectedAddress;
      final name = (addr['name'] as String? ?? '').trim();
      final phone = (addr['phoneNumber'] as String? ?? '').trim();
      final display = addrCtrl.displayFor(addr);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MSectionHeading(
            title: 'Shipping Address',
            buttontitle: 'Change',
            onPressed: () => Get.to(() => UserAddressScreen()),
          ),
          const SizedBox(height: MSizes.spaceBtwItems / 2),
          if (name.isEmpty && phone.isEmpty && display.isEmpty)
            Text('No address selected. Tap Change to add one.',
                style: Theme.of(context).textTheme.bodyMedium),
          if (name.isNotEmpty)
            Text(name, style: Theme.of(context).textTheme.bodyLarge),
          if (phone.isNotEmpty) ...[
            const SizedBox(height: MSizes.spaceBtwItems / 2),
            Row(
              children: [
                const Icon(Icons.phone, color: Colors.grey, size: 16),
                const SizedBox(width: MSizes.spaceBtwItems),
                Text(phone, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ],
          if (display.isNotEmpty) ...[
            const SizedBox(height: MSizes.spaceBtwItems / 2),
            Row(
              children: [
                const Icon(Icons.location_city, color: Colors.grey, size: 16),
                const SizedBox(width: MSizes.spaceBtwItems),
                Expanded(
                  child: Text(display,
                      style: Theme.of(context).textTheme.bodyMedium),
                ),
              ],
            ),
          ],
          const SizedBox(height: MSizes.spaceBtwItems / 2),
        ],
      );
    });
  }
}
