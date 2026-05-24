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

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = MHelperFunctions.isDarkMode(context);
    Get.put(OrderController());
    Get.put(CouponController());
    final cart = CartController.instance;
    final couponCtrl = CouponController.instance;

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
          final orderCtrl = OrderController.instance;
          final isPlacing = orderCtrl.isLoading.value;
          final isEmpty = cart.cartItems.isEmpty;
          final discount = couponCtrl.discountAmount.value;
          final total =
              cart.subtotal + cart.shippingFee + cart.taxFee - discount;
          return ElevatedButton(
            onPressed: isPlacing || isEmpty
                ? null
                : () => orderCtrl.placeOrder(),
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
