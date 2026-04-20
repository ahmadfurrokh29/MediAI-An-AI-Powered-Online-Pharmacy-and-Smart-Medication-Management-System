import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/customer_controller.dart';
import '../models/customer_model.dart';

class CustomersPage extends StatelessWidget {
  final Function(CustomerModel) onView;
  const CustomersPage({super.key, required this.onView});

  @override
  Widget build(BuildContext context) {
    final controller = CustomerController.instance;
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
              onPressed: controller.fetchCustomers,
              icon: const Icon(Icons.refresh, color: Color(0xFF4A5568)),
              tooltip: 'Refresh',
            ),
            const SizedBox(width: 8),
            Obx(
              () => Text(
                '(${controller.filteredCustomers.length})',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: 250,
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Search customers...',
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
            final customers = controller.filteredCustomers;
            if (customers.isEmpty) {
              return const Center(child: Text('No customers found'));
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
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 50,
                    horizontalMargin: 20,
                    columns: const [
                      DataColumn(label: Text('#')),
                      DataColumn(label: Text('Customer')),
                      DataColumn(label: Text('Email')),
                      DataColumn(label: Text('Phone')),
                      DataColumn(label: Text('Orders')),
                      DataColumn(label: Text('Points')),
                      DataColumn(label: Text('Register Date')),
                      DataColumn(label: Text('Action')),
                    ],
                    rows: List.generate(customers.length, (index) {
                      final c = customers[index];
                      return DataRow(
                        cells: [
                          DataCell(Text('${index + 1}')),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: _avatarColor(c.id),
                                  child: Text(
                                    c.initials,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  c.fullName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF4299E1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          DataCell(
                            Text(c.email, overflow: TextOverflow.ellipsis),
                          ),
                          DataCell(
                            Text(c.phoneNumber.isEmpty ? '-' : c.phoneNumber),
                          ),
                          DataCell(
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: _orderCountColor(c.orderCount),
                              child: Text(
                                c.orderCount.toString(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: _pointsColor(c.points),
                              child: Text(
                                c.points.toString(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              DateFormat(
                                'dd/MM/yyyy \'at\' H:mm',
                              ).format(c.createdAt),
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
                                  onPressed: () => onView(c),
                                  tooltip: 'View',
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 20,
                                    color: Colors.red,
                                  ),
                                  onPressed: () =>
                                      _confirmDelete(context, controller, c),
                                  tooltip: 'Delete',
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            );
          }),
        ),

        // ── Footer row count ──
        const SizedBox(height: 10),
        Obx(
          () => Text(
            'Showing ${controller.filteredCustomers.length} of ${controller.customers.length} Customers',
            style: const TextStyle(color: Colors.grey),
          ),
        ),
      ],
    );
  }

  // ── Helpers ──
  static Color _avatarColor(String id) {
    const colors = [
      Color(0xFF4299E1),
      Color(0xFF9F7AEA),
      Color(0xFFED8936),
      Color(0xFFE53E3E),
      Color(0xFF48BB78),
      Color(0xFF805AD5),
      Color(0xFFD69E2E),
      Color(0xFF2C5282),
      Color(0xFFD53F8C),
      Color(0xFFDD6B20),
    ];
    final h = id.codeUnits.fold(0, (int p, int e) => p + e);
    return colors[h % colors.length];
  }

  static Color _orderCountColor(int n) {
    if (n == 0) return const Color(0xFF9F7AEA);
    if (n <= 3) return const Color(0xFFED8936);
    return const Color(0xFF48BB78);
  }

  static Color _pointsColor(int n) {
    if (n == 0) return const Color(0xFF9F7AEA);
    if (n <= 50) return const Color(0xFFED8936);
    return const Color(0xFF48BB78);
  }

  static void _confirmDelete(
    BuildContext context,
    CustomerController controller,
    CustomerModel c,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Text(
          'Are you sure you want to delete ${c.fullName}?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              controller.deleteCustomer(c.id);
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
