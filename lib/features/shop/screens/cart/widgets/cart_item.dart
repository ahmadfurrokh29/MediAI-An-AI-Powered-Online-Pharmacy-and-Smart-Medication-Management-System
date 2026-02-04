import 'package:flutter/material.dart';
import 'package:med/common/widgets/products/cart/add_remove_button.dart';
import 'package:med/common/widgets/products/cart/cart_item.dart';
import 'package:med/common/widgets/texts/product_price_text.dart';
import 'package:med/utils/constants/sizes.dart';

class MCartitem extends StatelessWidget {
  const MCartitem({super.key, this.showAddRemoveButton = true});
  final bool showAddRemoveButton;
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      separatorBuilder: (_, _) => const Divider(),
      itemCount: 3,
      itemBuilder: (_, index) => Column(
        children: [
          MCartItem(),
          if (showAddRemoveButton) const SizedBox(height: MSizes.spaceBtwItems),
          if (showAddRemoveButton)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    /// to align with the text
                    SizedBox(width: 70),

                    /// Add and Remove Button
                    MProductQuantityWithAddRemoveButton(),
                  ],
                ),

                /// product total price
                MProductPriceText(price: '256'),
              ],
            ),
        ],
      ),
    );
  }
}
