import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:med/common/widgets/appbar/appbar.dart';
import 'package:med/common/widgets/custom_shapes/containers/rounded_container.dart';
import 'package:med/common/widgets/products/cart/coupon_widget.dart';
import 'package:med/features/shop/controllers/cart_controller.dart';
import 'package:med/features/shop/controllers/coupon_controller.dart';
import 'package:med/features/shop/controllers/order_controller.dart';
import 'package:med/features/shop/screens/cart/widgets/cart_item.dart';
import 'package:med/features/shop/screens/checkout/widgets/billing_address_section.dart';
import 'package:med/features/shop/screens/checkout/widgets/billing_amount_section.dart';
import 'package:med/features/shop/screens/checkout/widgets/billing_payment_section.dart';
import 'package:med/utils/constants/colors.dart';
import 'package:med/utils/constants/sizes.dart';
import 'package:med/utils/helpers/helper_functions.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  late final OrderController _orderCtrl;
  late final CouponController _couponCtrl;
  late final CartController _cart;

  @override
  void initState() {
    super.initState();
    _orderCtrl = Get.put(OrderController());
    _couponCtrl = Get.put(CouponController());
    _cart = CartController.instance;
    // Auto-attach any previously scanned prescriptions from local history.
    _orderCtrl.autoAttachPrescriptionsFromLocalDB();
  }

  @override
  Widget build(BuildContext context) {
    final dark = MHelperFunctions.isDarkMode(context);

    return Scaffold(
      appBar: MAppBar(
        title: Text(
          'Order Review',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        showBackArrow: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(MSizes.defaultSpace),
          child: Column(
            children: [
              /// Items in Cart (read-only)
              MCartitem(showAddRemoveButton: false),
              const SizedBox(height: MSizes.spaceBtwSections),

              /// Prescription Upload Section (only for prescribed medicines)
              Obx(() {
                if (!_cart.hasPrescribedItems) return const SizedBox.shrink();
                return Column(
                  children: [
                    _PrescriptionUploadSection(orderCtrl: _orderCtrl, dark: dark),
                    const SizedBox(height: MSizes.spaceBtwSections),
                  ],
                );
              }),

              /// Coupon Code Section
              const MCouponCode(),
              const SizedBox(height: MSizes.spaceBtwSections),

              /// Billing Details Section
              MRoundedContainer(
                padding: const EdgeInsets.all(MSizes.md),
                showBorder: true,
                backgroundColor: dark ? MColors.black : MColors.white,
                child: const Column(
                  children: [
                    MBillingAmountSection(),
                    SizedBox(height: MSizes.spaceBtwItems),
                    Divider(),
                    SizedBox(height: MSizes.spaceBtwItems),
                    MBillingPaymentSection(),
                    SizedBox(height: MSizes.spaceBtwItems),
                    MBillingAddressSection(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(MSizes.defaultSpace),
        child: Obx(() {
          final isPlacing = _orderCtrl.isLoading.value;
          final isEmpty = _cart.cartItems.isEmpty;
          final prescriptionMissing =
              _cart.hasPrescribedItems && _orderCtrl.prescriptions.isEmpty;
          final discount = _couponCtrl.discountAmount.value;
          final total =
              _cart.subtotal + _cart.shippingFee + _cart.taxFee - discount;
          return ElevatedButton(
            onPressed: isPlacing || isEmpty
                ? null
                : () => _orderCtrl.placeOrder(),
            style: prescriptionMissing
                ? ElevatedButton.styleFrom(backgroundColor: Colors.grey)
                : null,
            child: isPlacing
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Place Order  Rs ${total.clamp(0, double.infinity).toStringAsFixed(0)}',
                  ),
          );
        }),
      ),
    );
  }
}

// ── Prescription Upload Widget ────────────────────────────────────────────────

class _PrescriptionUploadSection extends StatelessWidget {
  const _PrescriptionUploadSection({
    required this.orderCtrl,
    required this.dark,
  });

  final OrderController orderCtrl;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return MRoundedContainer(
      padding: const EdgeInsets.all(MSizes.md),
      showBorder: true,
      borderColor: Colors.orange,
      backgroundColor: dark ? MColors.black : MColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.medical_services_outlined,
                  color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Prescription Required',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              Obx(() => orderCtrl.prescriptions.isNotEmpty
                  ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
                  : const Icon(Icons.warning_amber_rounded,
                      color: Colors.orange, size: 20)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'One or more items in your cart require a valid prescription.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.orange.shade700),
          ),
          const SizedBox(height: MSizes.spaceBtwItems),

          // Auto-attached label
          Obx(() {
            if (orderCtrl.prescriptions.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.history_edu_outlined,
                      size: 14, color: Colors.green),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Prescription auto-attached from your scan history. '
                      'You can remove and re-upload if needed.',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.green.shade700,
                          ),
                    ),
                  ),
                ],
              ),
            );
          }),

          // Uploaded thumbnails
          Obx(() {
            if (orderCtrl.prescriptions.isEmpty) return const SizedBox.shrink();
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(orderCtrl.prescriptions.length, (i) {
                final Uint8List bytes =
                    base64Decode(orderCtrl.prescriptions[i]);
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        bytes,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 2,
                      right: 2,
                      child: GestureDetector(
                        onTap: () => orderCtrl.removePrescription(i),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(2),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 12),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            );
          }),
          const SizedBox(height: MSizes.spaceBtwItems),

          // Upload / add more button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: orderCtrl.pickPrescription,
              icon: const Icon(Icons.upload_file_outlined),
              label: Obx(() => Text(
                    orderCtrl.prescriptions.isEmpty
                        ? 'Upload Prescription'
                        : 'Add Another Prescription',
                  )),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange,
                side: const BorderSide(color: Colors.orange),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

