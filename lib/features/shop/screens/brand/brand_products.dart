import 'package:flutter/material.dart';
import 'package:med/common/widgets/appbar/appbar.dart';
import 'package:med/common/widgets/brands/brand_card.dart';
import 'package:med/common/widgets/products/sortable/sortable_products.dart';
import 'package:med/utils/constants/sizes.dart';

class BrandProducts extends StatelessWidget {
  const BrandProducts({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MAppBar(title: Text('Medicine'), showBackArrow: true),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(MSizes.defaultSpace),
          child: Column(
            children: [
              ///Brand Details
              MBrandCard(showBorder: true),
              SizedBox(height: MSizes.spaceBtwSections),

              MSortableProducts(),
            ],
          ),
        ),
      ),
    );
  }
}
