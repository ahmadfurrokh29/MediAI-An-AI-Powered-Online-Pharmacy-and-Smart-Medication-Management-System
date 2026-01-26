import 'dart:io';

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:med/common/widgets/appbar/appbar.dart';
import 'package:med/utils/constants/sizes.dart';

class AddNewMedicationScreen extends StatefulWidget {
  const AddNewMedicationScreen({Key? key}) : super(key: key);

  @override
  State<AddNewMedicationScreen> createState() => _AddNewMedicationScreenState();
}

class _AddNewMedicationScreenState extends State<AddNewMedicationScreen> {
  final ImagePicker _picker = ImagePicker();
  File? scannedImage;

  /// Open Camera
  Future<void> _openCamera() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() {
        scannedImage = File(image.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MAppBar(
        showBackArrow: true,
        title: const Text('Medication Form'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(MSizes.defaultSpace),
          child: Form(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Heading + Scan Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Enter Medication Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: _openCamera,
                      icon: const Icon(Iconsax.scan),
                    ),
                  ],
                ),

                /// Preview Scanned Image
                if (scannedImage != null) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      scannedImage!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],

                const SizedBox(height: MSizes.defaultSpace),

                /// Disease Name
                TextFormField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Iconsax.health),
                    labelText: 'Disease Name',
                  ),
                ),

                const SizedBox(height: MSizes.spaceBtwInputFields),

                /// Allergies
                TextFormField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Iconsax.warning_2),
                    labelText: 'Allergies',
                  ),
                ),

                const SizedBox(height: MSizes.spaceBtwInputFields),

                /// Health Condition
                TextFormField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Iconsax.heart),
                    labelText: 'Health Condition',
                  ),
                ),

                const SizedBox(height: MSizes.spaceBtwInputFields),

                /// Current Medications
                TextFormField(
                  maxLines: 3,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Iconsax.document),
                    labelText: 'Current Medications',
                  ),
                ),

                const SizedBox(height: MSizes.defaultSpace),

                /// Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Save medication data
                    },
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
