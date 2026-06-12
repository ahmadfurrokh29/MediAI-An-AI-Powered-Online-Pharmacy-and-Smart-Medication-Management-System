import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:med/common/widgets/appbar/appbar.dart';
import 'package:med/common/widgets/payment/payment_logos.dart';
import 'package:med/features/shop/controllers/payment_controller.dart';
import 'package:med/features/shop/models/payment_method_model.dart';
import 'package:med/utils/constants/colors.dart';
import 'package:med/utils/constants/sizes.dart';

// ── Main Screen ────────────────────────────────────────────────────────────

class BankAccountScreen extends StatelessWidget {
  const BankAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(PaymentController());
    return Scaffold(
      appBar: MAppBar(
        title: Text(
          'My Payment Methods',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        showBackArrow: true,
      ),
      body: Obx(() {
        if (ctrl.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(MSizes.defaultSpace),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (ctrl.paymentMethods.isEmpty)
                _EmptyState()
              else ...[
                Text(
                  'Saved Methods',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: MSizes.spaceBtwItems),
                ...ctrl.paymentMethods.map(
                  (method) => _PaymentMethodCard(method: method, ctrl: ctrl),
                ),
              ],
              const SizedBox(height: MSizes.spaceBtwSections),
              _AddMethodButton(ctrl: ctrl),
              const SizedBox(height: MSizes.spaceBtwItems),
              _SecurityNote(),
            ],
          ),
        );
      }),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: MSizes.spaceBtwSections),
        child: Column(
          children: [
            Icon(Iconsax.card, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: MSizes.spaceBtwItems),
            Text(
              'No payment methods saved',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Add a card, Easypaisa or JazzCash account\nto pay faster at checkout.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Saved method card ──────────────────────────────────────────────────────

class _PaymentMethodCard extends StatelessWidget {
  const _PaymentMethodCard({required this.method, required this.ctrl});
  final PaymentMethodModel method;
  final PaymentController ctrl;

  static Color _cardColor(PaymentMethodType t) {
    switch (t) {
      case PaymentMethodType.card:
        return const Color(0xFF1A1A2E);
      case PaymentMethodType.easypaisa:
        return const Color(0xFF00875A);
      case PaymentMethodType.jazzcash:
        return const Color(0xFFEE1C25);
    }
  }

  static Color _cardAccent(PaymentMethodType t) {
    switch (t) {
      case PaymentMethodType.card:
        return const Color(0xFF283593);
      case PaymentMethodType.easypaisa:
        return const Color(0xFF0D7A48);
      case PaymentMethodType.jazzcash:
        return const Color(0xFFB71C1C);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: MSizes.spaceBtwItems),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_cardColor(method.type), _cardAccent(method.type)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(MSizes.cardRadiusLg),
        boxShadow: [
          BoxShadow(
            color: _cardColor(method.type).withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(MSizes.defaultSpace),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: logo + label + remove button
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                PaymentLogo(type: method.typeString, size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    method.typeLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _confirmRemove(context),
                  icon: const Icon(
                    Iconsax.trash,
                    color: Colors.white70,
                    size: 20,
                  ),
                  tooltip: 'Remove',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: MSizes.spaceBtwItems),
            // Masked number / account
            Text(
              method.displayLabel,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                letterSpacing: 2,
                fontWeight: FontWeight.w500,
                fontFamily: 'monospace',
              ),
            ),
            if (method.accountTitle.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      method.accountTitle.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (method.expiryDate.isNotEmpty)
                    Text(
                      'Exp: ${method.expiryDate}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _confirmRemove(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Payment Method'),
        content: Text('Remove "${method.typeLabel} – ${method.displayLabel}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ctrl.removePaymentMethod(method.id);
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ── Add method button ──────────────────────────────────────────────────────

class _AddMethodButton extends StatelessWidget {
  const _AddMethodButton({required this.ctrl});
  final PaymentController ctrl;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _showAddMethodSheet(context, ctrl),
        icon: const Icon(Iconsax.add),
        label: const Text('Add Payment Method'),
      ),
    );
  }

  static void _showAddMethodSheet(
    BuildContext context,
    PaymentController ctrl,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddMethodSheet(ctrl: ctrl),
    );
  }
}

// ── Security note ──────────────────────────────────────────────────────────

class _SecurityNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Iconsax.shield_tick, size: 16, color: MColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Full card/account numbers are never stored. '
            'Only masked values are saved for display purposes.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: MColors.darkerGrey),
          ),
        ),
      ],
    );
  }
}

// ── Add Method bottom sheet ────────────────────────────────────────────────

class _AddMethodSheet extends StatefulWidget {
  const _AddMethodSheet({required this.ctrl});
  final PaymentController ctrl;

  @override
  State<_AddMethodSheet> createState() => _AddMethodSheetState();
}

class _AddMethodSheetState extends State<_AddMethodSheet> {
  PaymentMethodType _selectedType = PaymentMethodType.card;
  final _formKey = GlobalKey<FormState>();

  // Card fields
  final _cardNumberCtrl = TextEditingController();
  final _cardHolderCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();

  // Wallet fields (Easypaisa / JazzCash)
  final _accountNumberCtrl = TextEditingController();
  final _accountNameCtrl = TextEditingController();

  @override
  void dispose() {
    _cardNumberCtrl.dispose();
    _cardHolderCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    _accountNumberCtrl.dispose();
    _accountNameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCard = _selectedType == PaymentMethodType.card;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Add Payment Method',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // ── Type selector (3 equal tiles, no overflow) ────────────
              Text(
                'Select Type',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _TypeTile(
                      logo: const CardLogo(size: 36),
                      label: 'Card',
                      selected: _selectedType == PaymentMethodType.card,
                      activeColor: const Color(0xFF1A237E),
                      onTap: () => setState(
                        () => _selectedType = PaymentMethodType.card,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _TypeTile(
                      logo: const EasypaisaLogo(size: 36),
                      label: 'Easypaisa',
                      selected: _selectedType == PaymentMethodType.easypaisa,
                      activeColor: const Color(0xFF1BA260),
                      onTap: () => setState(
                        () => _selectedType = PaymentMethodType.easypaisa,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _TypeTile(
                      logo: const JazzCashLogo(size: 36),
                      label: 'JazzCash',
                      selected: _selectedType == PaymentMethodType.jazzcash,
                      activeColor: const Color(0xFFEE1C25),
                      onTap: () => setState(
                        () => _selectedType = PaymentMethodType.jazzcash,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: MSizes.spaceBtwSections),

              // ── Dynamic form fields ───────────────────────────────────
              if (isCard) ...[
                TextFormField(
                  controller: _cardNumberCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Card Number',
                    prefixIcon: Icon(Iconsax.card),
                    hintText: '1234 5678 9012 3456',
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 19,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    _CardNumberFormatter(),
                  ],
                  validator: (v) {
                    final digits = (v ?? '').replaceAll(' ', '');
                    return digits.length < 16
                        ? 'Enter a valid 16-digit card number'
                        : null;
                  },
                ),
                const SizedBox(height: MSizes.spaceBtwInputFields),
                TextFormField(
                  controller: _cardHolderCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Card Holder Name',
                    prefixIcon: Icon(Iconsax.user),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Enter card holder name'
                      : null,
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
                        inputFormatters: [_ExpiryFormatter()],
                        maxLength: 5,
                        validator: (v) => (v == null || v.trim().length < 5)
                            ? 'Enter expiry date'
                            : null,
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
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (v) => (v == null || v.trim().length < 3)
                            ? 'Enter CVV'
                            : null,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                TextFormField(
                  controller: _accountNumberCtrl,
                  decoration: InputDecoration(
                    labelText: _selectedType == PaymentMethodType.easypaisa
                        ? 'Easypaisa Number'
                        : 'JazzCash Number',
                    prefixIcon: const Icon(Icons.phone_android),
                    hintText: '03XX XXXX XXX',
                  ),
                  keyboardType: TextInputType.phone,
                  maxLength: 13,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) {
                    final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
                    return digits.length < 11
                        ? 'Enter a valid 11-digit number'
                        : null;
                  },
                ),
                const SizedBox(height: MSizes.spaceBtwInputFields),
                TextFormField(
                  controller: _accountNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Account Name',
                    prefixIcon: Icon(Iconsax.user),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Enter account name'
                      : null,
                ),
              ],

              const SizedBox(height: MSizes.spaceBtwSections),

              // ── Save button ───────────────────────────────────────────
              Obx(() {
                final saving = widget.ctrl.isLoading.value;
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: saving ? null : _save,
                    child: saving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Save'),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    PaymentMethodModel method;
    final now = DateTime.now();

    if (_selectedType == PaymentMethodType.card) {
      final rawNumber = _cardNumberCtrl.text.replaceAll(' ', '');
      method = PaymentMethodModel(
        id: '',
        type: PaymentMethodType.card,
        displayLabel: PaymentMethodModel.maskCardNumber(rawNumber),
        accountTitle: _cardHolderCtrl.text.trim(),
        expiryDate: _expiryCtrl.text.trim(),
        createdAt: now,
      );
    } else {
      final rawNumber = _accountNumberCtrl.text.replaceAll(RegExp(r'\D'), '');
      method = PaymentMethodModel(
        id: '',
        type: _selectedType,
        displayLabel: PaymentMethodModel.maskAccountNumber(rawNumber),
        accountTitle: _accountNameCtrl.text.trim(),
        createdAt: now,
      );
    }

    await widget.ctrl.addPaymentMethod(method);
    if (mounted) Navigator.pop(context);
  }
}

// ── Type tile (replaces old TypeChip — uses logo widget, fills its Expanded slot) ──

class _TypeTile extends StatelessWidget {
  const _TypeTile({
    required this.logo,
    required this.label,
    required this.selected,
    required this.activeColor,
    required this.onTap,
  });

  final Widget logo;
  final String label;
  final bool selected;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: selected
              ? activeColor.withValues(alpha: 0.08)
              : Colors.grey.shade100,
          border: Border.all(
            color: selected ? activeColor : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(MSizes.cardRadiusMd),
        ),
        // overflow: hidden prevents any child from escaping the border
        child: ClipRect(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Hard-constrain the logo so it can never overflow
              SizedBox(width: 40, height: 40, child: Center(child: logo)),
              const SizedBox(height: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: selected ? activeColor : Colors.grey.shade600,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Input formatters ───────────────────────────────────────────────────────

/// Formats card number as "XXXX XXXX XXXX XXXX"
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue old,
    TextEditingValue updated,
  ) {
    final text = updated.text
        .replaceAll(' ', '')
        .substring(
          0,
          updated.text.replaceAll(' ', '').length > 16
              ? 16
              : updated.text.replaceAll(' ', '').length,
        );
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(text[i]);
    }
    final str = buffer.toString();
    return TextEditingValue(
      text: str,
      selection: TextSelection.collapsed(offset: str.length),
    );
  }
}

/// Formats expiry as "MM/YY"
class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue old,
    TextEditingValue updated,
  ) {
    var text = updated.text.replaceAll('/', '');
    if (text.length > 4) text = text.substring(0, 4);
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i == 2) buffer.write('/');
      buffer.write(text[i]);
    }
    final str = buffer.toString();
    return TextEditingValue(
      text: str,
      selection: TextSelection.collapsed(offset: str.length),
    );
  }
}
