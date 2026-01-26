import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:med/common/widgets/layouts/grid_layout.dart';
import 'package:med/common/widgets/products/product_cards/product_card_vertical.dart';
import 'package:med/utils/constants/sizes.dart';

class MSortableProducts extends StatelessWidget {
  const MSortableProducts({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DropdownButtonFormField(
          decoration: InputDecoration(prefixIcon: Icon(Iconsax.sort)),
          items:
              [
                    'Name',
                    'Higher Price',
                    'Lower Price',
                    'Sale',
                    'Newest',
                    'Popularity',
                  ]
                  .map(
                    (option) =>
                        DropdownMenuItem(value: option, child: Text(option)),
                  )
                  .toList(),

          onChanged: (value) {},
        ),
        SizedBox(height: MSizes.spaceBtwSections),

        /// products
        MGridLayout(
          itemCount: 8,
          itemBuilder: (_, __) => MProductCardVertical(),
        ),
      ],
    );
  }
}
