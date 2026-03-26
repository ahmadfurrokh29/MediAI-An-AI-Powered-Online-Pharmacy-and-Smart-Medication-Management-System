import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:med/common/widgets/appbar/appbar.dart';
import 'package:med/features/shop/controllers/cart_controller.dart';
import 'package:med/features/shop/screens/cart/widgets/cart_item.dart';
import 'package:med/features/shop/screens/checkout/checkout.dart';
import 'package:med/utils/constants/sizes.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cartCtrl = CartController.instance;
    return Scaffold(
      appBar: MAppBar(
        title: Text('Cart', style: Theme.of(context).textTheme.headlineSmall),
        showBackArrow: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(MSizes.defaultSpace),
          child: MCartitem(),
        ),
      ),
      bottomNavigationBar: Obx(() {
        if (cartCtrl.cartItems.isEmpty) return const SizedBox.shrink();
        final total = cartCtrl.totalAmount;
        return Padding(
          padding: const EdgeInsets.all(MSizes.defaultSpace),
          child: ElevatedButton(
            onPressed: () => Get.to(() => const CheckoutScreen()),
            child: Text('Checkout Rs ${total.toStringAsFixed(0)}'),
          ),
        );
      }),
    );
  }
}
