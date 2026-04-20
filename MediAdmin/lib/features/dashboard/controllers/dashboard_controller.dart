import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:universal_html/html.dart' as html;
import '../../orders/models/order_model.dart';

class LowStockProduct {
  final String id;
  final String name;
  final int stock;

  LowStockProduct({required this.id, required this.name, required this.stock});
}

class DashboardController extends GetxController {
  static DashboardController get instance => Get.find();

  final _firestore = FirebaseFirestore.instance;

  final RxBool isLoading = false.obs;
  final RxBool hasInitialized = false.obs;
  final RxBool isExporting = false.obs;

  final RxList<OrderModel> _allOrders = <OrderModel>[].obs;
  final RxList<LowStockProduct> lowStockProducts = <LowStockProduct>[].obs;

  // Explicit reactive stat values — updated whenever _allOrders changes
  final RxDouble salesTotal = 0.0.obs;
  final RxDouble avgOrderValue = 0.0.obs;
  final RxInt totalOrders = 0.obs;
  final RxInt soldProducts = 0.obs;

  StreamSubscription<QuerySnapshot>? _ordersSubscription;

  // ── Derived values ──
  List<OrderModel> get todayOrders {
    final now = DateTime.now();
    return _allOrders
        .where(
          (o) =>
              o.createdAt.year == now.year &&
              o.createdAt.month == now.month &&
              o.createdAt.day == now.day,
        )
        .toList();
  }

  /// Only delivered + paid orders count toward revenue
  List<OrderModel> get _completedTodayOrders => todayOrders
      .where(
        (o) =>
            o.orderStatus.toLowerCase() == 'delivered' &&
            o.paymentStatus.toLowerCase() == 'paid',
      )
      .toList();

  double get todaySalesTotal => salesTotal.value;

  double get todayAvgOrderValue => avgOrderValue.value;

  int get todayTotalOrders => totalOrders.value;

  int get todaySoldProducts => soldProducts.value;

  List<OrderModel> get recentOrders => _allOrders.take(5).toList();

  int get pendingCount =>
      _allOrders.where((o) => o.orderStatus.toLowerCase() == 'pending').length;

  int get processingCount => _allOrders
      .where((o) => o.orderStatus.toLowerCase() == 'processing')
      .length;

  int get deliveredCount => _allOrders
      .where((o) => o.orderStatus.toLowerCase() == 'delivered')
      .length;

  int get shippedCount =>
      _allOrders.where((o) => o.orderStatus.toLowerCase() == 'shipped').length;

  /// Recalculate the four stat values from current _allOrders
  void _recalculateStats() {
    final completed = _completedTodayOrders;
    final today = todayOrders;

    final total = completed.fold(0.0, (sum, o) => sum + o.totalAmount);
    salesTotal.value = total;

    final now = DateTime.now();
    final daysElapsed = now.day;
    avgOrderValue.value = total == 0 ? 0.0 : total / daysElapsed;

    totalOrders.value = today.length;

    soldProducts.value = completed.fold(
      0,
      (sum, o) => sum + o.items.fold(0, (s, i) => s + i.quantity),
    );
  }

  Future<void> initialize() async {
    if (hasInitialized.value) return;
    isLoading.value = true;
    await _fetchLowStockProducts();
    _listenToOrders();
    hasInitialized.value = true;
  }

  /// Real-time listener on Orders collection — keeps _allOrders and stats in sync
  void _listenToOrders() {
    _ordersSubscription?.cancel();
    _ordersSubscription = _firestore
        .collection('Orders')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            final list = snapshot.docs
                .map((doc) => OrderModel.fromSnapshot(doc))
                .toList();
            list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            _allOrders.value = list;
            _recalculateStats();

            // Turn off initial loading spinner on first data
            if (isLoading.value) isLoading.value = false;
          },
          onError: (e) {
            debugPrint('Dashboard orders stream error: $e');
            // Fallback: try without ordering
            _ordersSubscription?.cancel();
            _ordersSubscription = _firestore
                .collection('Orders')
                .snapshots()
                .listen(
                  (snapshot) {
                    final list = snapshot.docs
                        .map((doc) => OrderModel.fromSnapshot(doc))
                        .toList();
                    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
                    _allOrders.value = list;
                    _recalculateStats();
                    if (isLoading.value) isLoading.value = false;
                  },
                  onError: (e2) {
                    debugPrint('Dashboard orders fallback stream error: $e2');
                    if (isLoading.value) isLoading.value = false;
                  },
                );
          },
        );
  }

  /// Force refresh — re-fetches low stock and restarts orders stream
  Future<void> refreshDashboard() async {
    isLoading.value = true;
    try {
      await _fetchLowStockProducts();
      _listenToOrders();
    } finally {
      // isLoading will be turned off by the stream listener
      // but set a safety timeout
      Future.delayed(const Duration(seconds: 3), () {
        if (isLoading.value) isLoading.value = false;
      });
    }
  }

  @override
  void onClose() {
    _ordersSubscription?.cancel();
    super.onClose();
  }

  Future<void> _fetchLowStockProducts() async {
    try {
      final snapshot = await _firestore
          .collection('Products')
          .where('Stock', isLessThanOrEqualTo: 10)
          .get();

      List<LowStockProduct> list = snapshot.docs.map((doc) {
        final data = doc.data();
        return LowStockProduct(
          id: doc.id,
          name: data['Name'] as String? ?? data['name'] as String? ?? 'Unknown',
          stock: (data['Stock'] as num? ?? data['stock'] as num? ?? 0).toInt(),
        );
      }).toList();

      // Fallback: try lowercase stock field
      if (list.isEmpty) {
        final fallback = await _firestore
            .collection('Products')
            .where('stock', isLessThanOrEqualTo: 10)
            .get();
        list = fallback.docs.map((doc) {
          final data = doc.data();
          return LowStockProduct(
            id: doc.id,
            name:
                data['Name'] as String? ?? data['name'] as String? ?? 'Unknown',
            stock: (data['Stock'] as num? ?? data['stock'] as num? ?? 0)
                .toInt(),
          );
        }).toList();
      }

      list.sort((a, b) => a.stock.compareTo(b.stock));
      lowStockProducts.value = list;
    } catch (e) {
      debugPrint('Low stock fetch error: $e');
    }
  }

  Future<void> generateExcelReport() async {
    try {
      isExporting.value = true;
      final excel = Excel.createExcel();
      final sheet = excel['Daily Report'];
      excel.delete('Sheet1');

      final now = DateTime.now();
      final dateStr = DateFormat('dd/MM/yyyy').format(now);

      // Title
      sheet.cell(CellIndex.indexByString('A1')).value = TextCellValue(
        'MediAdmin Daily Report — $dateStr',
      );

      // Summary headers
      sheet.cell(CellIndex.indexByString('A3')).value = TextCellValue('Metric');
      sheet.cell(CellIndex.indexByString('B3')).value = TextCellValue('Value');

      final currencyFormat = NumberFormat.currency(symbol: '\$');
      sheet.cell(CellIndex.indexByString('A4')).value = TextCellValue(
        'Sales Total',
      );
      sheet.cell(CellIndex.indexByString('B4')).value = TextCellValue(
        currencyFormat.format(todaySalesTotal),
      );

      sheet.cell(CellIndex.indexByString('A5')).value = TextCellValue(
        'Average Order Value',
      );
      sheet.cell(CellIndex.indexByString('B5')).value = TextCellValue(
        currencyFormat.format(todayAvgOrderValue),
      );

      sheet.cell(CellIndex.indexByString('A6')).value = TextCellValue(
        'Total Orders',
      );
      sheet.cell(CellIndex.indexByString('B6')).value = IntCellValue(
        todayTotalOrders,
      );

      sheet.cell(CellIndex.indexByString('A7')).value = TextCellValue(
        'Sold Products',
      );
      sheet.cell(CellIndex.indexByString('B7')).value = IntCellValue(
        todaySoldProducts,
      );

      // Orders detail header
      sheet.cell(CellIndex.indexByString('A9')).value = TextCellValue(
        "Today's Orders",
      );

      final orderHeaders = [
        'Order ID',
        'Customer',
        'Email',
        'Items',
        'Status',
        'Payment',
        'Total',
        'Date',
      ];
      for (int i = 0; i < orderHeaders.length; i++) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 9))
            .value = TextCellValue(
          orderHeaders[i],
        );
      }

      int row = 10;
      for (final order in todayOrders) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
            .value = TextCellValue(
          order.id,
        );
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
            .value = TextCellValue(
          order.customerName,
        );
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
            .value = TextCellValue(
          order.customerEmail,
        );
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row))
            .value = IntCellValue(
          order.itemCount,
        );
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
            .value = TextCellValue(
          order.orderStatus,
        );
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row))
            .value = TextCellValue(
          order.paymentStatus,
        );
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row))
            .value = DoubleCellValue(
          order.totalAmount,
        );
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row))
            .value = TextCellValue(
          DateFormat('dd/MM/yyyy').format(order.createdAt),
        );
        row++;
      }

      final bytes = excel.encode();
      if (bytes != null) {
        final blob = html.Blob([Uint8List.fromList(bytes)]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute('download', 'daily_report_$dateStr.xlsx')
          ..click();
        html.Url.revokeObjectUrl(url);
        Get.snackbar(
          'Success',
          'Report downloaded successfully',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to generate report: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isExporting.value = false;
    }
  }
}
