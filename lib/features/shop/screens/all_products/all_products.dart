import 'package:flutter/material.dart';
import 'package:med/common/widgets/appbar/appbar.dart';
import 'package:med/common/widgets/products/sortable/sortable_products.dart';
import 'package:med/utils/constants/sizes.dart';

class AllProducts extends StatelessWidget {
  const AllProducts({super.key, this.title = 'All Products', this.products});

  /// Page title shown in the app bar.
  final String title;

  /// Optional pre-fetched product list (from a subcategory).
  /// When null the sortable grid renders placeholder / demo cards.
  final List<Map<String, dynamic>>? products;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MAppBar(title: Text(title), showBackArrow: true),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(MSizes.defaultSpace),
          child: MSortableProducts(products: products),
        ),
      ),
    );
  }
}
