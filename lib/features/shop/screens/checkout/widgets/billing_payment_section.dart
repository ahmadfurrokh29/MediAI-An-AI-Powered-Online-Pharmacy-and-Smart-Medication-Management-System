import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:med/common/widgets/payment/payment_logos.dart';
import 'package:med/common/widgets/texts/section_heading.dart';
import 'package:med/features/shop/controllers/payment_controller.dart';
import 'package:med/utils/constants/colors.dart';
import 'package:med/utils/constants/sizes.dart';

class MBillingPaymentSection extends StatelessWidget {
  const MBillingPaymentSection({super.key});

  // ── Bottom sheet that lets the user pick a payment method ─────────────────
  static void _showPickerSheet(BuildContext context, PaymentController ctrl) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PaymentPickerSheet(ctrl: ctrl),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(PaymentController());
    return Obx(() {
      final bool isCOD = ctrl.selectedMethod.value == null;
      final String label = ctrl.methodLabel;
      final String sub = isCOD
          ? 'Pay when your order arrives'
          : ctrl.selectedMethod.value!.displayLabel;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MSectionHeading(
            title: 'Payment Method',
            buttontitle: 'Change',
            onPressed: () => _showPickerSheet(context, ctrl),
          ),
          const SizedBox(height: MSizes.spaceBtwItems / 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: MColors.primary, width: 1.5),
              borderRadius: BorderRadius.circular(MSizes.cardRadiusSm),
              color: MColors.primary.withValues(alpha: 0.05),
            ),
            child: Row(
              children: [
                isCOD
                    ? const Icon(
                        Iconsax.money,
                        size: 28,
                        color: MColors.primary,
                      )
                    : PaymentLogo(
                        type: ctrl.selectedMethod.value!.typeString,
                        size: 32,
                      ),
                const SizedBox(width: MSizes.spaceBtwItems),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (sub.isNotEmpty)
                        Text(
                          sub,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: MColors.darkerGrey),
                        ),
                    ],
                  ),
                ),
                const Icon(
                  Iconsax.tick_circle5,
                  color: MColors.primary,
                  size: 20,
                ),
              ],
            ),
          ),
        ],
      );
    });
  }
}

// ── Bottom-sheet payment picker ────────────────────────────────────────────

class _PaymentPickerSheet extends StatelessWidget {
  const _PaymentPickerSheet({required this.ctrl});
  final PaymentController ctrl;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 20, bottom: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Select Payment Method',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // ── Cash on Delivery ──────────────────────────────────────────
          Obx(
            () => _MethodTile(
              leading: const Icon(
                Iconsax.money,
                size: 32,
                color: Color(0xFF4A5568),
              ),
              title: 'Cash on Delivery',
              subtitle: 'Pay when your order arrives',
              selected: ctrl.selectedMethod.value == null,
              onTap: () {
                ctrl.selectedMethod.value = null;
                Navigator.pop(context);
              },
            ),
          ),

          // ── Saved payment methods ─────────────────────────────────────
          Obx(() {
            if (ctrl.isLoading.value) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (ctrl.paymentMethods.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No saved payment methods. Add one in Bank Account settings.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              );
            }
            return Column(
              children: ctrl.paymentMethods.map((method) {
                return Obx(
                  () => _MethodTile(
                    leading: PaymentLogo(type: method.typeString, size: 32),
                    title: method.typeLabel,
                    subtitle: method.displayLabel,
                    selected: ctrl.selectedMethod.value?.id == method.id,
                    onTap: () {
                      ctrl.selectedMethod.value = method;
                      Navigator.pop(context);
                    },
                  ),
                );
              }).toList(),
            );
          }),
        ],
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  const _MethodTile({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final Widget leading;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
            leading,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: selected ? MColors.primary : null,
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: MColors.darkerGrey,
                      ),
                    ),
                ],
              ),
            ),
            if (selected)
              const Icon(
                Iconsax.tick_circle5,
                color: MColors.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
