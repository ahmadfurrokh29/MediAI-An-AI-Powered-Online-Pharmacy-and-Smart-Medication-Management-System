import 'package:flutter/material.dart';
import 'package:med/common/widgets/appbar/appbar.dart';
import 'package:med/common/widgets/appbar/tabbar.dart';
import 'package:med/features/personalization/Stock-_and_reminder_management/lib/screens/reminder/reminder_screen.dart';
import 'package:med/features/personalization/Stock-_and_reminder_management/lib/screens/stock_management_screen.dart';

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
                  // Medicine Reminder Tab
                  RemindersScreen(showAppBar: false),
                  // Medicines In-stock Tab
                  StockManagementScreen(showAppBar: false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
