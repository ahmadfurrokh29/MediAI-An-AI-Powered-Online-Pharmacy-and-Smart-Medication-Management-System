import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/prescription_request_controller.dart';
import '../models/prescription_request_model.dart';
import '../../orders/controllers/order_controller.dart';
import '../../orders/models/order_model.dart';

const List<String> _kResponseOptions = [
  'Medicine is available — we have added it to your order.',
  'Medicine is not available in our store currently.',
  'Your prescription is not clear. Please send a clearer image.',
  'We need more details about the medicine. Please contact us.',
  'Medicine is out of stock. We will notify you when available.',
];

class PrescriptionRequestDetailPage extends StatefulWidget {
  final PrescriptionRequestModel request;
  final VoidCallback onBack;

  const PrescriptionRequestDetailPage({
    super.key,
    required this.request,
    required this.onBack,
  });

  @override
  State<PrescriptionRequestDetailPage> createState() =>
      _PrescriptionRequestDetailPageState();
}

class _PrescriptionRequestDetailPageState
    extends State<PrescriptionRequestDetailPage> {
  late PrescriptionRequestModel _req;
  String? _selectedResponse;
  final _customResponseCtrl = TextEditingController();
  bool _useCustom = false;
  bool _isSending = false;

  // For "Add product to order" mini-flow
  final _searchCtrl = TextEditingController();
  bool _searching = false;
  List<Map<String, dynamic>> _searchResults = [];
  Map<String, dynamic>? _selectedProduct;
  int _addQty = 1;

  final _db = FirebaseFirestore.instance;

  PrescriptionRequestModel get req {
    final ctrl = PrescriptionRequestController.instance;
    return ctrl.requests.firstWhereOrNull((r) => r.id == _req.id) ?? _req;
  }

  @override
  void initState() {
    super.initState();
    _req = widget.request;
  }

  @override
  void dispose() {
    _customResponseCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  String get _responseText {
    if (_useCustom) return _customResponseCtrl.text.trim();
    return _selectedResponse ?? '';
  }

  Future<void> _sendResponse() async {
    if (_responseText.isEmpty) {
      Get.snackbar('Missing Message', 'Please select or type a response.',
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }
    setState(() => _isSending = true);
    await PrescriptionRequestController.instance
        .respondToRequest(req, _responseText);
    if (mounted) setState(() => _isSending = false);
  }

  // ── Product search for "Add to order" ──────────────────────────────────

  Future<void> _searchProducts(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _searching = true);
    try {
      final snap = await _db.collection('Products').get();
      final q = query.toLowerCase().trim();
      final results = snap.docs
          .where((doc) {
            final data = doc.data();
            final name =
                (data['Name'] ?? data['name'] ?? '').toString().toLowerCase();
            return name.contains(q);
          })
          .map((doc) {
            final data = doc.data();
            final salePrice = (data['SalePrice'] as num? ?? 0).toDouble();
            final regularPrice =
                (data['Price'] as num? ?? data['price'] as num? ?? 0)
                    .toDouble();
            final price = salePrice > 0 ? salePrice : regularPrice;
            return {
              'id': doc.id,
              'name': (data['Name'] ?? data['name'] ?? '').toString(),
              'price': price,
              'isPrescribed':
                  data['IsPrescribed'] ?? data['isPrescribed'] ?? false,
            };
          })
          .toList();
      if (mounted) setState(() => _searchResults = results);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _showAddToOrderDialog() {
    _searchCtrl.clear();
    _searchResults = [];
    _selectedProduct = null;
    _addQty = 1;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setS) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: 480, maxHeight: 520),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('Add Item to Order (if available)',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx2),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Search for the correct product and create a new order for the customer.',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Search product...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (v) async {
                      await _searchProducts(v);
                      setS(() {});
                    },
                  ),
                  const SizedBox(height: 8),
                  if (_searching)
                    const Center(
                        child: Padding(
                      padding: EdgeInsets.all(12),
                      child:
                          CircularProgressIndicator(strokeWidth: 2),
                    )),
                  Expanded(
                    child: _searchResults.isEmpty && !_searching
                        ? Center(
                            child: Text(
                              _searchCtrl.text.isEmpty
                                  ? 'Type to search products'
                                  : 'No products found',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _searchResults.length,
                            itemBuilder: (_, i) {
                              final p = _searchResults[i];
                              final isSel =
                                  _selectedProduct?['id'] == p['id'];
                              return ListTile(
                                dense: true,
                                selected: isSel,
                                selectedTileColor:
                                    Colors.green.withOpacity(0.08),
                                title: Text(p['name'] as String),
                                subtitle: Text(
                                    'Rs ${(p['price'] as double).toStringAsFixed(0)}'),
                                trailing: isSel
                                    ? const Icon(Icons.check_circle,
                                        color: Colors.green)
                                    : null,
                                onTap: () =>
                                    setS(() => _selectedProduct = p),
                              );
                            },
                          ),
                  ),
                  if (_selectedProduct != null) ...[
                    const Divider(),
                    Row(
                      children: [
                        Expanded(
                            child: Text(
                          _selectedProduct!['name'] as String,
                          style:
                              const TextStyle(fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        )),
                        const SizedBox(width: 8),
                        const Text('Qty: '),
                        IconButton(
                          icon: const Icon(Icons.remove, size: 16),
                          onPressed: _addQty > 1
                              ? () => setS(() => _addQty--)
                              : null,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 8),
                          child: Text('$_addQty',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, size: 16),
                          onPressed: () => setS(() => _addQty++),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx2),
                          child: const Text('Cancel')),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _selectedProduct == null
                            ? null
                            : () async {
                                Navigator.pop(ctx2);
                                await _createOrderForCustomer();
                              },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white),
                        child: const Text('Create Order'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _createOrderForCustomer() async {
    if (_selectedProduct == null) return;
    try {
      final p = _selectedProduct!;
      final price = (p['price'] as double);
      final item = OrderItemModel(
        productId: p['id'] as String,
        productName: p['name'] as String,
        price: price,
        quantity: _addQty,
        isPrescribed: p['isPrescribed'] as bool? ?? false,
      );
      final total = price * _addQty;

      await _db.collection('Orders').add({
        'customerId': req.customerId,
        'customerName': req.customerName,
        'customerEmail': req.customerEmail,
        'orderStatus': 'Pending',
        'paymentStatus': 'Unpaid',
        'totalAmount': total,
        'subtotal': total,
        'couponCode': '',
        'couponDiscount': 0,
        'shippingFee': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'shippingAddress': {},
        'items': [item.toMap()],
        'prescriptions': [req.prescriptionUrl],
        'prescriptionRequestId': req.id,
      });

      // Notify the customer
      final notifMsg =
          'Good news! We found "${req.medicineName}" and created an order for you. Please review it in the Orders section.';
      await PrescriptionRequestController.instance
          .respondToRequest(req, notifMsg);

      if (Get.isRegistered<OrderController>()) {
        OrderController.instance.fetchOrders();
      }

      Get.snackbar(
          'Order Created',
          'Order placed for ${req.customerName} — "${p['name']}"',
          backgroundColor: Colors.green,
          colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error', 'Failed to create order: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────

  /// Renders a prescription image from either an HTTPS URL or a data-URI
  /// (data:image/jpeg;base64,...) that is used as fallback when Storage fails.
  Widget _buildPrescriptionImage(String src) {
    if (src.startsWith('data:image')) {
      // data-URI fallback: decode base64 portion
      try {
        final commaIdx = src.indexOf(',');
        final b64 = commaIdx != -1 ? src.substring(commaIdx + 1) : src;
        final Uint8List bytes = base64Decode(b64);
        return Image.memory(
          bytes,
          fit: BoxFit.contain,
          width: double.infinity,
          errorBuilder: (_, __, ___) => const Center(
            child: Text('Failed to decode image',
                style: TextStyle(color: Colors.grey)),
          ),
        );
      } catch (_) {
        return const Center(
          child: Text('Failed to decode image',
              style: TextStyle(color: Colors.grey)),
        );
      }
    }
    // Regular HTTPS download URL
    return Image.network(
      src,
      fit: BoxFit.contain,
      width: double.infinity,
      loadingBuilder: (_, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const Center(
            child: CircularProgressIndicator(strokeWidth: 2));
      },
      errorBuilder: (_, __, ___) => const Center(
        child: Text('Failed to load image',
            style: TextStyle(color: Colors.grey)),
      ),
    );
  }

  Widget _card({required Widget child}) => Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
            )
          ],
        ),
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F7FA),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back
            InkWell(
              onTap: widget.onBack,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back, color: Color(0xFF4A5568)),
                  SizedBox(width: 8),
                  Text('Back',
                      style: TextStyle(
                          fontSize: 14, color: Color(0xFF4A5568))),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Obx(() {
              final r = req;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Left: prescription image ──────────────────────
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        _card(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Summary
                              Row(
                                children: [
                                  const Text('Request Details',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16)),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: r.isPending
                                          ? Colors.orange.withOpacity(0.12)
                                          : Colors.green.withOpacity(0.12),
                                      borderRadius:
                                          BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      r.status,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: r.isPending
                                            ? Colors.orange
                                            : Colors.green,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _InfoRow('Customer', r.customerName),
                              _InfoRow('Email', r.customerEmail),
                              _InfoRow('Medicine', r.medicineName),
                              _InfoRow(
                                  'Date',
                                  DateFormat('dd MMM yyyy, hh:mm a')
                                      .format(r.createdAt)),
                              if (r.adminResponse.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                const Divider(),
                                const SizedBox(height: 8),
                                _InfoRow(
                                    'Admin Response', r.adminResponse),
                              ],
                            ],
                          ),
                        ),

                        // Prescription image
                        _card(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Prescription Image',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15)),
                              const SizedBox(height: 12),
                              r.prescriptionUrl.isEmpty
                                  ? Container(
                                      width: double.infinity,
                                      height: 140,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        border: Border.all(
                                            color: Colors.grey.shade300),
                                      ),
                                      child: const Center(
                                        child: Text(
                                          'No prescription uploaded',
                                          style: TextStyle(
                                              color: Colors.grey),
                                        ),
                                      ),
                                    )
                                  : ClipRRect(
                                      borderRadius:
                                          BorderRadius.circular(8),
                                      child: _buildPrescriptionImage(
                                          r.prescriptionUrl),
                                    ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 24),

                  // ── Right: actions ────────────────────────────────
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        // Add to order
                        _card(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Medicine Available?',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              const Text(
                                'If the medicine exists in your product catalog, create an order for the customer.',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 12),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _showAddToOrderDialog,
                                  icon: const Icon(Icons.add_shopping_cart,
                                      size: 16),
                                  label: const Text('Add Medicine & Create Order'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(8)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Send notification
                        _card(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Send Notification',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 12),

                              // Toggle: preset vs custom
                              Row(
                                children: [
                                  Expanded(
                                    child: ChoiceChip(
                                      label: const Text('Preset',
                                          style: TextStyle(fontSize: 12)),
                                      selected: !_useCustom,
                                      onSelected: (_) => setState(
                                          () => _useCustom = false),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ChoiceChip(
                                      label: const Text('Custom',
                                          style: TextStyle(fontSize: 12)),
                                      selected: _useCustom,
                                      onSelected: (_) =>
                                          setState(() => _useCustom = true),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              if (!_useCustom)
                                DropdownButtonFormField<String>(
                                  value: _selectedResponse,
                                  hint: const Text('Select message...',
                                      style: TextStyle(fontSize: 13)),
                                  items: _kResponseOptions
                                      .map((e) => DropdownMenuItem(
                                            value: e,
                                            child: Text(e,
                                                style: const TextStyle(
                                                    fontSize: 12)),
                                          ))
                                      .toList(),
                                  onChanged: (v) => setState(
                                      () => _selectedResponse = v),
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                )
                              else
                                TextField(
                                  controller: _customResponseCtrl,
                                  maxLines: 3,
                                  decoration: const InputDecoration(
                                    hintText: 'Type your message...',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                ),
                              const SizedBox(height: 12),

                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _isSending
                                      ? null
                                      : _sendResponse,
                                  icon: _isSending
                                      ? const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white),
                                        )
                                      : const Icon(Icons.send, size: 16),
                                  label: Text(_isSending
                                      ? 'Sending...'
                                      : 'Send Notification'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color(0xFF6C63FF),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(8)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: const TextStyle(
                    color: Colors.grey, fontSize: 13)),
          ),
          Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}


