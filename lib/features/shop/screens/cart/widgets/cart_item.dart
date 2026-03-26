import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:med/common/widgets/products/cart/add_remove_button.dart';
import 'package:med/common/widgets/products/cart/cart_item.dart';
import 'package:med/common/widgets/texts/product_price_text.dart';
import 'package:med/features/shop/controllers/cart_controller.dart';
import 'package:med/utils/constants/sizes.dart';

class MCartitem extends StatelessWidget {
  const MCartitem({super.key, this.showAddRemoveButton = true});
  final bool showAddRemoveButton;

  @override
  Widget build(BuildContext context) {
    final cartCtrl = CartController.instance;
    return Obx(() {
      final items = cartCtrl.cartItems;
      if (items.isEmpty) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(MSizes.defaultSpace),
            child: Text('Your cart is empty'),
          ),
        );
      }
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        separatorBuilder: (_, __) => const Divider(),
        itemCount: items.length,
        itemBuilder: (_, index) {
          final item = items[index];
          if (!showAddRemoveButton) {
            // No observables needed — just show the item row
            return MCartItem(cartItem: item);
          }
          return Obx(() => Column(
            children: [
              MCartItem(cartItem: item),
              const SizedBox(height: MSizes.spaceBtwItems),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const SizedBox(width: 70),
                      MProductQuantityWithAddRemoveButton(
                        quantity: item.quantity.value,
                        onAdd: () => cartCtrl.incrementQuantity(item),
                        onRemove: () => cartCtrl.decrementQuantity(item),
                      ),
                    ],
                  ),
                  MProductPriceText(price: item.lineTotal.toStringAsFixed(0)),
                ],
              ),
            ],
          ));
        },
      );
    });
  }
}
