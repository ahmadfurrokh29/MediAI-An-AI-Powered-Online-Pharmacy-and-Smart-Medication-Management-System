import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:med/common/widgets/appbar/appbar.dart';
import 'package:med/utils/constants/colors.dart';
import 'package:med/utils/constants/sizes.dart';
import 'package:med/utils/helpers/helper_functions.dart';

class ChatbotScreen extends StatelessWidget {
  const ChatbotScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = MHelperFunctions.isDarkMode(context);
    return Scaffold(
      appBar: MAppBar(
        title: Text(
          'AI Pharmacist',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),

      /// Chat Area
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(MSizes.defaultSpace),
              children: [
                Center(
                  child: Text(
                    'Chatbot will be implemented here.',
                    style: Theme.of(context).textTheme.bodyMedium!.apply(
                      color: dark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      /// Chat Input Field
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(MSizes.defaultSpace),
          child: Row(
            children: [
              /// Input Field
              Expanded(
                child: TextFormField(
                  decoration: InputDecoration(
                    hintText: 'Type your message...',
                    filled: true,
                    fillColor: dark ? MColors.dark : Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              /// Send Button
              CircleAvatar(
                radius: 24,
                backgroundColor: MColors.primary,
                child: IconButton(
                  onPressed: () {},
                  icon: const Icon(Iconsax.send_1, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
