import 'package:flutter/material.dart';
import 'package:med/common/widgets/appbar/appbar.dart';
import 'package:med/features/shop/screens/order/widgets/order_list.dart';
import 'package:med/utils/constants/sizes.dart';

class OrderScreen extends StatelessWidget {
  static const String routeName = '/orders';

  const OrderScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MAppBar(
        title: Text(
          'My Orders',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        showBackArrow: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(MSizes.defaultSpace),
        child: MOrderListItems(),
      ),
    );
  }
}
