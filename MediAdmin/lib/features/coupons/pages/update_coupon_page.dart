import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/coupon_controller.dart';
import '../models/coupon_model.dart';

class UpdateCouponPage extends StatefulWidget {
  final VoidCallback onBack;
  final Map<String, dynamic> coupon;

  const UpdateCouponPage({
    super.key,
    required this.onBack,
    required this.coupon,
  });

  @override
  State<UpdateCouponPage> createState() => _UpdateCouponPageState();
}

class _UpdateCouponPageState extends State<UpdateCouponPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController couponCodeController;
  late final TextEditingController discountValueController;
  late final TextEditingController descriptionController;
  late final TextEditingController usageLimitController;
  late final TextEditingController startDateController;
  late final TextEditingController endDateController;
  late final TextEditingController perUserLimitController;
  late final TextEditingController minOrderAmountController;

  final List<String> _targetTypes = ['ALL', 'SPECIFIC', 'SEGMENT'];
  late String selectedTargetType;

  late bool isActive;

  @override
  void initState() {
    super.initState();
    couponCodeController = TextEditingController(text: widget.coupon['code']);
    discountValueController = TextEditingController(
      text: widget.coupon['discountValue'].toString(),
    );
    descriptionController = TextEditingController(
      text: widget.coupon['description'] ?? '',
    );
    usageLimitController = TextEditingController(text: '100'); // Default value
    startDateController = TextEditingController(
      text: widget.coupon['startDate'],
    );
    endDateController = TextEditingController(text: widget.coupon['endDate']);
    perUserLimitController = TextEditingController(
      text: (widget.coupon['perUserLimit'] ?? 1).toString(),
    );
    minOrderAmountController = TextEditingController(
      text: (widget.coupon['minOrderAmount'] ?? 0).toString(),
    );
    selectedTargetType = widget.coupon['targetType'] ?? 'ALL';
    isActive = widget.coupon['isActive'] ?? true;
  }

  @override
  void dispose() {
    couponCodeController.dispose();
    discountValueController.dispose();
    descriptionController.dispose();
    usageLimitController.dispose();
    startDateController.dispose();
    endDateController.dispose();
    perUserLimitController.dispose();
    minOrderAmountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(
    BuildContext context,
    TextEditingController controller,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        controller.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F7FA),
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back button
            InkWell(
              onTap: widget.onBack,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back, color: Color(0xFF4A5568)),
                  SizedBox(width: 8),
                  Text(
                    'Update Coupon',
                    style: TextStyle(
                      fontSize: 18,
                      color: Color(0xFF2D3748),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Form Card
            Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 800),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      const Row(
                        children: [
                          Icon(
                            Icons.local_offer,
                            color: Color(0xFF4299E1),
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Update Coupon Details',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Coupon Code
                      const Text(
                        'Coupon Code',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: couponCodeController,
                        decoration: InputDecoration(
                          hintText: 'Format: e.g. PERCENTAGE',
                          hintStyle: const TextStyle(color: Color(0xFFA0AEC0)),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter coupon code';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 24),

                      // Discount Value
                      const Text(
                        'Discount Value',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: discountValueController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Discount Value',
                          hintStyle: const TextStyle(color: Color(0xFFA0AEC0)),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter discount value';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 24),

                      // Description
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: descriptionController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Description',
                          hintStyle: const TextStyle(color: Color(0xFFA0AEC0)),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Usage Limit
                      const Text(
                        'Usage Limit',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: usageLimitController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Usage Limit',
                          hintStyle: const TextStyle(color: Color(0xFFA0AEC0)),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Start Date and End Date Row
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Start Date',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF2D3748),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: startDateController,
                                  readOnly: true,
                                  onTap: () =>
                                      _selectDate(context, startDateController),
                                  decoration: InputDecoration(
                                    hintText: 'Select Date',
                                    hintStyle: const TextStyle(
                                      color: Color(0xFFA0AEC0),
                                    ),
                                    suffixIcon: const Icon(
                                      Icons.calendar_today,
                                      color: Color(0xFF4299E1),
                                      size: 20,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'End Date',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF2D3748),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: endDateController,
                                  readOnly: true,
                                  onTap: () =>
                                      _selectDate(context, endDateController),
                                  decoration: InputDecoration(
                                    hintText: 'Select Date',
                                    hintStyle: const TextStyle(
                                      color: Color(0xFFA0AEC0),
                                    ),
                                    suffixIcon: const Icon(
                                      Icons.calendar_today,
                                      color: Color(0xFF4299E1),
                                      size: 20,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Min Order Amount
                      const Text(
                        'Min Order Amount (Rs)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: minOrderAmountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '0 = no minimum',
                          hintStyle: const TextStyle(color: Color(0xFFA0AEC0)),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Per-User Limit
                      const Text(
                        'Per-User Limit',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: perUserLimitController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Max times one user can use this coupon',
                          hintStyle: const TextStyle(color: Color(0xFFA0AEC0)),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Target Audience
                      const Text(
                        'Target Audience',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: selectedTargetType,
                        items: _targetTypes
                            .map(
                              (t) => DropdownMenuItem(value: t, child: Text(t)),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setState(() => selectedTargetType = v ?? 'ALL'),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Is Active Checkbox
                      CheckboxListTile(
                        value: isActive,
                        onChanged: (val) {
                          setState(() {
                            isActive = val ?? true;
                          });
                        },
                        title: const Text(
                          'Is Active',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),

                      const SizedBox(height: 32),

                      // Update Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              final controller = Get.find<CouponController>();
                              final dateFormat = DateFormat('d/M/yyyy');
                              final coupon = CouponModel(
                                id: widget.coupon['id'] ?? '',
                                code: couponCodeController.text.trim(),
                                discountValue:
                                    num.tryParse(
                                      discountValueController.text.trim(),
                                    ) ??
                                    0,
                                type: widget.coupon['type'] ?? 'FLAT',
                                description: descriptionController.text.trim(),
                                isActive: isActive,
                                startDate: startDateController.text.isNotEmpty
                                    ? dateFormat.parse(startDateController.text)
                                    : null,
                                endDate: endDateController.text.isNotEmpty
                                    ? dateFormat.parse(endDateController.text)
                                    : null,
                                usageLimit:
                                    int.tryParse(
                                      usageLimitController.text.trim(),
                                    ) ??
                                    100,
                                perUserLimit:
                                    int.tryParse(
                                      perUserLimitController.text.trim(),
                                    ) ??
                                    1,
                                minOrderAmount:
                                    (num.tryParse(
                                              minOrderAmountController.text
                                                  .trim(),
                                            ) ??
                                            0)
                                        .toDouble(),
                                targetType: selectedTargetType,
                              );
                              await controller.updateCoupon(coupon);
                              widget.onBack();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4299E1),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Update Coupon',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
