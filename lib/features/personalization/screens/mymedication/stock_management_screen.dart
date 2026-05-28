import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:med/features/shop/controllers/cart_controller.dart';
import 'package:med/features/shop/screens/prescription_request/prescription_request_screen.dart';
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
  final Set<String> _loadingMeds = {};

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

      // Merge medicines with the same name: sum stock, combine disease names
      Map<String, Map<String, dynamic>> merged = {};
      Map<String, List<String>> mergedMedIds = {};
      for (var med in allMedicines) {
        final name = (med['medicine_name'] ?? '')
            .toString()
            .trim()
            .toLowerCase();
        if (merged.containsKey(name)) {
          // Sum stocks
          int existingStock =
              int.tryParse(merged[name]!['available_stock'].toString()) ?? 0;
          int newStock = int.tryParse(med['available_stock'].toString()) ?? 0;
          merged[name]!['available_stock'] = existingStock + newStock;
          // Sum total doses
          int existingDoses =
              int.tryParse(merged[name]!['total_no_of_doses'].toString()) ?? 0;
          int newDoses = int.tryParse(med['total_no_of_doses'].toString()) ?? 0;
          merged[name]!['total_no_of_doses'] = existingDoses + newDoses;
          // Append disease name if different
          final existingDisease = (merged[name]!['disease_name'] ?? '')
              .toString();
          final newDisease = (med['disease_name'] ?? '').toString().trim();
          if (newDisease.isNotEmpty && !existingDisease.contains(newDisease)) {
            merged[name]!['disease_name'] = existingDisease.isEmpty
                ? newDisease
                : '$existingDisease, $newDisease';
          }
          // If any entry is chronic, mark as chronic
          if (med['chronic'] == 1 || med['chronic'] == true) {
            merged[name]!['chronic'] = 1;
          }
          // Keep highest alert_before_days
          int existingAlert =
              int.tryParse(merged[name]!['alert_before_days'].toString()) ?? 0;
          int newAlert = int.tryParse(med['alert_before_days'].toString()) ?? 0;
          if (newAlert > existingAlert)
            merged[name]!['alert_before_days'] = newAlert;
          mergedMedIds[name]!.add(med['medId'].toString());
        } else {
          merged[name] = Map<String, dynamic>.from(med);
          mergedMedIds[name] = [med['medId'].toString()];
        }
      }

      List<Map<String, dynamic>> tempOut = [];
      List<Map<String, dynamic>> tempLow = [];
      List<Map<String, dynamic>> tempNormal = [];

      for (var med in merged.values) {
        // Attach all medIds for this merged entry
        final name = (med['medicine_name'] ?? '')
            .toString()
            .trim()
            .toLowerCase();
        med['_allMedIds'] = mergedMedIds[name] ?? [med['medId'].toString()];
        int currentStock = int.tryParse(med['available_stock'].toString()) ?? 0;
        int alertDays = int.tryParse(med['alert_before_days'].toString()) ?? 0;
        bool isChronic = med['chronic'] == 1 || med['chronic'] == true;

        if (currentStock == 0) {
          tempOut.add(med);
          continue;
        }

        // alert_before_days == 0 means alerts disabled → always normal
        if (alertDays <= 0) {
          tempNormal.add(med);
          continue;
        }

        int freq = _parseFrequency((med['frequency'] ?? '').toString());
        int warningThreshold = freq * alertDays;

        if (!isChronic) {
          int totalDoses =
              int.tryParse(med['total_no_of_doses'].toString()) ?? 0;
          // Non-chronic: if stock covers full course, always normal
          if (currentStock >= totalDoses) {
            tempNormal.add(med);
            continue;
          }
        }

        if (currentStock <= warningThreshold) {
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

  Future<void> _updateStockInDB(Map<String, dynamic> med, int newStock) async {
    setState(() => isLoading = true);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        final allMedIds = List<String>.from(
          med['_allMedIds'] ?? [med['medId'].toString()],
        );
        // Distribute stock evenly across underlying entries
        int stockPerEntry = newStock ~/ allMedIds.length;
        int remainder = newStock % allMedIds.length;
        for (int i = 0; i < allMedIds.length; i++) {
          int entryStock = stockPerEntry + (i < remainder ? 1 : 0);
          await LocalDB.updateMedicineStats(
            allMedIds[i],
            med['total_no_of_doses'] ?? 0,
            entryStock,
          );
          await OfflineQueueService.queueOperation(
            type: 'UPDATE',
            entity: 'MEDICINE',
            entityId: allMedIds[i],
            data: {'available_stock': entryStock},
          );
        }
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

  Future<void> _addToCartFromStock(Map<String, dynamic> med) async {
    final medName = (med['medicine_name'] ?? '').toString().trim();
    if (medName.isEmpty) return;
    setState(() => _loadingMeds.add(medName));

    try {
      // 1. Calculate required tablets
      final bool isChronic = med['chronic'] == 1 || med['chronic'] == true;
      final int freq = _parseFrequency((med['frequency'] ?? '').toString());
      final int alertDays =
          int.tryParse(med['alert_before_days']?.toString() ?? '7') ?? 7;
      final int currentStock =
          int.tryParse(med['available_stock']?.toString() ?? '0') ?? 0;
      final int totalDoses =
          int.tryParse(med['total_no_of_doses']?.toString() ?? '0') ?? 0;

      final int requiredTablets = isChronic
          ? (freq * alertDays).clamp(1, 99999)
          : (totalDoses - currentStock).clamp(1, 99999);

      if (requiredTablets <= 0) {
        _showSnackbar(
          'No additional tablets required for $medName.',
          Colors.orange,
        );
        return;
      }

      // 2. Search products by name (client-side contains match)
      final snapshot =
          await FirebaseFirestore.instance.collection('Products').get();
      final query = medName.toLowerCase();

      // Split into individual words so "ors" doesn't match "Monitors"
      final queryWords = query
          .split(RegExp(r'[\s\-_/]+'))
          .map((w) => w.trim())
          .where((w) => w.length > 1)
          .toSet();

      final matches = snapshot.docs.where((doc) {
        final docData = doc.data() as Map<String, dynamic>;
        // Firestore stores product names as 'Name' (PascalCase)
        final productName =
            (docData['Name'] ?? docData['name'] ?? '').toString().toLowerCase();
        final productWords = productName
            .split(RegExp(r'[\s\-_/]+'))
            .map((w) => w.trim())
            .where((w) => w.isNotEmpty)
            .toSet();
        // A match requires at least one query word to equal a product word exactly
        return queryWords.any((qw) => productWords.contains(qw));
      }).toList();

      if (matches.isEmpty) {
        // Medicine not found — ask user if they want to send prescription to store
        if (!mounted) return;
        final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
        // Try to pre-load the prescription image from LocalDB
        List<String> prescriptionImages = [];
        try {
          prescriptionImages =
              await LocalDB.getPrescriptionImagesForNames(uid, [medName]);
        } catch (_) {}
        final prescriptionBase64 =
            prescriptionImages.isNotEmpty ? prescriptionImages.first : null;

        if (!mounted) return;
        final shouldSend = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: const Text('Medicine Not Found'),
            content: Text(
              '"$medName" is not available in our store right now.\n\n'
              'Would you like to send your prescription to our team? '
              'We will check and get back to you.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('No, Cancel'),
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(ctx, true),
                icon: const Icon(Icons.send, size: 16),
                label: const Text('Yes, Send'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        );

        if (shouldSend == true && mounted) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PrescriptionRequestScreen(
                medicineName: medName,
                prescriptionBase64: prescriptionBase64,
              ),
            ),
          );
        }
        return;
      }

      // 3. Build candidate list with tabletsInPack (Firestore: 'TabletsInPack')
      final candidates = matches.map((doc) {
        final raw = Map<String, dynamic>.from(
          doc.data() as Map<String, dynamic>,
        );
        // Normalize PascalCase Firestore fields → camelCase for CartController
        // Compute pack size first so it can be included in data map
        final rawPack = (raw['TabletsInPack'] ?? raw['tabletsInPack'] ?? 0);
        final pack = ((rawPack as num?)?.toInt() ?? 0).clamp(1, 99999);
        final data = <String, dynamic>{
          'id': doc.id,
          'name': raw['Name'] ?? raw['name'] ?? '',
          'brandName': raw['BrandName'] ?? raw['brandName'] ?? '',
          'images': raw['Images'] ?? raw['images'] ?? [],
          'price': raw['Price'] ?? raw['price'] ?? 0,
          'salePrice': raw['SalePrice'] ?? raw['salePrice'] ?? 0,
          'stock': raw['Stock'] ?? raw['stock'] ?? 0,
          'isPrescribed': raw['IsPrescribed'] ?? raw['isPrescribed'] ?? false,
          'tabletsInPack': pack, // needed for stock refill on delivery
        };
        return _ProductCandidate(data: data, tabletsInPack: pack);
      }).toList();

      // 4. Pick best candidate and quantity using case logic
      _ProductCandidate selected;
      int selectedQty;

      if (candidates.length == 1) {
        // Case 1: Single match
        selected = candidates.first;
        selectedQty =
            (requiredTablets / selected.tabletsInPack).ceil().clamp(1, 99999);
      } else {
        // Case 2: Multiple matches
        // Find candidates whose single pack already covers the requirement
        final sufficient =
            candidates
                .where((c) => c.tabletsInPack >= requiredTablets)
                .toList();

        if (sufficient.isNotEmpty) {
          // Subcase 1: pick the one with LEAST tablets (minimum wastage), qty=1
          sufficient.sort((a, b) => a.tabletsInPack.compareTo(b.tabletsInPack));
          selected = sufficient.first;
          selectedQty = 1;
        } else {
          // Subcase 2: none covers alone → pick GREATEST pack, increase qty
          candidates.sort(
            (a, b) => b.tabletsInPack.compareTo(a.tabletsInPack),
          );
          selected = candidates.first;
          selectedQty =
              (requiredTablets / selected.tabletsInPack)
                  .ceil()
                  .clamp(1, 99999);
        }
      }

      // 5. Add to cart (suppress default snackbar)
      final cartCtrl = Get.find<CartController>();
      await cartCtrl.addToCart(
        selected.data,
        quantity: selectedQty,
        showSnackbar: false,
      );

      // 6. Show informative snackbar
      final productName = selected.data['name'].toString();
      final totalTablets = selectedQty * selected.tabletsInPack;
      _showSnackbar(
        'Added $productName × $selectedQty pack${selectedQty > 1 ? 's' : ''} '
        'to cart ($totalTablets tablets)',
        MColors.primary,
      );
    } catch (e) {
      _showSnackbar('Error: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _loadingMeds.remove(medName));
    }
  }

  void _showSnackbar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
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
              _updateStockInDB(med, val);
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
            icon: _loadingMeds.contains(name)
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.grey,
                    ),
                  )
                : Icon(
                    Icons.add_shopping_cart,
                    color: isLowOrOut ? Colors.red : MColors.primary,
                    size: 20,
                  ),
            onPressed: _loadingMeds.contains(name)
                ? null
                : () => _addToCartFromStock(med),
            tooltip: 'Add to Cart',
          ),
        ],
      ),
    );
  }
}

enum StockLevel { out, low, normal }

/// Lightweight holder for a Firestore product candidate during cart matching.
class _ProductCandidate {
  final Map<String, dynamic> data;
  final int tabletsInPack;
  const _ProductCandidate({required this.data, required this.tabletsInPack});
}
