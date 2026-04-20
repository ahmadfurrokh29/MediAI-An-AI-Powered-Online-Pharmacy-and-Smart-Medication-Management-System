import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'controllers/order_controller.dart';
import 'models/order_model.dart';

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
  late final OrderController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = OrderController.instance;
    selectedStatus = widget.order.orderStatus;
    selectedPaymentStatus = widget.order.paymentStatus;
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final sid = order.id.length > 5 ? order.id.substring(0, 5) : order.id;
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
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Order [#$sid] Details',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        _card(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _IC(
                                'Order Date',
                                DateFormat(
                                  'dd/MM/yyyy',
                                ).format(order.createdAt),
                              ),
                              _IC(
                                'Items',
                                '${order.itemCount} item${order.itemCount != 1 ? 's' : ''}',
                              ),
                              _IC(
                                'Total',
                                '\$${order.totalAmount.toStringAsFixed(2)}',
                              ),
                              _IC('Status', order.orderStatus),
                              _IC('Payment', order.paymentStatus),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        _card(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Order Items',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        'Product',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        'Price',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        'Qty',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        'Subtotal',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(height: 8),
                              if (order.items.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Text(
                                    'No item details available',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                )
                              else
                                ...order.items.map(
                                  (item) => _ir(
                                    item.productName,
                                    '\$${item.price.toStringAsFixed(2)}',
                                    item.quantity.toString(),
                                    '\$${item.subtotal.toStringAsFixed(2)}',
                                  ),
                                ),
                              const Divider(height: 30),
                              _sr(
                                'Subtotal',
                                '\$${order.subtotal.toStringAsFixed(2)}',
                              ),
                              _sr(
                                'Coupon Discount',
                                order.couponDiscount > 0
                                    ? '-\$${order.couponDiscount.toStringAsFixed(2)}'
                                    : '-\$0.00',
                              ),
                              _sr(
                                'Shipping',
                                '\$${order.shippingFee.toStringAsFixed(2)}',
                              ),
                              const Divider(height: 30),
                              _sr(
                                'Total',
                                '\$${order.totalAmount.toStringAsFixed(2)}',
                                bold: true,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        _card(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Update Status',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                initialValue: selectedStatus,
                                items:
                                    [
                                          'Pending',
                                          'Processing',
                                          'Shipped',
                                          'Delivered',
                                        ]
                                        .map(
                                          (e) => DropdownMenuItem(
                                            value: e,
                                            child: Text(e),
                                          ),
                                        )
                                        .toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => selectedStatus = val);
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
                                    _ctrl.updatingOrderId.value == order.id;
                                return SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: busy
                                        ? null
                                        : () => _ctrl.updateOrderStatus(
                                            order.id,
                                            selectedStatus,
                                          ),
                                    child: busy
                                        ? const SizedBox(
                                            height: 16,
                                            width: 16,
                                            child: CircularProgressIndicator(
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

                        /// ── Payment Status Update ──
                        _card(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Payment Status',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                initialValue: selectedPaymentStatus,
                                items: ['Unpaid', 'Paid']
                                    .map((e) => DropdownMenuItem(
                                          value: e,
                                          child: Text(e),
                                        ))
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(
                                        () => selectedPaymentStatus = val);
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
                                    _ctrl.updatingOrderId.value == order.id;
                                return SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: busy
                                        ? null
                                        : () => _ctrl.updatePaymentStatus(
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
                        _card(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Customer',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                order.customerName.isEmpty
                                    ? 'N/A'
                                    : order.customerName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                order.customerEmail,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        _card(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Shipping Address',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              if (order.shippingAddress.isEmpty)
                                const Text(
                                  'No shipping address',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                  ),
                                )
                              else ...[
                                _al(
                                  order.shippingAddress['name'] as String? ??
                                      order.shippingAddress['Name']
                                          as String? ??
                                      '',
                                ),
                                _al(
                                  [
                                    order.shippingAddress['city'] as String? ??
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
                                  ].where((s) => s.isNotEmpty).join(', '),
                                ),
                                _al(
                                  order.shippingAddress['phone'] as String? ??
                                      order.shippingAddress['Phone']
                                          as String? ??
                                      order.shippingAddress['phoneNumber']
                                          as String? ??
                                      '',
                                ),
                                _al(
                                  order.shippingAddress['address'] as String? ??
                                      order.shippingAddress['Address']
                                          as String? ??
                                      '',
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

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
  static Widget _ir(String t, String p, String q, String s) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Expanded(flex: 3, child: Text(t)),
        Expanded(child: Text(p)),
        Expanded(child: Text(q)),
        Expanded(child: Text(s)),
      ],
    ),
  );
  static Widget _sr(String t, String v, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          t,
          style: TextStyle(
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          v,
          style: TextStyle(
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    ),
  );
}

class _IC extends StatelessWidget {
  final String title, value;
  const _IC(this.title, this.value);
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      const SizedBox(height: 6),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
    ],
  );
}
