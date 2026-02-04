import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:med/common/widgets/appbar/appbar.dart';
import 'package:med/common/widgets/custom_shapes/containers/rounded_container.dart';
import 'package:med/common/widgets/products/cart/coupon_widget.dart';
import 'package:med/common/widgets/success_screen/success_screen.dart';
import 'package:med/features/shop/screens/cart/widgets/cart_item.dart';
import 'package:med/features/shop/screens/checkout/widgets/billing_address_section.dart';
import 'package:med/features/shop/screens/checkout/widgets/billing_amount_section.dart';
import 'package:med/features/shop/screens/checkout/widgets/billing_payment_section.dart';
import 'package:med/navigation_menu.dart';
import 'package:med/utils/constants/colors.dart';
import 'package:med/utils/constants/image_strings.dart';
import 'package:med/utils/constants/sizes.dart';
import 'package:med/utils/helpers/helper_functions.dart';

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

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
          padding: EdgeInsets.all(MSizes.defaultSpace),
          child: Column(
            children: [
              /// Items in Cart
              MCartitem(showAddRemoveButton: false),
              SizedBox(height: MSizes.spaceBtwSections),

              ///-- Coupoun Code Section --///
              MCouponCode(),
              SizedBox(height: MSizes.spaceBtwSections),

              ///-- Billing Details Section --///
              MRoundedContainer(
                padding: EdgeInsets.all(MSizes.md),
                showBorder: true,
                backgroundColor: dark ? MColors.black : MColors.white,
                child: Column(
                  children: [
                    /// Pricing
                    MBillingAmountSection(),
                    SizedBox(height: MSizes.spaceBtwItems),

                    /// Divider
                    Divider(),
                    SizedBox(height: MSizes.spaceBtwItems),

                    /// Payment Methods
                    MBillingPaymentSection(),
                    SizedBox(height: MSizes.spaceBtwItems),

                    /// Address Details
                    MBillingAddressSection(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(MSizes.defaultSpace),
        child: ElevatedButton(
          onPressed: () => Get.to(
            () => SuccessScreen(
              image: MImages.staticSuccessIllustration,
              title: 'Payment Success',
              subTitle: 'Your Item Will Be Shipped Soon!!',
              onPressed: () => Get.offAll(() => const NavigationMenu()),
            ),
          ),
          child: Text('Checkout Rs 391'),
        ),
      ),
    );
  }
}
