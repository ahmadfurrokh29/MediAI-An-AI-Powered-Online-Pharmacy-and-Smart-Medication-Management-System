import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:med/common/widgets/texts/section_heading.dart';
import 'package:med/features/personalization/screens/bank_account/bank_account.dart';
import 'package:med/features/shop/controllers/payment_controller.dart';
import 'package:med/utils/constants/colors.dart';
import 'package:med/utils/constants/sizes.dart';

class MBillingPaymentSection extends StatelessWidget {
  const MBillingPaymentSection({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(PaymentController());
    return Obx(() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MSectionHeading(
            title: 'Payment Method',
            buttontitle: 'Manage Cards',
            onPressed: () => Get.to(() => const BankAccountScreen()),
          ),
          const SizedBox(height: MSizes.spaceBtwItems / 2),

          /// Cash on Delivery
          _PaymentTile(
            icon: Iconsax.money,
            title: 'Cash on Delivery',
            selected: ctrl.selectedMethod.value == PaymentMethod.cashOnDelivery,
            onTap: () => ctrl.selectedMethod.value = PaymentMethod.cashOnDelivery,
          ),
          const SizedBox(height: MSizes.spaceBtwItems / 2),

          /// Card Payment
          _PaymentTile(
            icon: Iconsax.card,
            title: ctrl.hasCard.value
                ? 'Card ****${ctrl.cardNumber.value.length >= 4 ? ctrl.cardNumber.value.substring(ctrl.cardNumber.value.length - 4) : ''}'
                : 'Card Payment (add card first)',
            selected: ctrl.selectedMethod.value == PaymentMethod.card,
            enabled: ctrl.hasCard.value,
            onTap: ctrl.hasCard.value
                ? () => ctrl.selectedMethod.value = PaymentMethod.card
                : () {
                    Get.snackbar('No Card', 'Please add a card in My Bank section first.',
                        snackPosition: SnackPosition.BOTTOM);
                  },
          ),
        ],
      );
    });
  }
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? MColors.primary : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(MSizes.cardRadiusSm),
          color: selected
              ? MColors.primary.withValues(alpha: 0.05)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(icon, size: 24, color: enabled ? null : Colors.grey),
            const SizedBox(width: MSizes.spaceBtwItems),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: enabled ? null : Colors.grey,
                    ),
              ),
            ),
            if (selected)
              const Icon(Iconsax.tick_circle5,
                  color: MColors.primary, size: 20),
          ],
        ),
      ),
    );
  }
}
