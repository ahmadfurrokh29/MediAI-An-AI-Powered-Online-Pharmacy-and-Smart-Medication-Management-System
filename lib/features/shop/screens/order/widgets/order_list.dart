import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:med/common/widgets/custom_shapes/containers/rounded_container.dart';
import 'package:med/features/shop/controllers/order_controller.dart';
import 'package:med/features/shop/models/order_model.dart';
import 'package:med/utils/constants/colors.dart';
import 'package:med/utils/constants/sizes.dart';
import 'package:med/utils/helpers/helper_functions.dart';

class MOrderListItems extends StatelessWidget {
  const MOrderListItems({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(OrderController());

    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.orders.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              const Icon(Iconsax.box, size: 60, color: MColors.grey),
              const SizedBox(height: MSizes.spaceBtwItems),
              Text(
                'No orders yet',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        );
      }

      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: controller.orders.length,
        separatorBuilder: (_, __) =>
            const SizedBox(height: MSizes.spaceBtwItems),
        itemBuilder: (_, index) => _OrderCard(order: controller.orders[index]),
      );
    });
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});
  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final dark = MHelperFunctions.isDarkMode(context);

    return MRoundedContainer(
      showBorder: true,
      padding: const EdgeInsets.all(MSizes.md),
      backgroundColor: dark ? MColors.dark : MColors.light,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          /// Row 1 – status and date
          Row(
            children: [
              const Icon(Iconsax.ship),
              const SizedBox(width: MSizes.spaceBtwItems / 2),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.orderStatus,
                      style: Theme.of(context).textTheme.bodyLarge!.apply(
                        color: MColors.primary,
                        fontWeightDelta: 1,
                      ),
                    ),
                    Text(
                      order.formattedDate,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Iconsax.arrow_right, size: MSizes.iconSm),
              ),
            ],
          ),
          const SizedBox(height: MSizes.spaceBtwItems),

          /// Row 2 – Order ID and total
          Row(
            children: [
              /// Order ID
              Expanded(
                child: Row(
                  children: [
                    const Icon(Iconsax.tag),
                    const SizedBox(width: MSizes.spaceBtwItems / 2),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order ID',
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                          Text(
                            order.shortId,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              /// Total amount
              Expanded(
                child: Row(
                  children: [
                    const Icon(Iconsax.money),
                    const SizedBox(width: MSizes.spaceBtwItems / 2),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total',
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                          Text(
                            'Rs ${order.totalAmount.toStringAsFixed(0)}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
