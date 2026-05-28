import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'controllers/order_controller.dart';
import 'models/order_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Available notification messages admin can send to the customer.
// ─────────────────────────────────────────────────────────────────────────────
const List<String> _kNotificationOptions = [
  'Item out of stock',
  'Item not available',
  'Invalid prescription uploaded',
  'Items and prescription do not match',
  'Items removed as not on prescription',
  'Added new items to your order',
];

class OrderDetailsPage extends StatefulWidget {
  final OrderModel order;
  final VoidCallback onBack;
  const OrderDetailsPage({
    super.key,
    required this.order,
    required this.onBack,
  });
  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  late String selectedStatus;
  late String selectedPaymentStatus;
  String? selectedNotification;
  late final OrderController _ctrl;

  /// Always use live order from controller list.
  OrderModel get _order {
    final found =
        _ctrl.orders.firstWhereOrNull((o) => o.id == widget.order.id);
    return found ?? widget.order;
  }

  @override
  void initState() {
    super.initState();
    _ctrl = OrderController.instance;
    selectedStatus = widget.order.orderStatus;
    selectedPaymentStatus = const ['Unpaid', 'Paid'].contains(widget.order.paymentStatus)
        ? widget.order.paymentStatus
        : 'Unpaid';
  }

  bool get _hasPrescriptions => _order.prescriptions.isNotEmpty;

  // ── Dialogs ────────────────────────────────────────────────────────────────

  /// Renders a prescription image from any of the three stored formats:
  /// - HTTPS URL (Cloudinary or Firebase Storage)
  /// - data:image/...;base64,... data-URI
  /// - Raw base64 string (legacy mobile uploads)
  Widget _buildPrescriptionWidget(String src, double width) {
    if (src.startsWith('http')) {
      return Image.network(
        src,
        width: width,
        fit: BoxFit.contain,
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : const CircularProgressIndicator(),
        errorBuilder: (_, __, ___) =>
            const Text('Failed to load', style: TextStyle(color: Colors.grey)),
      );
    }
    // data-URI or raw base64
    try {
      final b64 = src.startsWith('data:image')
          ? src.substring(src.indexOf(',') + 1)
          : src;
      final bytes = base64Decode(b64);
      return Image.memory(bytes, width: width, fit: BoxFit.contain);
    } catch (_) {
      return const Text('Invalid image',
          style: TextStyle(color: Colors.grey));
    }
  }

  void _showPrescriptions() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: 680, maxHeight: 560),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 16),
                decoration: const BoxDecoration(
                  color: Color(0xFF6C63FF),
                  borderRadius: BorderRadius.vertical(
                      top: Radius.circular(12)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.medical_services_outlined,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Prescription(s)',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                    ),
                    IconButton(
                      icon:
                          const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(ctx),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: _order.prescriptions
                        .asMap()
                        .entries
                        .map((e) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Prescription ${e.key + 1}',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: _buildPrescriptionWidget(e.value, 280),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddItemDialog() {
    final searchCtrl = TextEditingController();
    List<Map<String, dynamic>> results = [];
    Map<String, dynamic>? selectedProduct;
    int addQty = 1;
    bool searching = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setS) {
          Future<void> search(String q) async {
            if (q.trim().length < 2) {
              setS(() => results = []);
              return;
            }
            setS(() => searching = true);
            try {
              // Prefix search on Name
              QuerySnapshot snap;
              try {
                snap = await FirebaseFirestore.instance
                    .collection('Products')
                    .orderBy('Name')
                    .startAt([q.trim()])
                    .endAt(['${q.trim()}\uf8ff'])
                    .limit(20)
                    .get();
              } catch (_) {
                snap = await FirebaseFirestore.instance
                    .collection('Products')
                    .limit(60)
                    .get();
              }

              List<Map<String, dynamic>> found = snap.docs
                  .where((d) {
                    final n = (d.data()
                                    as Map<String, dynamic>)['Name'] ??
                            (d.data() as Map<String, dynamic>)['name'] ??
                            '';
                    return n
                        .toString()
                        .toLowerCase()
                        .contains(q.trim().toLowerCase());
                  })
                  .map((d) {
                    final data = d.data() as Map<String, dynamic>;
                    final regularPrice =
                        (data['Price'] ?? data['price'] ?? 0).toDouble();
                    final salePrice =
                        (data['SalePrice'] ?? data['salePrice'] ?? 0).toDouble();
                    final effectivePrice =
                        (salePrice > 0 && salePrice < regularPrice)
                            ? salePrice
                            : regularPrice;
                    return {
                      'id': d.id,
                      'name':
                          (data['Name'] ?? data['name'] ?? '').toString(),
                      'price': effectivePrice,
                      'isPrescribed':
                          data['IsPrescribed'] ?? data['isPrescribed'] ?? false,
                    };
                  })
                  .toList();

              setS(() {
                results = found;
                searching = false;
              });
            } catch (_) {
              setS(() => searching = false);
            }
          }

          return Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
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
                        const Text(
                          'Add Item to Order',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx2),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: searchCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Search product by name...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: search,
                    ),
                    const SizedBox(height: 8),
                    if (searching)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    Expanded(
                      child: results.isEmpty && !searching
                          ? const Center(
                              child: Text('Type to search products',
                                  style: TextStyle(color: Colors.grey)))
                          : ListView.builder(
                              itemCount: results.length,
                              itemBuilder: (_, i) {
                                final p = results[i];
                                final isSelected =
                                    selectedProduct?['id'] == p['id'];
                                return ListTile(
                                  dense: true,
                                  selected: isSelected,
                                  selectedTileColor: const Color(0xFF6C63FF)
                                      .withOpacity(0.08),
                                  title: Text(p['name'] as String),
                                  subtitle: Text(
                                    'Rs ${(p['price'] as double).toStringAsFixed(0)}'
                                    '${p['isPrescribed'] == true ? ' • Prescribed' : ''}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  trailing: isSelected
                                      ? const Icon(Icons.check_circle,
                                          color: Color(0xFF6C63FF))
                                      : null,
                                  onTap: () =>
                                      setS(() => selectedProduct = p),
                                );
                              },
                            ),
                    ),
                    if (selectedProduct != null) ...[
                      const Divider(),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              selectedProduct!['name'] as String,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('Qty: '),
                          _qtyBtn(
                            icon: Icons.remove,
                            onTap: addQty > 1
                                ? () => setS(() => addQty--)
                                : null,
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8),
                            child: Text('$addQty',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                          ),
                          _qtyBtn(
                            icon: Icons.add,
                            onTap: () => setS(() => addQty++),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Spacer(),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx2),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: selectedProduct == null
                              ? null
                              : () {
                                  final p = selectedProduct!;
                                  final item = OrderItemModel(
                                    productId: p['id'] as String,
                                    productName: p['name'] as String,
                                    price: p['price'] as double,
                                    quantity: addQty,
                                    isPrescribed:
                                        p['isPrescribed'] as bool? ??
                                            false,
                                  );
                                  _ctrl.addOrderItem(_order.id, item);
                                  Navigator.pop(ctx2);
                                },
                          child: const Text('Add'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final sid =
        _order.id.length > 5 ? _order.id.substring(0, 5) : _order.id;

    return Container(
      color: const Color(0xFFF5F7FA),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: widget.onBack,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_back, color: Color(0xFF4A5568)),
                    SizedBox(width: 8),
                    Text(
                      'Back',
                      style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF4A5568),
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Order [#$sid] Details',
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Obx(() {
                final order = _order;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Left column ──────────────────────────────────
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          // Summary bar
                          _card(
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                _IC('Order Date',
                                    DateFormat('dd/MM/yyyy')
                                        .format(order.createdAt)),
                                _IC(
                                    'Items',
                                    '${order.itemCount} item${order.itemCount != 1 ? 's' : ''}'),
                                _IC('Total',
                                    'Rs ${order.totalAmount.toStringAsFixed(0)}'),
                                _IC('Status', order.orderStatus),
                                _IC('Payment', order.paymentStatus),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Order Items card
                          _card(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header
                                Row(
                                  children: [
                                    const Text(
                                      'Order Items',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15),
                                    ),
                                    const Spacer(),
                                    if (_hasPrescriptions) ...[
                                      _actionBtn(
                                        icon: Icons.visibility_outlined,
                                        label: 'View Prescription',
                                        color: const Color(0xFF6C63FF),
                                        onTap: _showPrescriptions,
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    _actionBtn(
                                      icon: Icons.add_circle_outline,
                                      label: 'Add Item',
                                      color: Colors.green,
                                      onTap: _showAddItemDialog,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Column headers
                                const Padding(
                                  padding:
                                      EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 4,
                                        child: Text('Product',
                                            style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 12)),
                                      ),
                                      SizedBox(
                                        width: 80,
                                        child: Text('Prescribed',
                                            style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 12)),
                                      ),
                                      Expanded(
                                        child: Text('Price',
                                            style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 12)),
                                      ),
                                      SizedBox(
                                        width: 110,
                                        child: Text('Qty',
                                            style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 12)),
                                      ),
                                      Expanded(
                                        child: Text('Subtotal',
                                            style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 12)),
                                      ),
                                      SizedBox(width: 32),
                                    ],
                                  ),
                                ),
                                const Divider(height: 8),

                                // Item rows
                                if (order.items.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                        vertical: 12),
                                    child: Text(
                                      'No item details available',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  )
                                else
                                  ...order.items.asMap().entries.map(
                                    (entry) => _ItemRow(
                                      key: ValueKey(
                                          '${order.id}_${entry.key}'),
                                      item: entry.value,
                                      index: entry.key,
                                      orderId: order.id,
                                      ctrl: _ctrl,
                                    ),
                                  ),

                                const Divider(height: 30),
                                _sr('Subtotal',
                                    'Rs ${order.subtotal.toStringAsFixed(0)}'),
                                _sr(
                                  'Coupon Discount',
                                  order.couponDiscount > 0
                                      ? '-Rs ${order.couponDiscount.toStringAsFixed(0)}'
                                      : '-Rs 0',
                                ),
                                _sr('Shipping',
                                    'Rs ${order.shippingFee.toStringAsFixed(0)}'),
                                const Divider(height: 30),
                                _sr(
                                  'Total',
                                  'Rs ${order.totalAmount.toStringAsFixed(0)}',
                                  bold: true,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 24),

                    // ── Right column ─────────────────────────────────
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          // Update Status
                          _card(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Update Status',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<String>(
                                  value: selectedStatus,
                                  items: const [
                                    'Pending',
                                    'Processing',
                                    'Shipped',
                                    'Delivered',
                                    'Cancelled',
                                  ]
                                      .map((e) => DropdownMenuItem(
                                            value: e,
                                            child: Text(e),
                                          ))
                                      .toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(
                                          () => selectedStatus = val);
                                    }
                                  },
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                ),

                                // Send Notification (only when prescriptions exist)
                                if (_hasPrescriptions) ...[
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Send Notification (optional)',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey),
                                  ),
                                  const SizedBox(height: 6),
                                  DropdownButtonFormField<String>(
                                    value: selectedNotification,
                                    hint: const Text(
                                      'Select message...',
                                      style: TextStyle(fontSize: 13),
                                    ),
                                    items: [
                                      const DropdownMenuItem<String>(
                                        value: null,
                                        child: Text('— None —',
                                            style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 13)),
                                      ),
                                      ..._kNotificationOptions.map(
                                        (e) => DropdownMenuItem(
                                          value: e,
                                          child: Text(e,
                                              style: const TextStyle(
                                                  fontSize: 13)),
                                        ),
                                      ),
                                    ],
                                    onChanged: (val) => setState(
                                        () => selectedNotification = val),
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                    isExpanded: true,
                                  ),
                                ],

                                const SizedBox(height: 12),
                                Obx(() {
                                  final busy =
                                      _ctrl.updatingOrderId.value ==
                                          order.id;
                                  return SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: busy
                                          ? null
                                          : () async {
                                              await _ctrl.updateOrderStatus(
                                                  order.id,
                                                  selectedStatus);
                                              if (selectedNotification !=
                                                      null &&
                                                  selectedNotification!
                                                      .isNotEmpty) {
                                                await _ctrl
                                                    .sendNotification(
                                                  order.customerId,
                                                  order.id,
                                                  selectedNotification!,
                                                );
                                                setState(() =>
                                                    selectedNotification =
                                                        null);
                                              }
                                            },
                                      child: busy
                                          ? const SizedBox(
                                              height: 16,
                                              width: 16,
                                              child:
                                                  CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Text('Update'),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Payment Status
                          _card(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Payment Status',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<String>(
                                  value: selectedPaymentStatus,
                                  items: ['Unpaid', 'Paid']
                                      .map((e) => DropdownMenuItem(
                                            value: e,
                                            child: Text(e),
                                          ))
                                      .toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() =>
                                          selectedPaymentStatus = val);
                                    }
                                  },
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Obx(() {
                                  final busy =
                                      _ctrl.updatingOrderId.value ==
                                          order.id;
                                  return SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: busy
                                          ? null
                                          : () =>
                                              _ctrl.updatePaymentStatus(
                                                order.id,
                                                selectedPaymentStatus,
                                              ),
                                      child: busy
                                          ? const SizedBox(
                                              height: 16,
                                              width: 16,
                                              child:
                                                  CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Text('Update Payment'),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Customer
                          _card(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Customer',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  order.customerName.isEmpty
                                      ? 'N/A'
                                      : order.customerName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  order.customerEmail,
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Shipping Address
                          _card(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Shipping Address',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 8),
                                if (order.shippingAddress.isEmpty)
                                  const Text(
                                    'No shipping address',
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 13),
                                  )
                                else ...[
                                  _al(order.shippingAddress['name']
                                          as String? ??
                                      order.shippingAddress['Name']
                                          as String? ??
                                      ''),
                                  _al([
                                    order.shippingAddress['city']
                                            as String? ??
                                        order.shippingAddress['City']
                                            as String? ??
                                        '',
                                    order.shippingAddress['postalCode']
                                            as String? ??
                                        order.shippingAddress['PostalCode']
                                            as String? ??
                                        '',
                                    order.shippingAddress['country']
                                            as String? ??
                                        order.shippingAddress['Country']
                                            as String? ??
                                        '',
                                  ]
                                      .where((s) => s.isNotEmpty)
                                      .join(', ')),
                                  _al(order.shippingAddress['phone']
                                          as String? ??
                                      order.shippingAddress['Phone']
                                          as String? ??
                                      order.shippingAddress['phoneNumber']
                                          as String? ??
                                      ''),
                                  _al(order.shippingAddress['address']
                                          as String? ??
                                      order.shippingAddress['Address']
                                          as String? ??
                                      ''),
                                ],
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
      ),
    );
  }

  // ── Static helpers ────────────────────────────────────────────────────────

  static Widget _al(String t) {
    if (t.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(t, style: const TextStyle(fontSize: 13)),
    );
  }

  static Widget _card({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: child,
      );

  static Widget _sr(String t, String v, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(t,
                style: TextStyle(
                    fontWeight:
                        bold ? FontWeight.bold : FontWeight.normal)),
            Text(v,
                style: TextStyle(
                    fontWeight:
                        bold ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      );

  static Widget _actionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: color.withOpacity(0.6)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Text(label,
                  style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      );

  static Widget _qtyBtn(
          {required IconData icon, VoidCallback? onTap}) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            border: Border.all(
                color: onTap != null
                    ? Colors.grey
                    : Colors.grey.shade300),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(icon,
              size: 14,
              color: onTap != null
                  ? Colors.black87
                  : Colors.grey.shade300),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Stateful item row — handles local +/- quantity before committing to Firestore
// ─────────────────────────────────────────────────────────────────────────────
class _ItemRow extends StatefulWidget {
  final OrderItemModel item;
  final int index;
  final String orderId;
  final OrderController ctrl;

  const _ItemRow({
    super.key,
    required this.item,
    required this.index,
    required this.orderId,
    required this.ctrl,
  });

  @override
  State<_ItemRow> createState() => _ItemRowState();
}

class _ItemRowState extends State<_ItemRow> {
  late int _qty;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _qty = widget.item.quantity;
  }

  @override
  void didUpdateWidget(_ItemRow old) {
    super.didUpdateWidget(old);
    if (old.item.quantity != widget.item.quantity) {
      _qty = widget.item.quantity;
    }
  }

  Future<void> _save(int newQty) async {
    setState(() {
      _qty = newQty;
      _saving = true;
    });
    await widget.ctrl
        .updateItemQuantity(widget.orderId, widget.index, newQty);
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Product name
          Expanded(
            flex: 4,
            child: Text(item.productName,
                style: const TextStyle(fontSize: 13)),
          ),

          // Prescribed badge
          SizedBox(
            width: 80,
            child: Text(
              item.isPrescribed ? 'Yes' : 'No',
              style: TextStyle(
                fontSize: 12,
                color: item.isPrescribed
                    ? Colors.orange.shade700
                    : Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Price
          Expanded(
            child: Text(
              'Rs ${item.price.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 13),
            ),
          ),

          // Qty +/-
          SizedBox(
            width: 110,
            child: Row(
              children: [
                _qtyBtn(
                  icon: Icons.remove,
                  onTap: (!_saving && _qty > 1) ? () => _save(_qty - 1) : null,
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6),
                  child: Text('$_qty',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold)),
                ),
                _qtyBtn(
                  icon: Icons.add,
                  onTap: _saving ? null : () => _save(_qty + 1),
                ),
              ],
            ),
          ),

          // Subtotal
          Expanded(
            child: Text(
              'Rs ${(item.price * _qty).toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 13),
            ),
          ),

          // Remove
          SizedBox(
            width: 32,
            child: IconButton(
              icon: const Icon(Icons.cancel_outlined,
                  color: Colors.red, size: 18),
              tooltip: 'Remove item',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => widget.ctrl
                  .removeOrderItem(widget.orderId, widget.index),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _qtyBtn(
          {required IconData icon, VoidCallback? onTap}) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            border: Border.all(
                color: onTap != null
                    ? Colors.grey
                    : Colors.grey.shade300),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(icon,
              size: 14,
              color: onTap != null
                  ? Colors.black87
                  : Colors.grey.shade300),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Info chip
// ─────────────────────────────────────────────────────────────────────────────
class _IC extends StatelessWidget {
  final String title, value;
  const _IC(this.title, this.value);
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      );
}
