import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:med/utils/constants/colors.dart';
import 'package:med/utils/constants/sizes.dart';
import 'package:med/utils/helpers/helper_functions.dart';
import 'package:med/features/personalization/screens/mymedicalhistory/ocr_scan/local_db.dart';
import 'services/offline_queue_service.dart';
import 'services/sync_service.dart';

class StockManagementScreen extends StatefulWidget {
  final bool showAppBar;
  const StockManagementScreen({super.key, this.showAppBar = true});

  @override
  State<StockManagementScreen> createState() => _StockManagementScreenState();
}

class _StockManagementScreenState extends State<StockManagementScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> outOfStockList = [];
  List<Map<String, dynamic>> lowStockList = [];
  List<Map<String, dynamic>> normalStockList = [];

  @override
  void initState() {
    super.initState();
    _loadStocks();
  }

  int _parseFrequency(String freqStr) {
    freqStr = freqStr.toLowerCase().trim();
    // Handle "X/day"
    if (freqStr.contains('/')) {
      final parts = freqStr.split('/');
      final val = int.tryParse(parts[0].trim());
      if (val != null) return val;
    }
    if (freqStr.contains('+')) {
      int total = 0;
      for (var p in freqStr.split('+')) {
        total += int.tryParse(p.trim()) ?? 0;
      }
      if (total > 0) return total;
    }
    if (freqStr.contains('twice') ||
        freqStr.contains('bd') ||
        freqStr.contains('2'))
      return 2;
    if (freqStr.contains('thrice') ||
        freqStr.contains('tds') ||
        freqStr.contains('3'))
      return 3;
    return 1;
  }

  Future<void> _loadStocks() async {
    setState(() => isLoading = true);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final allMedicines = await LocalDB.getUserMedicines(uid);
      List<Map<String, dynamic>> tempOut = [];
      List<Map<String, dynamic>> tempLow = [];
      List<Map<String, dynamic>> tempNormal = [];

      for (var med in allMedicines) {
        int currentStock = int.tryParse(med['available_stock'].toString()) ?? 0;
        int freq = _parseFrequency((med['frequency'] ?? '').toString());
        int alertDays = int.tryParse(med['alert_before_days'].toString()) ?? 3;
        int warningThreshold = (freq * alertDays).clamp(5, 9999);

        if (currentStock == 0) {
          tempOut.add(med);
        } else if (currentStock <= warningThreshold) {
          tempLow.add(med);
        } else {
          tempNormal.add(med);
        }
      }

      setState(() {
        outOfStockList = tempOut;
        lowStockList = tempLow;
        normalStockList = tempNormal;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading stocks: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> _updateStockInDB(
    String medId,
    int newStock,
    int totalDoses,
  ) async {
    setState(() => isLoading = true);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        await LocalDB.updateMedicineStats(medId, totalDoses, newStock);
        await OfflineQueueService.queueOperation(
          type: 'UPDATE',
          entity: 'MEDICINE',
          entityId: medId,
          data: {'available_stock': newStock, 'total_no_of_doses': totalDoses},
        );
        SyncService.trySyncNow();
        await _loadStocks();
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Stock Updated! ')));
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _addToCart(String medName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(" '$medName' added to cart!"),
        backgroundColor: MColors.primary,
      ),
    );
  }

  Future<void> _editStockDialog(Map<String, dynamic> med) async {
    final dark = MHelperFunctions.isDarkMode(context);
    TextEditingController stockController = TextEditingController(
      text: med['available_stock'].toString(),
    );
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: dark ? MColors.darkerGrey : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Update Stock",
          style: TextStyle(color: dark ? Colors.white : Colors.black87),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              med['medicine_name'] ?? '',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: MColors.primary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: stockController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'New Stock Quantity',
                prefixIcon: Icon(Icons.inventory, color: MColors.primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: MColors.primary),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: dark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              int val = int.tryParse(stockController.text) ?? 0;
              Navigator.pop(ctx);
              _updateStockInDB(
                med['medId'],
                val,
                med['total_no_of_doses'] ?? 0,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: MColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = MHelperFunctions.isDarkMode(context);
    final isEmpty =
        outOfStockList.isEmpty &&
        lowStockList.isEmpty &&
        normalStockList.isEmpty;

    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(title: const Text('Stock Management'), centerTitle: true)
          : null,
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: MColors.primary))
          : isEmpty
          ? Center(
              child: Text(
                'No medicines added yet.',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadStocks,
              color: MColors.primary,
              child: ListView(
                padding: const EdgeInsets.all(MSizes.defaultSpace),
                children: [
                  if (outOfStockList.isNotEmpty) ...[
                    _sectionHeader(
                      'Out of Stock',
                      Icons.error_outline,
                      Colors.red,
                      dark,
                    ),
                    const SizedBox(height: 8),
                    ...outOfStockList.map(
                      (m) => _buildStockCard(m, StockLevel.out, dark),
                    ),
                    const SizedBox(height: MSizes.spaceBtwSections),
                  ],
                  if (lowStockList.isNotEmpty) ...[
                    _sectionHeader(
                      'Low Stock',
                      Icons.warning_amber_rounded,
                      Colors.orange,
                      dark,
                    ),
                    const SizedBox(height: 8),
                    ...lowStockList.map(
                      (m) => _buildStockCard(m, StockLevel.low, dark),
                    ),
                    const SizedBox(height: MSizes.spaceBtwSections),
                  ],
                  if (normalStockList.isNotEmpty) ...[
                    _sectionHeader(
                      'In Stock',
                      Icons.check_circle_outline,
                      MColors.primary,
                      dark,
                    ),
                    const SizedBox(height: 8),
                    ...normalStockList.map(
                      (m) => _buildStockCard(m, StockLevel.normal, dark),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _sectionHeader(String title, IconData icon, Color color, bool dark) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: dark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildStockCard(
    Map<String, dynamic> med,
    StockLevel level,
    bool dark,
  ) {
    final isLowOrOut = level != StockLevel.normal;
    final stockColor = level == StockLevel.out
        ? Colors.red
        : (level == StockLevel.low ? Colors.orange : MColors.primary);
    final bgColor = level == StockLevel.out
        ? (dark ? Colors.red.withOpacity(0.1) : Colors.red.shade50)
        : level == StockLevel.low
        ? (dark ? Colors.orange.withOpacity(0.1) : Colors.orange.shade50)
        : (dark ? MColors.darkerGrey : Colors.grey.shade50);
    final borderColor = level == StockLevel.out
        ? (dark ? Colors.red.shade800 : Colors.red.shade200)
        : level == StockLevel.low
        ? (dark ? Colors.orange.shade800 : Colors.orange.shade200)
        : (dark ? Colors.grey.shade700 : Colors.grey.shade300);

    final stock = int.tryParse(med['available_stock'].toString()) ?? 0;
    final name = med['medicine_name'] ?? '';
    final disease = (med['disease_name'] ?? '').toString();
    final freq = med['frequency'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          // Stock indicator
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: stockColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '$stock',
                style: TextStyle(
                  color: stockColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: dark ? Colors.white : Colors.black87,
                  ),
                ),
                if (disease.isNotEmpty)
                  Text(
                    disease,
                    style: TextStyle(
                      fontSize: 12,
                      color: dark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 13, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      freq,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: stockColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        level == StockLevel.out
                            ? 'OUT'
                            : level == StockLevel.low
                            ? 'LOW'
                            : 'OK',
                        style: TextStyle(
                          color: stockColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Actions
          IconButton(
            icon: Icon(
              Icons.edit_outlined,
              color: dark ? Colors.grey.shade300 : Colors.grey.shade700,
              size: 20,
            ),
            onPressed: () => _editStockDialog(med),
            tooltip: 'Edit Stock',
          ),
          IconButton(
            icon: Icon(
              Icons.add_shopping_cart,
              color: isLowOrOut ? Colors.red : MColors.primary,
              size: 20,
            ),
            onPressed: () => _addToCart(name),
            tooltip: 'Add to Cart',
          ),
        ],
      ),
    );
  }
}

enum StockLevel { out, low, normal }
