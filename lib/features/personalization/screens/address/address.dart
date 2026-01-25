import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:med/common/widgets/appbar/appbar.dart';
import 'package:med/features/personalization/screens/address/add_new_address.dart';
import 'package:med/features/personalization/screens/address/widgets/single_address.dart';
import 'package:med/utils/constants/colors.dart';
import 'package:med/utils/constants/sizes.dart';

class UserAddressScreen extends StatelessWidget {
  const UserAddressScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: MColors.primary,
        onPressed: () => Get.to(() => const AddNewAddressScreen()),
        child: Icon(Iconsax.add, color: MColors.white),
        shape: CircleBorder(),
      ),
      appBar: MAppBar(
        showBackArrow: true,
        title: Text(
          'Addresses',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(MSizes.defaultSpace),
          child: Column(
            children: [
              MSigleAddress(selectedAdress: true),
              MSigleAddress(selectedAdress: false),
            ],
          ),
        ),
      ),
    );
  }
}
