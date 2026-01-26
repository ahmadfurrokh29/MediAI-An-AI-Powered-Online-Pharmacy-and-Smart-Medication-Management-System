import 'package:flutter/material.dart';
import 'package:med/common/widgets/appbar/appbar.dart';
import 'package:med/common/widgets/appbar/tabbar.dart';

class MMyMedicationScreen extends StatelessWidget {
  const MMyMedicationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: MAppBar(
          title: Text(
            'My Medication',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          showBackArrow: true,
        ),
        body: Column(
          children: [
            MTabBar(
              tabs: [
                Tab(child: Text('Medicine Reminder')),
                Tab(child: Text('Medicines In-stock')),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // Chronic Diseases Tab Content
                  Center(child: Text('Alarm Cards Will display here')),
                  // Non-Chronic Diseases Tab Content
                  Center(
                    child: Center(
                      child: Text(
                        'Ongoing Medicine Course Detail Card Display',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
