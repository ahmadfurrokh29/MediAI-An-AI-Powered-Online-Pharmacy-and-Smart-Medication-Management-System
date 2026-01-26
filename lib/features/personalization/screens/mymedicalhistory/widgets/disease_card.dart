import 'package:flutter/material.dart';
import 'package:med/features/personalization/screens/mymedicalhistory/widgets/disease_container.dart';
import 'package:med/utils/constants/sizes.dart';

class MDiseaseCard extends StatelessWidget {
  const MDiseaseCard({super.key, required this.isChronic});
  final bool isChronic;
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(MSizes.defaultSpace),
        child: Column(
          children: [
            MDiseaseContainer(isChronic: isChronic),
            MDiseaseContainer(isChronic: isChronic),
          ],
        ),
      ),
    );
  }
}
