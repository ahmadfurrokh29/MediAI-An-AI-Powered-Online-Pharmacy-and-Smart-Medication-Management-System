import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:med/common/widgets/appbar/appbar.dart';
import 'package:med/features/shop/controllers/payment_controller.dart';
import 'package:med/utils/constants/colors.dart';
import 'package:med/utils/constants/sizes.dart';

class BankAccountScreen extends StatelessWidget {
  const BankAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(PaymentController());
    return Scaffold(
      appBar: MAppBar(
        title: Text('My Bank / Card',
            style: Theme.of(context).textTheme.headlineSmall),
        showBackArrow: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MSizes.defaultSpace),
        child: Obx(() {
          if (ctrl.hasCard.value) {
            return _SavedCardView(ctrl: ctrl);
          }
          return _AddCardForm(ctrl: ctrl);
        }),
      ),
    );
  }
}

class _SavedCardView extends StatelessWidget {
  const _SavedCardView({required this.ctrl});
  final PaymentController ctrl;

  @override
  Widget build(BuildContext context) {
    final last4 = ctrl.cardNumber.value.length >= 4
        ? ctrl.cardNumber.value.substring(ctrl.cardNumber.value.length - 4)
        : ctrl.cardNumber.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Card preview
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(MSizes.defaultSpace),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.credit_card, color: Colors.white70, size: 36),
              const SizedBox(height: MSizes.spaceBtwSections),
              Text(
                '**** **** **** $last4',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: MSizes.spaceBtwItems),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    ctrl.cardHolder.value.toUpperCase(),
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  Text(
                    ctrl.expiryDate.value,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: MSizes.spaceBtwSections),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              ctrl.removeCard();
              Get.snackbar('Card Removed', 'Your card has been removed.',
                  snackPosition: SnackPosition.BOTTOM);
            },
            icon: const Icon(Iconsax.trash, size: 18),
            label: const Text('Remove Card'),
          ),
        ),
      ],
    );
  }
}

class _AddCardForm extends StatefulWidget {
  const _AddCardForm({required this.ctrl});
  final PaymentController ctrl;

  @override
  State<_AddCardForm> createState() => _AddCardFormState();
}

class _AddCardFormState extends State<_AddCardForm> {
  final _formKey = GlobalKey<FormState>();
  final _numberCtrl = TextEditingController();
  final _holderCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();

  @override
  void dispose() {
    _numberCtrl.dispose();
    _holderCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add Card Details',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: MSizes.spaceBtwSections),
          TextFormField(
            controller: _numberCtrl,
            decoration: const InputDecoration(
              labelText: 'Card Number',
              prefixIcon: Icon(Iconsax.card),
            ),
            keyboardType: TextInputType.number,
            maxLength: 19,
            validator: (v) =>
                (v == null || v.replaceAll(' ', '').length < 16) ? 'Enter a valid card number' : null,
          ),
          const SizedBox(height: MSizes.spaceBtwInputFields),
          TextFormField(
            controller: _holderCtrl,
            decoration: const InputDecoration(
              labelText: 'Card Holder Name',
              prefixIcon: Icon(Iconsax.user),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Enter card holder name' : null,
          ),
          const SizedBox(height: MSizes.spaceBtwInputFields),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _expiryCtrl,
                  decoration: const InputDecoration(
                    labelText: 'MM/YY',
                    prefixIcon: Icon(Iconsax.calendar),
                  ),
                  keyboardType: TextInputType.datetime,
                  validator: (v) =>
                      (v == null || v.trim().length < 4) ? 'Enter expiry' : null,
                ),
              ),
              const SizedBox(width: MSizes.spaceBtwInputFields),
              Expanded(
                child: TextFormField(
                  controller: _cvvCtrl,
                  decoration: const InputDecoration(
                    labelText: 'CVV',
                    prefixIcon: Icon(Iconsax.security_safe),
                  ),
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4,
                  validator: (v) =>
                      (v == null || v.trim().length < 3) ? 'Enter CVV' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: MSizes.spaceBtwSections),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  widget.ctrl.saveCard(
                    number: _numberCtrl.text.trim(),
                    holder: _holderCtrl.text.trim(),
                    expiry: _expiryCtrl.text.trim(),
                    cvvCode: _cvvCtrl.text.trim(),
                  );
                  Get.snackbar('Card Saved', 'Your card details have been saved securely.',
                      snackPosition: SnackPosition.BOTTOM);
                }
              },
              child: const Text('Save Card'),
            ),
          ),
          const SizedBox(height: MSizes.spaceBtwItems),
          Row(
            children: [
              const Icon(Iconsax.shield_tick, size: 16, color: MColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Your card details are stored securely and encrypted.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
