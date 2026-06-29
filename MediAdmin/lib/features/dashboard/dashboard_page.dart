import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'controllers/dashboard_controller.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = DashboardController.instance;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ctrl.initialize();
    });

    return Obx(() {
      if (ctrl.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: ctrl.isExporting.value
                      ? null
                      : ctrl.generateExcelReport,
                  icon: ctrl.isExporting.value
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.download,
                          size: 18,
                          color: Colors.white,
                        ),
                  label: Text(
                    ctrl.isExporting.value
                        ? 'Exporting...'
                        : 'Export Daily Report',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF38A169),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: ctrl.isLoading.value
                      ? null
                      : ctrl.refreshDashboard,
                  icon: ctrl.isLoading.value
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.refresh,
                          size: 18,
                          color: Colors.white,
                        ),
                  label: Text(
                    ctrl.isLoading.value ? 'Refreshing...' : 'Refresh',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4299E1),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Today\'s Statistics',
              style: TextStyle(fontSize: 13, color: Color(0xFF718096)),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _statCard(
                    'Sales Total',
                    'Rs ${ctrl.todaySalesTotal.toStringAsFixed(2)}',
                    Icons.currency_rupee,
                    const Color(0xFF4299E1),
                    const Color(0xFFEBF8FF),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _statCard(
                    'Avg Order Value',
                    'Rs ${ctrl.todayAvgOrderValue.toStringAsFixed(2)}',
                    Icons.trending_up,
                    const Color(0xFF9F7AEA),
                    const Color(0xFFF3EBFF),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _statCard(
                    'Total Orders',
                    ctrl.todayTotalOrders.toString(),
                    Icons.shopping_bag,
                    const Color(0xFFED8936),
                    const Color(0xFFFFF5EB),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _statCard(
                    'Sold Products',
                    ctrl.todaySoldProducts.toString(),
                    Icons.inventory_2,
                    const Color(0xFF38A169),
                    const Color(0xFFF0FFF4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(children: [_recentOrdersCard(ctrl)]),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      _chartCard(ctrl),
                      const SizedBox(height: 20),
                      _stockCard(ctrl),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  static Widget _statCard(
    String label,
    String value,
    IconData icon,
    Color ic,
    Color ibg,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: ibg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: ic, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Color(0xFF718096)),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _recentOrdersCard(DashboardController ctrl) {
    final orders = ctrl.recentOrders;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.shopping_bag, color: Color(0xFF4299E1), size: 20),
                SizedBox(width: 8),
                Text(
                  'Recent Orders',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3748),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          SizedBox(
            width: double.infinity,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF7FAFC)),
              columns: const [
                DataColumn(
                  label: Text(
                    'Order ID',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4A5568),
                      fontSize: 13,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Date',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4A5568),
                      fontSize: 13,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Items',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4A5568),
                      fontSize: 13,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Status',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4A5568),
                      fontSize: 13,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Amount',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4A5568),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
              rows: orders.map((o) {
                final sid = o.id.length > 5 ? o.id.substring(0, 5) : o.id;
                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        '#$sid',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF4299E1),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        DateFormat('dd/MM/yyyy').format(o.createdAt),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF718096),
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        '${o.itemCount} item${o.itemCount != 1 ? 's' : ''}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF2D3748),
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
                          color: _sbg(o.orderStatus),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          o.orderStatus,
                          style: TextStyle(
                            fontSize: 12,
                            color: _stc(o.orderStatus),
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        'Rs ${o.totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
          if (orders.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: Text(
                  'No orders today',
                  style: TextStyle(color: Color(0xFF718096)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _chartCard(DashboardController ctrl) {
    final pending = ctrl.pendingCount.toDouble();
    final processing = ctrl.processingCount.toDouble();
    final shipped = ctrl.shippedCount.toDouble();
    final delivered = ctrl.deliveredCount.toDouble();
    final total = pending + processing + shipped + delivered;

    final sections = <PieChartSectionData>[];
    if (pending > 0) {
      sections.add(
        PieChartSectionData(
          value: pending,
          color: const Color(0xFFFC8181),
          title: '',
          radius: 60,
        ),
      );
    }
    if (processing > 0) {
      sections.add(
        PieChartSectionData(
          value: processing,
          color: const Color(0xFFED8936),
          title: '',
          radius: 60,
        ),
      );
    }
    if (shipped > 0) {
      sections.add(
        PieChartSectionData(
          value: shipped,
          color: const Color(0xFF4299E1),
          title: '',
          radius: 60,
        ),
      );
    }
    if (delivered > 0) {
      sections.add(
        PieChartSectionData(
          value: delivered,
          color: const Color(0xFF48BB78),
          title: '',
          radius: 60,
        ),
      );
    }
    if (sections.isEmpty) {
      sections.add(
        PieChartSectionData(
          value: 1,
          color: const Color(0xFFE2E8F0),
          title: '',
          radius: 60,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.pie_chart, color: Color(0xFF4299E1), size: 20),
              SizedBox(width: 8),
              Text(
                'Order Status',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3748),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sections: sections,
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _legend(
            'Pending',
            const Color(0xFFFC8181),
            pending.toInt(),
            total.toInt(),
          ),
          _legend(
            'Processing',
            const Color(0xFFED8936),
            processing.toInt(),
            total.toInt(),
          ),
          _legend(
            'Shipped',
            const Color(0xFF4299E1),
            shipped.toInt(),
            total.toInt(),
          ),
          _legend(
            'Delivered',
            const Color(0xFF48BB78),
            delivered.toInt(),
            total.toInt(),
          ),
        ],
      ),
    );
  }

  static Widget _legend(String label, Color color, int count, int total) {
    final pct = total > 0 ? (count / total * 100).toStringAsFixed(0) : '0';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Color(0xFF4A5568)),
            ),
          ),
          Text(
            '$count ($pct%)',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF718096),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stockCard(DashboardController ctrl) {
    final products = ctrl.lowStockProducts;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber, color: Color(0xFFED8936), size: 20),
              SizedBox(width: 8),
              Text(
                'Stock Refill Needed',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3748),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Products with stock  10',
            style: TextStyle(fontSize: 12, color: Color(0xFF718096)),
          ),
          const SizedBox(height: 16),
          if (products.isEmpty)
            const Text(
              'All products are well stocked!',
              style: TextStyle(fontSize: 13, color: Color(0xFF48BB78)),
            )
          else
            ...products.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFED8936),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        p.name,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF2D3748),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF5EB),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Left: ${p.stock}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFFB7791F),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FFF4),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Refill: ${100 - p.stock}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF276749),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  static Color _sbg(String s) {
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

  static Color _stc(String s) {
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
}
