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
    // Controller is registered in AdminLayout.initState — just find it.
    controller = Get.find<CouponController>();
    // Refresh data in case it's stale
    controller.fetchCoupons();
    controller.fetchAnalytics();
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
      'usageCount': c.usageCount,
      'perUserLimit': c.perUserLimit,
      'minOrderAmount': c.minOrderAmount,
      'targetType': c.targetType,
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: widget.onCreatePressed,
                  child: const Text(
                    "Create New Coupon",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 20),
                Obx(
                  () => Text(
                    'Total Coupons: ${controller.coupons.length}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
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

        // ── Analytics Summary Bar ────────────────────────────────────────────
        Obx(
          () => Row(
            children: [
              _StatCard(
                label: 'Total Coupons',
                value: controller.coupons.length.toString(),
                color: Colors.blue,
                icon: Icons.local_offer,
              ),
              const SizedBox(width: 12),
              _StatCard(
                label: 'Active',
                value: controller.coupons
                    .where((c) => c.isEffectivelyActive)
                    .length
                    .toString(),
                color: Colors.green,
                icon: Icons.check_circle,
              ),
              const SizedBox(width: 12),
              _StatCard(
                label: 'Total Redeemed',
                value: controller.totalRedemptions.value.toString(),
                color: Colors.purple,
                icon: Icons.redeem,
              ),
              const SizedBox(width: 12),
              _StatCard(
                label: 'Discount Given',
                value:
                    'Rs ${controller.totalDiscountGiven.value.toStringAsFixed(0)}',
                color: Colors.orange,
                icon: Icons.savings,
              ),
              const SizedBox(width: 12),
              _StatCard(
                label: 'Acceptance Rate',
                value: '${controller.acceptanceRate.value.toStringAsFixed(1)}%',
                color: Colors.teal,
                icon: Icons.thumb_up,
              ),
            ],
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
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 8),
              ],
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
                    headingRowColor: WidgetStateProperty.all(
                      Colors.grey.shade100,
                    ),
                    columns: const [
                      DataColumn(label: Text("Coupon Code")),
                      DataColumn(label: Text("Discount")),
                      DataColumn(label: Text("Type")),
                      DataColumn(label: Text("Description")),
                      DataColumn(label: Text("Status")),
                      DataColumn(label: Text("Used / Limit")),
                      DataColumn(label: Text("Per User")),
                      DataColumn(label: Text("Start Date")),
                      DataColumn(label: Text("End Date")),
                      DataColumn(label: Text("Action")),
                    ],
                    rows: filtered.map((coupon) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              coupon.code,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              coupon.type == 'FLAT'
                                  ? 'Rs ${coupon.discountValue.toStringAsFixed(0)}'
                                  : '${coupon.discountValue.toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: coupon.type == 'FLAT'
                                    ? Colors.green.shade700
                                    : Colors.blue.shade700,
                              ),
                            ),
                          ),
                          DataCell(
                            Chip(
                              label: Text(
                                coupon.type,
                                style: const TextStyle(fontSize: 12),
                              ),
                              backgroundColor: coupon.type == 'FLAT'
                                  ? Colors.green.shade50
                                  : Colors.blue.shade50,
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 150,
                              child: Text(
                                coupon.description.isEmpty
                                    ? '—'
                                    : coupon.description,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          DataCell(
                            GestureDetector(
                              onTap: () => controller.toggleActive(
                                coupon.id,
                                !coupon.isActive,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: coupon.isEffectivelyActive
                                          ? Colors.green
                                          : Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    coupon.isEffectivelyActive
                                        ? "Active"
                                        : "Inactive",
                                    style: TextStyle(
                                      color: coupon.isEffectivelyActive
                                          ? Colors.green
                                          : Colors.red,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.swap_horiz,
                                    size: 14,
                                    color: Colors.grey.shade500,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // ── Usage Count / Limit column ────────────────────
                          DataCell(
                            Row(
                              children: [
                                Text(
                                  '${coupon.usageCount} / ${coupon.usageLimit}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color:
                                        coupon.usageCount >= coupon.usageLimit
                                        ? Colors.red
                                        : Colors.black87,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 60,
                                  child: LinearProgressIndicator(
                                    value: coupon.usageLimit > 0
                                        ? (coupon.usageCount /
                                                  coupon.usageLimit)
                                              .clamp(0.0, 1.0)
                                        : 0.0,
                                    backgroundColor: Colors.grey.shade200,
                                    color:
                                        coupon.usageCount >= coupon.usageLimit
                                        ? Colors.red
                                        : Colors.green,
                                    minHeight: 6,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // ── Per-User Limit column ─────────────────────────
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.indigo.shade50,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.indigo.shade100,
                                ),
                              ),
                              child: Text(
                                coupon.perUserLimit <= 0
                                    ? '∞ unlimited'
                                    : '${coupon.perUserLimit}x per user',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.indigo.shade700,
                                ),
                              ),
                            ),
                          ),
                          DataCell(Text(_formatDate(coupon.startDate))),
                          DataCell(Text(_formatDate(coupon.endDate))),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Color(0xFF4299E1),
                                  ),
                                  tooltip: 'Edit Coupon',
                                  onPressed: () => widget.onViewPressed(
                                    _couponToMap(coupon),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () =>
                                      _showDeleteConfirmation(context, coupon),
                                ),
                              ],
                            ),
                          ),
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
        Obx(
          () => Text(
            "Showing ${controller.filteredCoupons.length} of ${controller.coupons.length} Coupons",
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmation(BuildContext context, CouponModel coupon) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Coupon'),
        content: Text(
          'Are you sure you want to delete coupon "${coupon.code}"?',
        ),
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

// ── Reusable stat card widget ──────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: color,
                ),
              ),
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
