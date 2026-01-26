import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/instance_manager.dart';
import 'package:med/common/widgets/appbar/appbar.dart';
import 'package:med/common/widgets/appbar/tabbar.dart';
import 'package:med/common/widgets/brands/brand_card.dart';
import 'package:med/common/widgets/custom_shapes/containers/search_container.dart';
import 'package:med/common/widgets/layouts/grid_layout.dart';
import 'package:med/common/widgets/products/cart/cart_menu_icon.dart';
import 'package:med/common/widgets/texts/section_heading.dart';
import 'package:med/features/shop/screens/brand/all_brands.dart';
import 'package:med/features/shop/screens/brand/brand_products.dart';
import 'package:med/features/shop/screens/store/widgets/category_tab.dart';
import 'package:med/utils/constants/sizes.dart';
import 'package:med/utils/helpers/helper_functions.dart';

class Store extends StatelessWidget {
  const Store({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = MHelperFunctions.isDarkMode(context);
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        //Appbar should be added here
        appBar: MAppBar(
          title: Text(
            'Store',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          actions: [
            MCartCounterIcon(
              onPressed: () {},
              iconColor: dark ? Colors.white : Colors.black,
            ),
          ],
        ),
        body: NestedScrollView(
          //header
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                automaticallyImplyLeading: false,
                pinned: true,
                floating: true,
                backgroundColor: dark ? Colors.black : Colors.white,
                expandedHeight: 440,

                flexibleSpace: Padding(
                  padding: EdgeInsets.all(MSizes.defaultSpace),
                  child: ListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      SizedBox(height: MSizes.spaceBtwItems),
                      //Search Container
                      MSearchContainer(
                        text: 'search in store',
                        showBorder: true,
                        showBackground: false,
                        padding: EdgeInsets.zero,
                      ),
                      SizedBox(height: MSizes.spaceBtwSections),
                      //Featured Brands Section
                      MSectionHeading(
                        title: 'Featured Brands',
                        onPressed: () => Get.to(() => const AllBrandsScreen()),
                      ),
                      const SizedBox(height: MSizes.spaceBtwItems / 1.5),
                      //_____________________________________________________code is correct till here
                      //Brands Grid
                      MGridLayout(
                        itemCount: 4,
                        mainAxisExtent: 80,
                        itemBuilder: (_, index) {
                          return MBrandCard(
                            showBorder: true,
                            onTap: () => Get.to(() => const BrandProducts()),
                          );
                        }, //_________________________________________________________till here
                      ),
                    ],
                  ),
                ),
                //Tabs
                bottom: const MTabBar(
                  tabs: [
                    Tab(child: Text('View All')),
                    Tab(child: Text('Medicines')),
                    Tab(child: Text('Supplements')),
                    Tab(child: Text('Personal Care')),
                    Tab(child: Text('Health Foods')),
                    Tab(child: Text('Medical Devices')),
                  ],
                ),
              ),
            ];
          },
          //Body
          body: const TabBarView(
            children: [
              MCategoryTab(),
              MCategoryTab(),
              MCategoryTab(),
              MCategoryTab(),
              MCategoryTab(),
              MCategoryTab(),
            ],
          ),
        ),
      ),
    );
  }
}
