import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:med/common/widgets/appbar/appbar.dart';

import 'package:med/features/shop/screens/cart/widgets/cart_item.dart';
import 'package:med/features/shop/screens/checkout/checkout.dart';
import 'package:med/utils/constants/sizes.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MAppBar(
        title: Text('Cart', style: Theme.of(context).textTheme.headlineSmall),
        showBackArrow: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(MSizes.defaultSpace),
          child: Container(child: MCartitem()),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(MSizes.defaultSpace),
        child: ElevatedButton(
          onPressed: () => Get.to(() => CheckoutScreen()),
          child: Text('Checkout Rs 768'),
        ),
      ),
    );
  }
}
