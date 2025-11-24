import 'package:flutter/material.dart';
import 'package:med/features/shop/screens/home/widgets/home_appbar.dart';
import '../../../../common/widgets/custom_shapes/containers/primary_header_container.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            MHomeAppbar(),
            MPrimaryHeaderContainer(
              child: Column(
                children: [





                ],
              ),
            ),
          ],
        ),
      ),
    );
}
