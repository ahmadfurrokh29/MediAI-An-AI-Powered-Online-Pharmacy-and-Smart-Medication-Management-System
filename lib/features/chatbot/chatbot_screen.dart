import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:med/common/widgets/appbar/appbar.dart';
import 'package:med/utils/constants/colors.dart';
import 'package:med/utils/constants/sizes.dart';
import 'package:med/utils/helpers/helper_functions.dart';
import 'controllers/chatbot_controller.dart';
import 'models/chat_message.dart';

class ChatbotScreen extends StatelessWidget {
  const ChatbotScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ChatbotController());
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
            child: Obx(() {
              if (controller.messages.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Iconsax.message_question,
                        size: 56,
                        color: MColors.primary.withOpacity(0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Ask me anything about medicines,\ndosage, or drug interactions.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              color: dark ? Colors.white54 : Colors.black45,
                            ),
                      ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                controller: controller.scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: MSizes.defaultSpace,
                  vertical: MSizes.sm,
                ),
                itemCount: controller.messages.length,
                itemBuilder: (_, index) {
                  final msg = controller.messages[index];
                  return _ChatBubble(message: msg, dark: dark);
                },
              );
            }),
          ),

          /// Loading indicator
          Obx(() => controller.isLoading.value
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const SizedBox(width: MSizes.defaultSpace),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: dark ? MColors.dark : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _TypingDot(delay: 0),
                            _TypingDot(delay: 150),
                            _TypingDot(delay: 300),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink()),
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
                  controller: controller.textController,
                  textInputAction: TextInputAction.send,
                  onFieldSubmitted: (_) => controller.sendMessage(),
                  decoration: InputDecoration(
                    hintText: 'Ask about a medicine...',
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
              Obx(() => CircleAvatar(
                    radius: 24,
                    backgroundColor: controller.isLoading.value
                        ? Colors.grey
                        : MColors.primary,
                    child: IconButton(
                      onPressed: controller.isLoading.value
                          ? null
                          : controller.sendMessage,
                      icon: const Icon(Iconsax.send_1, color: Colors.white),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool dark;

  const _ChatBubble({required this.message, required this.dark});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? MColors.primary
              : (dark ? MColors.dark : Colors.grey.shade200),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
        ),
        child: Text(
          message.text,
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: isUser
                    ? Colors.white
                    : (dark ? Colors.white : Colors.black87),
              ),
        ),
      ),
    );
  }
}

class _TypingDot extends StatefulWidget {
  final int delay;
  const _TypingDot({required this.delay});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
    _anim = Tween<double>(begin: 0, end: -5).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _anim.value),
        child: Container(
          width: 7,
          height: 7,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: MColors.primary,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
