import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:med/common/widgets/layouts/grid_layout.dart';
import 'package:med/common/widgets/products/product_cards/product_card_vertical.dart';
import 'package:med/utils/constants/sizes.dart';

class MSortableProducts extends StatefulWidget {
  const MSortableProducts({super.key, this.products});

  /// Optional list of product maps to display.
  /// When null, renders 8 placeholder/demo cards.
  final List<Map<String, dynamic>>? products;

  @override
  State<MSortableProducts> createState() => _MSortableProductsState();
}

class _MSortableProductsState extends State<MSortableProducts> {
  String _sortOption = 'Name';

  List<Map<String, dynamic>> get _sorted {
    final list = List<Map<String, dynamic>>.from(widget.products ?? []);
    switch (_sortOption) {
      case 'Higher Price':
        list.sort((a, b) => (b['price'] as num).compareTo(a['price'] as num));
      case 'Lower Price':
        list.sort((a, b) => (a['price'] as num).compareTo(b['price'] as num));
      case 'Sale':
        list.sort((a, b) {
          final aDiscount = (a['price'] as num) - (a['salePrice'] as num);
          final bDiscount = (b['price'] as num) - (b['salePrice'] as num);
          return bDiscount.compareTo(aDiscount);
        });
      case 'Name':
      default:
        list.sort(
          (a, b) => (a['name'] as String).compareTo(b['name'] as String),
        );
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final hasData = widget.products != null;
    final displayList = hasData ? _sorted : <Map<String, dynamic>>[];
    final itemCount = hasData ? displayList.length : 8;

    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: _sortOption,
          decoration: const InputDecoration(prefixIcon: Icon(Iconsax.sort)),
          items: [
            'Name',
            'Higher Price',
            'Lower Price',
            'Sale',
            'Newest',
            'Popularity',
          ].map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
          onChanged: (value) {
            if (value != null) setState(() => _sortOption = value);
          },
        ),
        const SizedBox(height: MSizes.spaceBtwSections),

        if (hasData && displayList.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: Text('No products found.')),
          )
        else
          MGridLayout(
            itemCount: itemCount,
            itemBuilder: (_, i) => MProductCardVertical(
              productData: hasData ? displayList[i] : null,
            ),
          ),
      ],
    );
  }
}
