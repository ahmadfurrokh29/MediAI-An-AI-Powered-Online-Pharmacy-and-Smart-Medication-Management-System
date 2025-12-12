import 'package:flutter/material.dart';
import '../../../../utils/constants/colors.dart';
import '../curved_edges/curved_edges_widget.dart';
import 'circular_container.dart';

class MPrimaryHeaderContainer extends StatelessWidget {
  const MPrimaryHeaderContainer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MCurvedEdgeWidget(
      child: Container(
        color: MColors.primary,
        padding: const EdgeInsets.all(0),
        child: SizedBox(
          height: 400,
          child: Stack(
            children: [
              // 1. Decorative Positioned Circles (Bottom Layers)
              Positioned(
                top: -150,
                right: -250,
                child: MCircularContainer(
                  backgroundColor: MColors.textWhite.withValues(alpha: 0.1), // Used withOpacity for simplicity
                ),
              ),
              Positioned(
                top: 100,
                right: -300,
                child: MCircularContainer(
                  backgroundColor: MColors.textWhite.withValues(alpha: 0.1),
                ),
              ),

              // 2. The Main Content (Top Layer)
              // THIS IS THE MISSING PIECE!
              child, // The Column containing MSearchContainer, MSectionHeading, etc.
            ],
          ),
        ),
      ),
    );
  }
}