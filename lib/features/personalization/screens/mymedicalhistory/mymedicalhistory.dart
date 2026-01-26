import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/utils.dart';
import 'package:iconsax/iconsax.dart';
import 'package:med/common/widgets/appbar/appbar.dart';
import 'package:med/common/widgets/appbar/tabbar.dart';
import 'package:med/features/personalization/screens/mymedicalhistory/widgets/disease_card.dart';
import 'package:med/features/personalization/screens/mymedicalhistory/widgets/disease_form.dart';
import 'package:med/utils/constants/colors.dart';

class MMyMedicalHistoryScreen extends StatelessWidget {
  const MMyMedicalHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          backgroundColor: MColors.primary,
          onPressed: () => Get.to(() => const AddNewMedicationScreen()),
          child: Icon(Iconsax.add, color: MColors.white),
          shape: CircleBorder(),
        ),
        appBar: MAppBar(
          title: Text(
            'Medical History',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          showBackArrow: true,
        ),
        body: Column(
          children: [
            MTabBar(
              tabs: [
                Tab(child: Text('Chronic Diseases')),
                Tab(child: Text('Non-Chronic Diseases')),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // Chronic Diseases Tab Content
                  MDiseaseCard(isChronic: true),
                  // Non-Chronic Diseases Tab Content
                  MDiseaseCard(isChronic: false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
