import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/coupon_controller.dart';
import '../models/coupon_model.dart';

class CouponsPage extends StatefulWidget {
  final VoidCallback onCreatePressed;
  final Function(Map<String, dynamic>) onViewPressed;

  const CouponsPage({
    super.key,
    required this.onCreatePressed,
    required this.onViewPressed,
  });

  @override
  State<CouponsPage> createState() => _CouponsPageState();
}

class _CouponsPageState extends State<CouponsPage> {
  final TextEditingController searchController = TextEditingController();
  late final CouponController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(CouponController());
    controller.initialize();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  Map<String, dynamic> _couponToMap(CouponModel c) {
    return {
      'id': c.id,
      'code': c.code,
      'discountValue': c.discountValue,
      'type': c.type,
      'description': c.description,
      'isActive': c.isActive,
      'startDate': _formatDate(c.startDate),
      'endDate': _formatDate(c.endDate),
      'usageLimit': c.usageLimit,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  onPressed: widget.onCreatePressed,
                  child: const Text("Create New Coupon", style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(width: 20),
                Obx(() => Text(
                  'Total Coupons: ${controller.coupons.length}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                )),
              ],
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => controller.fetchCoupons(),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        TextField(
          controller: searchController,
          onChanged: (value) => controller.updateSearchQuery(value),
          decoration: InputDecoration(
            hintText: "Search coupons...",
            filled: true,
            fillColor: Colors.white,
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
            ),
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              final filtered = controller.filteredCoupons;
              if (filtered.isEmpty) {
                return const Center(child: Text('No coupons found.'));
              }
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: DataTable(
                    columnSpacing: 50,
                    horizontalMargin: 20,
                    headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
                    columns: const [
                      DataColumn(label: Text("Coupon Code")),
                      DataColumn(label: Text("Discount")),
                      DataColumn(label: Text("Type")),
                      DataColumn(label: Text("Description")),
                      DataColumn(label: Text("Status")),
                      DataColumn(label: Text("Start Date")),
                      DataColumn(label: Text("End Date")),
                      DataColumn(label: Text("Action")),
                    ],
                    rows: filtered.map((coupon) {
                      return DataRow(
                        cells: [
                          DataCell(Text(coupon.code, style: const TextStyle(fontWeight: FontWeight.w500))),
                          DataCell(Text(coupon.discountValue.toString())),
                          DataCell(Chip(
                            label: Text(coupon.type, style: const TextStyle(fontSize: 12)),
                            backgroundColor: coupon.type == 'FLAT' ? Colors.green.shade50 : Colors.blue.shade50,
                          )),
                          DataCell(SizedBox(
                            width: 150,
                            child: Text(
                              coupon.description.isEmpty ? '—' : coupon.description,
                              overflow: TextOverflow.ellipsis,
                            ),
                          )),
                          DataCell(Row(
                            children: [
                              Container(
                                width: 8, height: 8,
                                decoration: BoxDecoration(
                                  color: coupon.isActive ? Colors.green : Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                coupon.isActive ? "Active" : "Inactive",
                                style: TextStyle(
                                  color: coupon.isActive ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )),
                          DataCell(Text(_formatDate(coupon.startDate))),
                          DataCell(Text(_formatDate(coupon.endDate))),
                          DataCell(Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Color(0xFF4299E1)),
                                tooltip: 'Edit Coupon',
                                onPressed: () => widget.onViewPressed(_couponToMap(coupon)),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _showDeleteConfirmation(context, coupon),
                              ),
                            ],
                          )),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 10),
        Obx(() => Text(
          "Showing ${controller.filteredCoupons.length} of ${controller.coupons.length} Coupons",
          style: const TextStyle(color: Colors.grey, fontSize: 13),
        )),
      ],
    );
  }

  void _showDeleteConfirmation(BuildContext context, CouponModel coupon) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Coupon'),
        content: Text('Are you sure you want to delete coupon "${coupon.code}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.deleteCoupon(coupon.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
