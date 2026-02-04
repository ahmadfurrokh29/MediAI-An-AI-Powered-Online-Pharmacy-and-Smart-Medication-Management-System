import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:med/common/widgets/loaders/animation_loader.dart';
import 'package:med/utils/constants/colors.dart';
import 'package:med/utils/helpers/helper_functions.dart';

/// A utility class for managing a full-screen loading dialog.
class MFullScreenLoader {
  /// Open a full-screen loading dialog with a given text and animation.
  static void openLoadingDialog(String text, String animation) {
    showDialog(
      context: Get.overlayContext!,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: MHelperFunctions.isDarkMode(Get.context!)
              ? MColors.dark
              : MColors.white,
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min, // 🔥 CRITICAL FIX
                children: [
                  MAnimationLoaderWidget(text: text, animation: animation),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Stop the currently open loading dialog.
  static void stopLoading() {
    if (Get.overlayContext != null) {
      Navigator.of(Get.overlayContext!).pop();
    }
  }
}
