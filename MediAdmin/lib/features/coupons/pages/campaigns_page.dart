import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/coupon_controller.dart';
import '../models/campaign_model.dart';
import '../models/coupon_model.dart';

/// Admin Campaign Management Page
/// Displays all campaigns in a table and allows sending new campaigns.
class CampaignsPage extends StatefulWidget {
  final VoidCallback? onCreatePressed;

  const CampaignsPage({super.key, this.onCreatePressed});

  @override
  State<CampaignsPage> createState() => _CampaignsPageState();
}

class _CampaignsPageState extends State<CampaignsPage> {
  late final CouponController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<CouponController>()
        ? Get.find<CouponController>()
        : Get.put(CouponController())..initialize();
    controller.fetchCampaigns();
    controller.fetchCoupons();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F7FA),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Campaign Management',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh',
                    onPressed: () {
                      controller.fetchCampaigns();
                      controller.fetchCoupons();
                    },
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed:
                        widget.onCreatePressed ??
                        () => _showCreateDialog(context, controller),
                    icon: const Icon(Icons.add),
                    label: const Text('New Campaign'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4299E1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Campaigns Table ─────────────────────────────────────────────────
          Expanded(
            child: Obx(() {
              if (controller.campaigns.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.campaign_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No campaigns yet.\nCreate one to start engaging users.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[500], fontSize: 16),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => _showCreateDialog(context, controller),
                        icon: const Icon(Icons.add),
                        label: const Text('Create First Campaign'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4299E1),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: SingleChildScrollView(
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(
                      const Color(0xFFF7FAFC),
                    ),
                    columnSpacing: 20,
                    columns: const [
                      DataColumn(
                        label: Text(
                          'Campaign Name',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Coupon Code',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Target',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Status',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Sent / Accepted / Redeemed',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Scheduled',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Actions',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                    rows: controller.campaigns.map((campaign) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              campaign.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEBF8FF),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                campaign.couponCode,
                                style: const TextStyle(
                                  color: Color(0xFF2B6CB0),
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          DataCell(Text(campaign.targetType)),
                          DataCell(_StatusChip(status: campaign.status)),
                          DataCell(
                            Text(
                              '${campaign.totalSent} / ${campaign.totalAccepted} / ${campaign.totalRedeemed}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          DataCell(
                            Text(
                              campaign.scheduledAt != null
                                  ? DateFormat(
                                      'MMM d, yyyy',
                                    ).format(campaign.scheduledAt!)
                                  : '—',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (campaign.status == 'DRAFT' ||
                                    campaign.status == 'SCHEDULED')
                                  Tooltip(
                                    message: 'Send Campaign Now',
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.send,
                                        color: Color(0xFF4299E1),
                                        size: 20,
                                      ),
                                      onPressed: () => _confirmSend(
                                        context,
                                        controller,
                                        campaign,
                                      ),
                                    ),
                                  ),
                                Tooltip(
                                  message: 'View Details',
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.info_outline,
                                      color: Color(0xFF718096),
                                      size: 20,
                                    ),
                                    onPressed: () =>
                                        _showDetailsDialog(context, campaign),
                                  ),
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
        ],
      ),
    );
  }

  // ── Send Confirmation ────────────────────────────────────────────────────────
  void _confirmSend(
    BuildContext context,
    CouponController controller,
    CampaignModel campaign,
  ) {
    // Find the coupon to show discount detail
    final coupon = controller.coupons.firstWhereOrNull(
      (c) => c.id == campaign.couponId,
    );
    final discountLabel = coupon == null
        ? '—'
        : coupon.type == 'FLAT'
        ? 'Rs ${coupon.discountValue.toStringAsFixed(0)} flat off'
        : '${coupon.discountValue.toStringAsFixed(0)}% off';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.send, color: Color(0xFF4299E1)),
            SizedBox(width: 8),
            Text('Confirm Send'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Send campaign "${campaign.name}" to all targeted users?'),
            const SizedBox(height: 12),
            _InfoRow(label: 'Coupon Code', value: campaign.couponCode),
            _InfoRow(label: 'Discount', value: discountLabel),
            _InfoRow(label: 'Target', value: campaign.targetType),
            _InfoRow(
              label: 'Users targeted',
              value: campaign.totalTargeted > 0
                  ? campaign.totalTargeted.toString()
                  : 'All users',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              await controller.sendCampaign(campaign);
            },
            icon: const Icon(Icons.send, size: 16),
            label: const Text('Send Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4299E1),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ── Create Campaign Dialog ────────────────────────────────────────────────────
  void _showCreateDialog(BuildContext context, CouponController controller) {
    final nameCtrl = TextEditingController();
    String? selectedCouponId;
    String targetType = 'ALL';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Row(
            children: [
              Icon(Icons.campaign, color: Color(0xFF4299E1)),
              SizedBox(width: 8),
              Text('New Campaign'),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Campaign Name
                const Text(
                  'Campaign Name',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    hintText: 'e.g. Summer Sale 2025',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Coupon Selection
                const Text(
                  'Coupon',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 6),
                Obx(() {
                  final coupons = controller.coupons
                      .where((c) => c.isActive)
                      .toList();
                  return DropdownButtonFormField<String>(
                    // ignore: deprecated_member_use
                    value: selectedCouponId,
                    hint: const Text('Select active coupon'),
                    items: coupons.map((CouponModel c) {
                      final discLabel = c.type == 'FLAT'
                          ? 'Rs ${c.discountValue.toStringAsFixed(0)} off'
                          : '${c.discountValue.toStringAsFixed(0)}% off';
                      return DropdownMenuItem<String>(
                        value: c.id,
                        child: Text('${c.code}  ·  $discLabel'),
                      );
                    }).toList(),
                    onChanged: (v) => setS(() => selectedCouponId = v),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 16),

                // Target Audience
                const Text(
                  'Target Audience',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: targetType,
                  items: ['ALL', 'SPECIFIC', 'SEGMENT']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setS(() => targetType = v ?? 'ALL'),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                final coupon = controller.coupons.firstWhereOrNull(
                  (c) => c.id == selectedCouponId,
                );
                if (coupon == null) {
                  Get.snackbar(
                    'Error',
                    'Please select a coupon.',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                  return;
                }
                Navigator.pop(ctx);
                final campaign = CampaignModel(
                  id: '',
                  name: nameCtrl.text.trim(),
                  couponId: coupon.id,
                  couponCode: coupon.code,
                  status: 'DRAFT',
                  targetType: targetType,
                  targetUserIds: const [],
                  targetSegment: '',
                  totalTargeted: 0,
                  totalSent: 0,
                  totalAccepted: 0,
                  totalDeclined: 0,
                  totalRedeemed: 0,
                  createdAt: DateTime.now(),
                );
                await controller.createCampaign(campaign);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4299E1),
                foregroundColor: Colors.white,
              ),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Details Dialog ─────────────────────────────────────────────────────────
  void _showDetailsDialog(BuildContext context, CampaignModel campaign) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(campaign.name),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _InfoRow(label: 'Coupon Code', value: campaign.couponCode),
              _InfoRow(label: 'Status', value: campaign.status),
              _InfoRow(label: 'Target Type', value: campaign.targetType),
              _InfoRow(
                label: 'Total Targeted',
                value: campaign.totalTargeted.toString(),
              ),
              _InfoRow(
                label: 'Total Sent',
                value: campaign.totalSent.toString(),
              ),
              _InfoRow(
                label: 'Total Accepted',
                value: campaign.totalAccepted.toString(),
              ),
              _InfoRow(
                label: 'Total Declined',
                value: campaign.totalDeclined.toString(),
              ),
              _InfoRow(
                label: 'Total Redeemed',
                value: campaign.totalRedeemed.toString(),
              ),
              if (campaign.scheduledAt != null)
                _InfoRow(
                  label: 'Scheduled At',
                  value: DateFormat(
                    'MMM d, yyyy HH:mm',
                  ).format(campaign.scheduledAt!),
                ),
              if (campaign.sentAt != null)
                _InfoRow(
                  label: 'Sent At',
                  value: DateFormat(
                    'MMM d, yyyy HH:mm',
                  ).format(campaign.sentAt!),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

// ── Reusable Widgets ──────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  Color get _color => switch (status) {
    'ACTIVE' => const Color(0xFF38A169),
    'COMPLETED' => const Color(0xFF718096),
    'SCHEDULED' => const Color(0xFFD69E2E),
    'CANCELLED' => const Color(0xFFE53E3E),
    _ => const Color(0xFF4299E1), // DRAFT
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withAlpha(80)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: _color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF718096), fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
