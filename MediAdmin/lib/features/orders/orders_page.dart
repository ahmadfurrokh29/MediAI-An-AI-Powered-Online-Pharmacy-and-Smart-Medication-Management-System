import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'controllers/order_controller.dart';
import 'models/order_model.dart';

class OrdersPage extends StatelessWidget {
  final Function(OrderModel) onView;
  const OrdersPage({super.key, required this.onView});

  @override
  Widget build(BuildContext context) {
    final controller = OrderController.instance;
    final searchController = TextEditingController();
    searchController.addListener(() {
      controller.searchQuery.value = searchController.text;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.initialize();
    });

    return Column(
      children: [
        // ── Header row: refresh + total count + search ──
        Row(
          children: [
            IconButton(
              onPressed: controller.fetchOrders,
              icon: const Icon(Icons.refresh, color: Color(0xFF4A5568)),
              tooltip: 'Refresh',
            ),
            const SizedBox(width: 8),
            Obx(
              () => Text(
                '(${controller.filteredOrders.length})',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: 250,
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Search orders...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── DataTable ──
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }
            final orders = controller.filteredOrders;
            if (orders.isEmpty) {
              return const Center(child: Text('No orders found'));
            }
            return Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 50,
                  horizontalMargin: 20,
                  columns: const [
                    DataColumn(label: Text('Order ID')),
                    DataColumn(label: Text('Customer')),
                    DataColumn(label: Text('Items')),
                    DataColumn(label: Text('Order Status')),
                    DataColumn(label: Text('Payment')),
                    DataColumn(label: Text('Amount')),
                    DataColumn(label: Text('Date')),
                    DataColumn(label: Text('Action')),
                  ],
                  rows: orders.map((order) {
                    final shortId = order.id.length > 5
                        ? order.id.substring(0, 5)
                        : order.id;
                    return DataRow(
                      cells: [
                        DataCell(
                          Text(
                            '#$shortId',
                            style: const TextStyle(
                              color: Color(0xFF4299E1),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        DataCell(
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                order.customerName.isEmpty
                                    ? 'Unknown'
                                    : order.customerName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                order.customerEmail,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        DataCell(
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: _itemCountColor(order.itemCount),
                            child: Text(
                              order.itemCount.toString(),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _statusBg(order.orderStatus),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              order.orderStatus,
                              style: TextStyle(
                                fontSize: 12,
                                color: _statusColor(order.orderStatus),
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _payBg(order.paymentStatus),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              order.paymentStatus,
                              style: TextStyle(
                                fontSize: 12,
                                color: _payColor(order.paymentStatus),
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            '\$${order.totalAmount.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        DataCell(
                          Text(
                            DateFormat('dd/MM/yyyy').format(order.createdAt),
                          ),
                        ),
                        DataCell(
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.visibility_outlined,
                                  size: 20,
                                  color: Colors.blueGrey,
                                ),
                                onPressed: () => onView(order),
                                tooltip: 'View',
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 20,
                                  color: Colors.red,
                                ),
                                onPressed: () =>
                                    _confirmDelete(context, controller, order),
                                tooltip: 'Delete',
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

        // ── Footer row count ──
        const SizedBox(height: 10),
        Obx(
          () => Text(
            'Showing ${controller.filteredOrders.length} of ${controller.orders.length} Orders',
            style: const TextStyle(color: Colors.grey),
          ),
        ),
      ],
    );
  }

  // ── Status helpers ──
  static Color _itemCountColor(int c) {
    if (c == 1) return const Color(0xFF9F7AEA);
    if (c <= 3) return const Color(0xFFED8936);
    if (c <= 5) return const Color(0xFF48BB78);
    return const Color(0xFF4299E1);
  }

  static Color _statusBg(String s) {
    switch (s.toLowerCase()) {
      case 'delivered':
        return const Color(0xFFF0FFF4);
      case 'shipped':
        return const Color(0xFFEBF8FF);
      case 'processing':
        return const Color(0xFFFFFAF0);
      default:
        return const Color(0xFFFFF5F5);
    }
  }

  static Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'delivered':
        return const Color(0xFF276749);
      case 'shipped':
        return const Color(0xFF2B6CB0);
      case 'processing':
        return const Color(0xFFB7791F);
      default:
        return const Color(0xFFC53030);
    }
  }

  static Color _payBg(String s) => s.toLowerCase() == 'paid'
      ? const Color(0xFFF0FFF4)
      : const Color(0xFFF7FAFC);

  static Color _payColor(String s) => s.toLowerCase() == 'paid'
      ? const Color(0xFF276749)
      : const Color(0xFF718096);

  static void _confirmDelete(
    BuildContext context,
    OrderController controller,
    OrderModel order,
  ) {
    final shortId = order.id.length > 5 ? order.id.substring(0, 5) : order.id;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Order'),
        content: Text(
          'Are you sure you want to delete order #$shortId?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              controller.deleteOrder(order.id);
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
